class_name DevCameraController
extends Node3D

const GUIDANCE_SCRIPT: Script = preload("res://game/objects/world_items/PickupGuidance3D.gd")
const MIN_FOV := 20.0
const MAX_FOV := 100.0
const SMOOTHING_RATE := 8.0
const HOUSE_SCENE := "res://game/scenes/recording/house_teaser.tscn"

var camera: Camera3D
var active := false
var _player: PlayerV2
var _pause_menu: CanvasLayer
var _gameplay_camera: Camera3D
var _environment := DevCameraEnvironment.new()
var _settings: Dictionary = {}
var _visibility: Dictionary = {}
var _process_modes: Dictionary = {}
var _groups: Dictionary = {}
var _generation := 0
var _capture_time := 0.0
var _velocity := Vector3.ZERO
var _pitch := 0.0
var _yaw := 0.0
var _target_fov := 60.0
var _has_pose := false
var _has_focus := true
var _owns_world_pause := false
var _recording_house: Node3D
var _recording_location: StringName = &"current"
var _location_poses: Dictionary = {}
var _world_visibility: Dictionary = {}
var _world_process_modes: Dictionary = {}


func _ready() -> void:
	name = "DevRecordingCamera"
	process_mode = Node.PROCESS_MODE_ALWAYS
	camera = Camera3D.new()
	camera.name = "Camera3D"
	add_child(camera)
	set_process(false)
	set_process_input(false)
	get_parent().tree_exiting.connect(_on_location_exiting)
	GlobalTimer.storm_arrived.connect(_on_storm_arrived)
	VisualSettings.quality_preset_changed.connect(_on_quality_changed.unbind(1))


func begin(player: PlayerV2, pause_menu: CanvasLayer, settings: Dictionary) -> bool:
	if not DevMode.can_use() or DevMode._camera_controller != self or active:
		return false
	_player = player
	_pause_menu = pause_menu
	_gameplay_camera = get_viewport().get_camera_3d()
	if _gameplay_camera == null or _gameplay_camera == camera:
		return false
	_generation = SceneManager.transition_generation
	_settings = settings.duplicate()
	camera.near = _gameplay_camera.near
	camera.far = _gameplay_camera.far
	camera.cull_mask = _gameplay_camera.cull_mask
	camera.attributes = _gameplay_camera.attributes.duplicate(true) if _gameplay_camera.attributes != null else CameraAttributesPractical.new()
	if not _has_pose:
		reset_pose()
	_pitch = camera.global_rotation.x
	_yaw = camera.global_rotation.y
	_target_fov = camera.fov
	_velocity = Vector3.ZERO
	_has_focus = true
	_capture_time = fmod(float(Time.get_ticks_msec()) / 1000.0, 3600.0)
	_visibility.clear()
	_process_modes.clear()
	_groups = {&"hide_player": [], &"hide_npcs": [], &"hide_animals": [], &"hide_items": [], &"hide_indicators": []}
	_cache_targets(get_parent())
	_add_target(&"hide_player", _player.get_node_or_null("visuals") as Node3D)
	active = true
	if not _apply_recording_location(settings):
		active = false
		_environment.restore()
		_restore_recording_world()
		for node in _process_modes:
			if is_instance_valid(node):
				node.process_mode = _process_modes[node]
		return false
	_cache_player_layers(_player)
	_process_modes[_player] = _world_process_modes.get(_player, _player.process_mode)
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	GlobalTimer.pause_timer(self)
	_pause_menu.call("begin_camera_capture")
	camera.make_current()
	apply_settings(settings)
	set_process(true)
	set_process_input(true)
	DevMode.camera_mode_changed.emit(true)
	return true


func apply_settings(settings: Dictionary) -> void:
	if not active or not DevMode.can_use():
		return
	_settings = settings.duplicate()
	get_tree().paused = bool(_settings[&"world_paused"])
	_owns_world_pause = bool(_settings[&"world_paused"])
	if not _apply_recording_location(settings):
		stop()
		return
	for key in _groups:
		for target: Node3D in _groups[key]:
			if is_instance_valid(target):
				target.visible = bool(_visibility[target]) and not bool(_settings[key])
	for node: Node3D in _world_visibility:
		if is_instance_valid(node):
			node.hide()
	_environment.apply(settings)
	_apply_effects()
	if not bool(_settings[&"cinematic"]):
		_velocity = Vector3.ZERO


