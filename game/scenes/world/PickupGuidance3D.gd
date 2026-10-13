extends Node3D

@export var navigation_mesh: NavigationMesh
@export var item_paths: Array[NodePath] = []

const FIRST_PULSE_DELAY := 3.0
const REPEAT_PULSE_DELAY := 8.0
const PULSE_DURATION := 2.5
const REPATH_INTERVAL := 0.5
const REPATH_DISTANCE := 0.4
const PICKUP_PROXIMITY := 1.6
const WIND_HEIGHT := 0.25
const WIND_SWAY := 0.09

var _map: RID
var _region: NavigationRegion3D
var _player: PlayerV2
var _items: Array[WorldItem] = []
var _target: WorldItem
var _route := PackedVector3Array()
var _route_length := 0.0
var _pulse_duration := PULSE_DURATION
var _last_route_position := Vector3.ZERO
var _until_pulse := FIRST_PULSE_DELAY
var _pulse_elapsed := -1.0
var _repath_wait := 0.0
var _wind: GPUParticles3D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if navigation_mesh == null or navigation_mesh.get_polygon_count() == 0:
		push_warning("PickupGuidance3D requires a baked navigation mesh.")
		set_process(false)
		return
	_player = get_tree().get_first_node_in_group("player") as PlayerV2
	if _player == null:
		push_warning("PickupGuidance3D could not find the scene player.")
		set_process(false)
		return
	for path in item_paths:
		var item := get_node_or_null(path) as WorldItem
		if item != null:
			_items.append(item)

	# This map belongs only to the hint. Gameplay navigation settings stay unchanged.
	_map = NavigationServer3D.map_create()
	NavigationServer3D.map_set_cell_size(_map, navigation_mesh.cell_size)
	NavigationServer3D.map_set_cell_height(_map, navigation_mesh.cell_height)
	NavigationServer3D.map_set_active(_map, true)
	_region = NavigationRegion3D.new()
	_region.navigation_mesh = navigation_mesh
	_region.set_navigation_map(_map)
	add_child(_region)
	_build_visuals()


func _exit_tree() -> void:
	if _map.is_valid():
		if is_instance_valid(_region):
			_region.set_navigation_map(RID())
		NavigationServer3D.free_rid(_map)


func _process(delta: float) -> void:
	if not _can_show():
		_hide_wind()
		_until_pulse = FIRST_PULSE_DELAY
		return
	if _pulse_elapsed >= 0.0:
		if not _is_eligible(_target):
			_target = null
			_hide_wind()
			_until_pulse = FIRST_PULSE_DELAY
			return
		_pulse_elapsed += delta
		if _pulse_elapsed >= _pulse_duration:
			_hide_wind()
			_until_pulse = REPEAT_PULSE_DELAY
			return
		_repath_wait -= delta
		if _repath_wait <= 0.0 and _player.global_position.distance_to(_last_route_position) >= REPATH_DISTANCE:
			_repath_wait = REPATH_INTERVAL
			var updated := _calculate_route(_target)
			if updated.is_empty():
				_target = null
				_hide_wind()
				_until_pulse = FIRST_PULSE_DELAY
				return
			_set_route(updated)
		_wind.global_position = _wind_position(_pulse_elapsed / _pulse_duration)
		return

	_until_pulse -= delta
	if _until_pulse > 0.0:
		return
	_until_pulse = REPEAT_PULSE_DELAY
	var route := _choose_route()
	if route.is_empty():
		return
	_set_route(route)
	_pulse_elapsed = 0.0
	_wind.show()
	_wind.restart()
	_wind.emitting = true


func _can_show() -> bool:
	return is_instance_valid(_player) and not get_tree().paused \
		and not _player._is_input_locked and not _player._is_movement_locked \
		and not SceneManager.is_travelling and not SceneManager.storm_transition_pending \
		and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED \
		and (TransitionOverlay.overlay == null or TransitionOverlay.overlay.color.a < 0.05)


func _is_eligible(item: WorldItem) -> bool:
	if not is_instance_valid(item) or item.is_queued_for_deletion() or item.item_data == null:
		return false
	if InventoryManager.inventory.size() >= InventoryManager.MAX_INVENTORY_SIZE:
		return false
	if item.world_item_id != "" and GameState.is_item_collected(item.world_item_id):
		return false
	match item.item_data.item_id:
		"hammer":
			return not InventoryManager.has_item_with_id("hammer") \
				and (not NeedsLog.is_resolved(NeedsLog.Need.ROOF) or not NeedsLog.is_resolved(NeedsLog.Need.WINDOWS))
		"broken_radio":
			return not NeedsLog.is_resolved(NeedsLog.Need.FLASHLIGHT) \
				and not InventoryManager.has_item_with_id("broken_radio") \
				and not InventoryManager.has_item_with_id("working_radio")
		"dead_flashlight":
			return not NeedsLog.is_resolved(NeedsLog.Need.FLASHLIGHT) \
				and not InventoryManager.has_item_with_id("dead_flashlight") \
				and not InventoryManager.has_item_with_id("working_flashlight")
		"plywood":
			return not NeedsLog.is_resolved(NeedsLog.Need.WINDOWS) \
				and InventoryManager.get_total_quantity("plywood") + NeedsLog.boarded_window_count() < 2
	return false


func _choose_route() -> PackedVector3Array:
	if _is_eligible(_target):
		var previous := _calculate_route(_target)
		if not previous.is_empty():
			return previous
	_target = null
	var best := PackedVector3Array()
	var best_length := INF
	for item in _items:
		if not _is_eligible(item):
			continue
		var route := _calculate_route(item)
		if route.is_empty():
			continue
		var length := _measure_route(route)
		if length < best_length:
			best_length = length
			best = route
			_target = item
	return best


