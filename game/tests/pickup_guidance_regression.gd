extends Node

var _checks := 0
var _failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	if OS.get_environment("BAGYONG_ISOLATED_SMOKE") != OS.get_user_data_dir():
		push_error("Pickup guidance regression requires isolated userdata.")
		get_tree().quit(1)
		return
	SceneManager.has_played_opening = true
	await _check_location("res://game/scenes/locations/bodega.tscn", [
		Vector3(-1.77, 0.0, -3.64), Vector3(-6.0, 0.0, -4.0)])
	await _check_location("res://game/scenes/locations/hardware.tscn", [
		Vector3(-12.93, 0.03, -4.84)])
	print("Pickup guidance regression: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(1 if _failures else 0)


func _check_location(path: String, starts: Array[Vector3]) -> void:
	GameState.reset()
	InventoryManager.reset()
	NeedsLog.reset()
	var location := (load(path) as PackedScene).instantiate() as Node3D
	add_child(location)
	var guidance := location.get_node("PickupGuidance")
	var player := location.get_node("playerv2") as PlayerV2
	player.set_physics_process(false)
	var deadline := Time.get_ticks_msec() + 3000
	var geometry_ready := false
	while Time.get_ticks_msec() < deadline:
		if NavigationServer3D.map_get_iteration_id(guidance._map) > 0:
			var closest := NavigationServer3D.map_get_closest_point(guidance._map, player.global_position)
			geometry_ready = closest.distance_to(player.global_position) < 0.75
			if geometry_ready:
				break
		await get_tree().create_timer(0.05).timeout
	_check(geometry_ready, path + " navigation geometry synchronized")
	_check(guidance._items.size() == 3, path + " has three configured vital pickups")
	var first_route := PackedVector3Array()
	for item in guidance._items:
		var route := PackedVector3Array()
		for start in starts:
			player.global_position = start
			route = guidance._calculate_route(item)
			if not route.is_empty():
				break
		_check(route.size() >= 2, path + " route to " + item.world_item_id)
		if item == guidance._items[0]:
			first_route = route
		if route.size() >= 2:
			var end: Vector3 = route[route.size() - 1]
			_check(Vector2(end.x, end.z).distance_to(Vector2(item.global_position.x, item.global_position.z)) <= 1.5,
				path + " route ends by " + item.world_item_id)
			_check(guidance._route_is_clear(route), path + " route avoids collisions to " + item.world_item_id)
		GameState.mark_item_collected(item.world_item_id)
		_check(not guidance._is_eligible(item), path + " collected " + item.world_item_id + " is not hinted")
		GameState.collected_world_items.erase(item.world_item_id)
	var first_item: WorldItem = guidance._items[0]
	player.global_position = Vector3(100.0, 0.0, 100.0)
	_check(guidance._calculate_route(first_item).is_empty(), path + " rejects a route from outside the scene")
	player.global_position = starts[0]
	if path.contains("hardware") and first_route.size() >= 2:
		guidance._set_route(first_route)
		_check(guidance._pulse_duration > 5.0, "long hardware hint stays readable")
	if DisplayServer.get_name() != "headless":
		_check(guidance._can_show(), path + " permits gameplay hint")
	if first_route.size() >= 2 and guidance._can_show():
		guidance._target = first_item
		guidance._set_route(first_route)
		guidance._pulse_elapsed = 0.0
		guidance._wind.show()
		guidance._wind.restart()
		guidance._wind.emitting = true
		var wind_start: Vector3 = guidance._wind.global_position
		guidance._process(guidance.PULSE_DURATION * 0.1)
		_check(guidance._wind.global_position.distance_to(wind_start) > 0.1,
			path + " wind source travels along the route")
		_check(guidance._wind.trail_enabled and guidance._wind.draw_pass_1 is RibbonTrailMesh,
			path + " wind motes have short ribbon trails")
		if OS.get_cmdline_user_args().has("--visual-only"):
			await get_tree().create_timer(0.35).timeout
			await RenderingServer.frame_post_draw
			var location_name := "hardware" if path.contains("hardware") else "bodega"
			for phase in ["early", "late"]:
				if phase == "late":
					await get_tree().create_timer(0.65).timeout
					await RenderingServer.frame_post_draw
				var image_path := "user://pickup_guidance_%s_%s.png" % [location_name, phase]
				_check(get_viewport().get_texture().get_image().save_png(image_path) == OK, "saved guidance visual in " + path)
				print("PICKUP GUIDANCE IMAGE ", ProjectSettings.globalize_path(image_path))
		GameState.mark_item_collected(first_item.world_item_id)
		guidance._process(0.01)
		_check(guidance._target == null and not guidance._wind.visible and not guidance._wind.emitting,
			path + " active hint stops when the item is collected")
		GameState.collected_world_items.erase(first_item.world_item_id)
		guidance._target = first_item
		guidance._set_route(first_route)
		guidance._pulse_elapsed = 0.0
		guidance._wind.show()
		guidance._wind.emitting = true
	player._is_movement_locked = true
	_check(not guidance._can_show(), path + " suppresses modal or dialogue lock")
	guidance._process(0.01)
	_check(not guidance._wind.visible and not guidance._wind.emitting, path + " modal hides active hint")
	player._is_movement_locked = false
	get_tree().paused = true
	_check(not guidance._can_show(), path + " suppresses pause")
	get_tree().paused = false
	if path.contains("hardware"):
		for _i in range(InventoryManager.MAX_INVENTORY_SIZE):
			InventoryManager.add_item(load("res://game/resources/items/hammer.tres"))
		_check(not guidance._is_eligible(first_item), "full bag suppresses plywood hint")
	location.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("Pickup guidance regression: " + description)