func stop(return_to_pause: bool = true) -> void:
	if not active:
		return
	active = false
	set_process(false)
	set_process_input(false)
	_velocity = Vector3.ZERO
	_environment.restore()
	_store_location_pose()
	_restore_recording_world()
	VhsCrtOverlay.set_recording_override(false, false, 0.0)
	for node in _visibility:
		if is_instance_valid(node):
			node.visible = _visibility[node]
	for node in _process_modes:
		if is_instance_valid(node):
			node.process_mode = _process_modes[node]
	_visibility.clear()
	_process_modes.clear()
	_groups.clear()
	GlobalTimer.resume_timer(self)
	if is_instance_valid(_gameplay_camera) and _gameplay_camera.is_inside_tree():
		_gameplay_camera.make_current()
	var same_scene := is_inside_tree() and get_tree().current_scene == get_parent()
	var same_generation := _generation == SceneManager.transition_generation
	var transition_pending := SceneManager.is_travelling or SceneManager.storm_transition_pending
	if return_to_pause and same_scene and same_generation and not transition_pending and is_instance_valid(_pause_menu):
		_pause_menu.call("return_from_camera_capture")
	elif _owns_world_pause and same_generation and not transition_pending and is_inside_tree():
		# A storm/travel owns its pause state; only release our uncontested freeze.
		if not is_instance_valid(_pause_menu) or not _pause_menu.visible:
			get_tree().paused = false
	_owns_world_pause = false
	DevMode.camera_mode_changed.emit(false)


func reset_pose() -> void:
	if not is_instance_valid(_gameplay_camera):
		_has_pose = false
		return
	var reference := _recording_house.call("reference_camera") as Camera3D if is_instance_valid(_recording_house) else _gameplay_camera
	if reference == null:
		return
	camera.global_transform = reference.global_transform
	camera.fov = clampf(reference.fov, MIN_FOV, MAX_FOV)
	camera.keep_aspect = reference.keep_aspect
	_pitch = camera.global_rotation.x
	_yaw = camera.global_rotation.y
	_target_fov = camera.fov
	_velocity = Vector3.ZERO
	_has_pose = true


func _process(delta: float) -> void:
	if not active:
		return
	if not DevMode.can_use() or _generation != SceneManager.transition_generation or get_tree().current_scene != get_parent():
		stop(false)
		return
	if not bool(_settings[&"world_paused"]):
		_capture_time = fmod(_capture_time + delta, 3600.0)
	VhsCrtOverlay.set_recording_override(true, bool(_settings[&"vhs_enabled"]), _capture_time)
	if not _has_focus:
		return
	_step_camera(minf(delta, 0.1))


func _step_camera(delta: float) -> void:
	var direction := Vector3.ZERO
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	direction += camera.global_basis * Vector3(input_dir.x, 0.0, input_dir.y)
	direction.y += float(Input.is_physical_key_pressed(KEY_E)) - float(Input.is_physical_key_pressed(KEY_Q))
	var speed := float(_settings[&"speed"])
	var cinematic := bool(_settings[&"cinematic"])
	if cinematic:
		speed *= 0.25
	if Input.is_action_pressed("sprint"):
		speed *= 3.0
	var desired_velocity := direction.limit_length() * speed
	var weight := 1.0 - exp(-SMOOTHING_RATE * delta) if cinematic else 1.0
	# Integrate the smoothed velocity exactly so a take travels equally at different frame rates.
	if cinematic:
		camera.global_position += desired_velocity * delta + (_velocity - desired_velocity) * weight / SMOOTHING_RATE
	else:
		camera.global_position += desired_velocity * delta
	_velocity = _velocity.lerp(desired_velocity, weight)
	var rotation := camera.global_rotation
	rotation.x = lerp_angle(rotation.x, _pitch, weight)
	rotation.y = lerp_angle(rotation.y, _yaw, weight)
	rotation.z = 0.0
	camera.global_rotation = rotation
	camera.fov = lerpf(camera.fov, _target_fov, weight)