func _calculate_route(item: WorldItem) -> PackedVector3Array:
	var empty := PackedVector3Array()
	if NavigationServer3D.map_get_iteration_id(_map) == 0:
		return empty
	var player_position := _player.global_position
	if Vector2(player_position.x, player_position.z).distance_to(Vector2(item.global_position.x, item.global_position.z)) <= PICKUP_PROXIMITY:
		return empty
	var start := NavigationServer3D.map_get_closest_point(_map, player_position)
	if _horizontal_distance(start, player_position) > 0.75 or absf(start.y - player_position.y) > 0.7:
		return empty
	var item_ground := Vector3(item.global_position.x, player_position.y, item.global_position.z)
	var finish := NavigationServer3D.map_get_closest_point(_map, item_ground)
	if _horizontal_distance(finish, item_ground) > 1.5 or absf(finish.y - player_position.y) > 0.7:
		return empty
	var nav_path := NavigationServer3D.map_get_path(_map, start, finish, true)
	if nav_path.size() < 2:
		return empty
	var route := PackedVector3Array([Vector3(player_position.x, start.y, player_position.z)])
	for point in nav_path:
		if route[route.size() - 1].distance_to(point) > 0.02:
			route.append(point)
	if route.size() < 2 or not _route_is_clear(route):
		return empty
	return route


func _route_is_clear(route: PackedVector3Array) -> bool:
	var space := get_world_3d().direct_space_state
	for i in range(route.size() - 1):
		for height in [0.3, 0.8]:
			var from: Vector3 = route[i] + Vector3.UP * float(height)
			var to: Vector3 = route[i + 1] + Vector3.UP * float(height)
			if from.distance_to(to) < 0.02:
				continue
			var query := PhysicsRayQueryParameters3D.create(from, to)
			query.exclude = [_player.get_rid()]
			if not space.intersect_ray(query).is_empty():
				return false
	return true


func _horizontal_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))


func _measure_route(route: PackedVector3Array) -> float:
	var length := 0.0
	for i in range(route.size() - 1):
		length += route[i].distance_to(route[i + 1])
	return length


func _set_route(route: PackedVector3Array) -> void:
	_route = route
	_route_length = _measure_route(route)
	_pulse_duration = maxf(PULSE_DURATION, _route_length / 4.0)
	_last_route_position = _player.global_position
	_wind.global_position = _wind_position(_pulse_elapsed / _pulse_duration if _pulse_elapsed >= 0.0 else 0.0)
	if _wind.emitting:
		_wind.restart()


func _wind_position(progress: float) -> Vector3:
	var t := clampf(progress, 0.0, 1.0)
	var distance := _route_length * t
	var center := _point_on_route(distance)
	var before := _point_on_route(maxf(distance - 0.1, 0.0))
	var after := _point_on_route(minf(distance + 0.1, _route_length))
	var tangent := (after - before).normalized()
	var side := Vector3(-tangent.z, 0.0, tangent.x).normalized()
	var phase := t * TAU * 2.0
	var height := WIND_HEIGHT + 0.56 * t * (1.0 - t) + WIND_SWAY * cos(phase)
	return center + side * (WIND_SWAY * sin(phase)) + Vector3.UP * height


func _point_on_route(distance: float) -> Vector3:
	for i in range(_route.size() - 1):
		var segment := _route[i].distance_to(_route[i + 1])
		if distance <= segment:
			return _route[i].lerp(_route[i + 1], distance / maxf(segment, 0.001))
		distance -= segment
	return _route[_route.size() - 1]


func _hide_wind() -> void:
	_pulse_elapsed = -1.0
	if is_instance_valid(_wind):
		_wind.emitting = false
		_wind.hide()


func _build_visuals() -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.vertex_color_use_as_albedo = true
	material.use_particle_trails = true
	material.albedo_color = Color(0.9, 0.94, 0.85, 0.8)
	material.emission_enabled = true
	material.emission = Color(0.9, 0.94, 0.85)
	material.emission_energy_multiplier = 1.3
	var width := Curve.new()
	width.add_point(Vector2(0.0, 0.0))
	width.add_point(Vector2(0.25, 0.8))
	width.add_point(Vector2(1.0, 0.0))
	var streak := RibbonTrailMesh.new()
	streak.material = material
	streak.size = 0.045
	streak.curve = width
	var mote := QuadMesh.new()
	mote.material = material
	mote.size = Vector2(0.055, 0.055)
	var motion := ParticleProcessMaterial.new()
	motion.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	motion.emission_sphere_radius = 0.04
	motion.direction = Vector3.UP
	motion.spread = 65.0
	motion.gravity = Vector3.ZERO
	motion.initial_velocity_min = 0.15
	motion.initial_velocity_max = 0.35
	motion.color = Color(1.0, 0.96, 0.83, 0.9)
	_wind = GPUParticles3D.new()
	_wind.amount = 30
	_wind.lifetime = 1.25
	_wind.randomness = 0.35
	_wind.local_coords = false
	_wind.trail_enabled = true
	_wind.trail_lifetime = 0.26
	_wind.visibility_aabb = AABB(Vector3(-4.0, -2.0, -4.0), Vector3(8.0, 4.0, 8.0))
	_wind.process_material = motion
	_wind.draw_passes = 2
	_wind.draw_pass_1 = streak
	_wind.draw_pass_2 = mote
	_wind.emitting = false
	_wind.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_wind)
	_wind.hide()