func _input(event: InputEvent) -> void:
	if not active or event.is_action_pressed("ui_cancel"):
		return
	if event is InputEventMouseMotion:
		var sensitivity := deg_to_rad(float(_settings[&"sensitivity"]))
		if bool(_settings[&"cinematic"]):
			sensitivity *= 0.5
		_yaw -= event.screen_relative.x * sensitivity
		_pitch = clampf(_pitch - event.screen_relative.y * sensitivity, deg_to_rad(-89.0), deg_to_rad(89.0))
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_target_fov = maxf(MIN_FOV, _target_fov - 2.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_target_fov = minf(MAX_FOV, _target_fov + 2.0)
	elif event is InputEventKey and event.pressed and not event.echo:
		var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if key == KEY_C and event.alt_pressed:
			DevMode.set_camera_setting(&"cinematic", not bool(_settings[&"cinematic"]))
		elif key == KEY_P and not event.alt_pressed and not event.ctrl_pressed:
			DevMode.set_camera_setting(&"world_paused", not bool(_settings[&"world_paused"]))
		elif key == KEY_G and not event.alt_pressed and not event.ctrl_pressed and _recording_location == &"house_teaser":
			DevMode.set_camera_setting(&"house_state", &"normal" if _settings[&"house_state"] == &"wrecked" else &"wrecked")
	if event is InputEventKey or event is InputEventMouse or event is InputEventAction:
		get_viewport().set_input_as_handled()


func _cache_targets(node: Node) -> void:
	if node == _recording_house:
		return
	if node is NPC:
		var actor := node.get_parent() as Node3D
		_add_target(&"hide_npcs", node as Node3D if actor == get_parent() else actor)
	elif node is AmbientAnimal:
		_add_target(&"hide_animals", node)
	elif node is WorldItem:
		_add_target(&"hide_items", node)
	elif node is TaskCue3D:
		_add_target(&"hide_indicators", node)
	elif node.get_script() == GUIDANCE_SCRIPT:
		_add_target(&"hide_indicators", node as Node3D)
		_process_modes[node] = node.process_mode
		node.process_mode = Node.PROCESS_MODE_PAUSABLE
	for child in node.get_children():
		_cache_targets(child)


func _apply_recording_location(settings: Dictionary) -> bool:
	var requested: StringName = settings[&"recording_location"]
	if requested != _recording_location or (requested == &"house_teaser" and not is_instance_valid(_recording_house)):
		var house: Node3D
		if requested == &"house_teaser":
			var packed := load(HOUSE_SCENE) as PackedScene
			if packed == null:
				push_warning("Recording house could not load.")
				return false
			house = packed.instantiate() as Node3D
			if house == null:
				return false
		_store_location_pose()
		_environment.restore()
		_restore_recording_world()
		_recording_location = requested
		if house != null:
			_recording_house = house
			add_child(house)
			# The set shares the viewport, so suppress every original light/GI/mesh branch.
			_hide_recording_world(get_parent())
		if _location_poses.has(requested):
			var pose: Dictionary = _location_poses[requested]
			camera.global_transform = pose.transform
			camera.fov = pose.fov
			camera.keep_aspect = pose.keep_aspect
			_pitch = camera.global_rotation.x
			_yaw = camera.global_rotation.y
			_target_fov = camera.fov
			_velocity = Vector3.ZERO
		else:
			reset_pose()
	if is_instance_valid(_recording_house):
		_recording_house.call("set_state", settings[&"house_state"])
		_recording_house.call("apply_visibility", settings)
		if _environment._active and _environment._source_environment != _recording_house.get("environment"):
			_environment.restore()
		for node: Node3D in _world_visibility:
			if is_instance_valid(node):
				node.hide()
	if not _environment._active:
		var root: Node = _recording_house if is_instance_valid(_recording_house) else get_parent()
		var source: Environment = _recording_house.get("environment") if is_instance_valid(_recording_house) else null
		if not _environment.begin(root, camera, settings, source):
			return false
	return true


func _store_location_pose() -> void:
	if _has_pose:
		_location_poses[_recording_location] = {"transform":camera.global_transform, "fov":camera.fov, "keep_aspect":camera.keep_aspect}


func _hide_recording_world(node: Node) -> void:
	for child in node.get_children():
		if child == self:
			continue
		if node == get_parent():
			_world_process_modes[child] = child.process_mode
			child.process_mode = Node.PROCESS_MODE_DISABLED
		if child is Node3D:
			_world_visibility[child] = child.visible
			child.hide()
		_hide_recording_world(child)


func _restore_recording_world() -> void:
	for node in _world_visibility:
		if is_instance_valid(node):
			node.visible = _world_visibility[node]
	for node in _world_process_modes:
		if is_instance_valid(node) and (node != _player or not active):
			node.process_mode = _world_process_modes[node]
	_world_visibility.clear()
	_world_process_modes.clear()
	if is_instance_valid(_recording_house):
		remove_child(_recording_house)
		_recording_house.queue_free()
	_recording_house = null


func _add_target(key: StringName, node: Node3D) -> void:
	if node == null:
		return
	if not _visibility.has(node):
		_visibility[node] = node.visible
	if not _groups[key].has(node):
		_groups[key].append(node)


func _cache_player_layers(node: Node) -> void:
	if node is CanvasLayer and node != _pause_menu:
		_visibility[node] = node.visible
		node.hide()
	for child in node.get_children():
		_cache_player_layers(child)


func _apply_effects() -> void:
	var attributes := camera.attributes as CameraAttributesPractical
	if attributes != null:
		attributes.dof_blur_far_enabled = bool(_settings[&"dof_enabled"])
		if not bool(_settings[&"dof_enabled"]):
			attributes.dof_blur_near_enabled = false
	VhsCrtOverlay.set_recording_override(true, bool(_settings[&"vhs_enabled"]), _capture_time)


func _on_quality_changed() -> void:
	if active:
		_settings = DevMode.camera_settings()
		_environment.apply(_settings)
		_apply_effects()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_has_focus = false
		_velocity = Vector3.ZERO
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_has_focus = true


func _on_location_exiting() -> void:
	stop(false)


func _on_storm_arrived() -> void:
	stop(false)


func _exit_tree() -> void:
	stop(false)
