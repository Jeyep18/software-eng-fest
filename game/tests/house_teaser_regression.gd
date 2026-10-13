extends "res://game/tests/dev_camera_regression.gd"
## Uses the production pause/camera flow and the approved imported model.


func _run() -> void:
	if OS.get_environment("BAGYONG_ISOLATED_SMOKE") != OS.get_user_data_dir():
		push_error("House teaser checks require isolated user data.")
		get_tree().quit(1)
		return
	get_tree().current_scene = null
	TutorialModal.mark_do_not_show_again()
	SceneManager.reset()
	GlobalTimer.start_fresh()
	DevMode.begin_run()
	_check(not DevMode.set_camera_setting(&"recording_location", &"house_teaser"), "locked teaser selection is denied")
	_check(not DevMode.set_camera_setting(&"house_state", &"wrecked"), "locked state selection is denied")
	if not DevMode.is_available():
		_check(not DevMode.unlock() and not DevMode.start_camera_mode(null, null), "release denies the recording house")
		_finish()
		return
	DevMode.unlock()
	DevMode.set_enabled(true)
	DevMode.begin_run()
	for key in [&"recording_location", &"house_state"]:
		for invalid in [&"unknown", 4, true, null]:
			_check(not DevMode.set_camera_setting(key, invalid), "%s rejects invalid selection" % key)
	var visual := OS.get_cmdline_user_args().has("--visual-only")
	_check(not visual or DisplayServer.get_name() != "headless", "visual mode uses a rendered viewport")
	if visual:
		get_window().size = Vector2i(1920, 1080)
		get_window().content_scale_size = Vector2i(1920, 1080)
	for location in ["home", "grocery"]:
		if await _load_location(location):
			await _test_house(location, visual)
	if await _load_location("home"):
		DevMode.set_camera_setting(&"recording_location", &"house_teaser")
		if await _start_camera():
			var house: WeakRef = weakref(DevMode._camera_controller._recording_house)
			DevMode.set_enabled(false)
			await get_tree().process_frame
			_check(not DevMode.camera_active and house.get_ref() == null, "developer disable removes the set")
		DevMode.set_enabled(true)
		DevMode.set_camera_setting(&"recording_location", &"house_teaser")
		if await _start_camera():
			var controller: Variant = DevMode._camera_controller
			DevMode.end_run()
			await get_tree().process_frame
			_check(not DevMode.camera_active and not GlobalTimer._pause_owners.has(controller), "run end releases teaser ownership")
		DevMode.begin_run()
	if not visual:
		if await _load_location("home"):
			DevMode.set_camera_setting(&"recording_location", &"house_teaser")
			await _test_restart_and_title()
		if await _load_location("home"):
			await _test_teaser_transition()
	await _remove_scene()
	DevMode.end_run()
	_finish()


func _test_house(location: String, visual: bool) -> void:
	var original_visibility := {}
	var original_modes := {}
	for node in _nodes(_scene):
		if node is Node3D and node != _scene:
			original_visibility[node] = node.visible
	for child in _scene.get_children():
		original_modes[child] = child.process_mode
	var player_pose := _player.global_transform
	var settings_file := _settings_bytes()
	var gameplay_location := SceneManager.current_location
	DevMode.set_camera_setting(&"recording_location", &"house_teaser")
	DevMode.set_camera_setting(&"world_paused", true)
	DevMode.set_camera_setting(&"vhs_enabled", false)
	DevMode.set_camera_setting(&"dof_enabled", false)
	if not await _start_camera():
		return
	var controller: Variant = DevMode._camera_controller
	var house: Node3D = controller._recording_house
	var camera: Camera3D = controller.camera
	_check(house != null, "approved set loads from " + location)
	if house == null:
		return
	var native := house.get_node("Normal/GameplayHouse")
	_check(native.get_node_or_null("door") != null and native.get_node_or_null("Main_Door") != null, "normal keeps both gameplay doors")
	_check(native.get_node_or_null("Tv") != null and native.get_node_or_null("Fridge") != null, "normal keeps authored TV and fridge")
	_check(native.get_node_or_null("house_inside/sofa") != null, "normal includes the complete gameplay sofa")
	_check(native.get_node("OutsideEnv").find_children("tree07", "MeshInstance3D", true, false).size() == 11, "all eleven authored trees are included")
	var original_model := _scene.get_node_or_null("house_inside")
	if original_model != null:
		for mesh: MeshInstance3D in original_model.find_children("*", "MeshInstance3D", true, false):
			var copied := native.get_node("house_inside").get_node_or_null(original_model.get_path_to(mesh)) as MeshInstance3D
			_check(copied != null and copied.mesh == mesh.mesh and copied.global_transform.is_equal_approx(mesh.global_transform), "normal matches gameplay mesh and placement: " + str(mesh.name))
	_check(house.get_node("NPCs").get_child_count() == 2, "Nanay and Lola visuals are included")
	_check(native.get_script() == null and native.get_node("door").get_script() == null, "visual set has no house/door gameplay callbacks")
	for npc in house.get_node("NPCs").get_children():
		_check(npc.get_groups().is_empty(), "teaser NPC cannot register a duplicate gameplay actor")
	_check(controller._environment._sun != null and DevMode.camera_has_active_sun(), "teaser uses authored sunlight controls")
	for root in [native, house.get_node("NPCs"), house.get_node("WreckedProps")]:
		for node in _nodes(root):
			_check(node.get_script() == null or node is StormRainController, "visual copies contain no gameplay scripts")
			_check(node.get_groups().is_empty(), "visual copies do not join gameplay groups")
			if node is CollisionObject3D:
				_check(node.collision_layer == 0 and node.collision_mask == 0, "visual collision object is noninteractive")
				if node is Area3D:
					_check(not node.monitoring and not node.monitorable, "visual area cannot fire gameplay overlaps")
	var default_shot := house.call("reference_camera") as Camera3D
	_check(default_shot != null and camera.global_transform.is_equal_approx(default_shot.global_transform), "entry uses approved living/dining camera")
	_check(house.get_node("Normal").visible and not house.get_node("Wrecked").visible, "normal state is exclusive on entry")
	for node: Node3D in original_visibility:
		_check(not node.visible, "teaser isolates original geometry/lights: " + str(node.name))
	var clock := GlobalTimer.current_minutes
	var matched_pose := camera.global_transform
	var matched_fov := camera.fov
	var aspect := camera.keep_aspect
	for state in [&"wrecked", &"normal", &"wrecked"]:
		_check(DevMode.set_camera_setting(&"house_state", state), "live house state changes")
		await get_tree().process_frame
		_check(house.get_node("Normal").visible == (state == &"normal") and house.get_node("Wrecked").visible == (state == &"wrecked"), "exactly one model is visible")
		_check(camera.global_transform.is_equal_approx(matched_pose) and is_equal_approx(camera.fov, matched_fov) and camera.keep_aspect == aspect, "state change preserves camera framing")
		var expected_source: Environment = load("res://game/resources/environments/house1_environment.tres" if state == &"normal" else "res://game/resources/environments/storm_outdoor_environment.tres")
		_check(controller._environment._source_environment == expected_source, "state changes rebuild from the correct authored environment")
		_check(house.get_node("NPCs").visible == (state == &"normal"), "family visuals belong to the intact house")
	_check(house.get_node("WreckedProps").get_node_or_null("door") == null and house.get_node("WreckedProps").get_node_or_null("Main_Door") == null, "wrecked excludes door leaves")
	_check(house.get_node("WreckedProps").get_node_or_null("sofa") == null and house.get_node("Wrecked").find_child("Wrecked__Sofa_sofa frame*", true, false) != null, "wrecked keeps the approved damaged sofa without an overlapping copy")
	var normal_stand := native.get_node("house_inside").find_child("Chest_drawers_03*", true, false) as Node3D
	var wrecked_stand := house.get_node("Wrecked").find_child("Wrecked__Chest_drawers_03*", true, false) as Node3D
	var normal_tv := native.get_node("Tv") as Node3D
	var wrecked_tv := house.get_node("WreckedProps/Tv") as Node3D
	_check((normal_stand.global_transform.affine_inverse() * normal_tv.global_transform).is_equal_approx(wrecked_stand.global_transform.affine_inverse() * wrecked_tv.global_transform), "TV stays supported by its displaced cabinet")
	var storm_rain := house.get_node("WreckedWeather/StormRain") as StormRainController
	_check(storm_rain != null and storm_rain.intensity_bias == 1.0 and storm_rain.emitting, "wrecked storm presentation rains independently of gameplay time")
	_check(not storm_rain.can_process(), "world freeze pauses teaser rain")
	_check(house.get_node("Wrecked").find_child("Flood__Interior_Water_Surface*", true, false) != null, "flood surface survives import")
	_check(house.get_node("Wrecked").find_child("Flood__Textured_Marks_Wrecked__Walls*", true, false) != null, "textured flood marks survive import")
	var texture_count := 0
	for node in _nodes(house):
		if node is MeshInstance3D:
			for surface in node.mesh.get_surface_count():
				var material := node.get_active_material(surface) as BaseMaterial3D
				if material != null and material.albedo_texture != null:
					texture_count += 1
	_check(texture_count > 200, "house textures remain assigned")
	if visual and location == "home":
		camera.global_transform = controller._gameplay_camera.global_transform
		camera.fov = controller._gameplay_camera.fov
		controller._pitch = camera.global_rotation.x
		controller._yaw = camera.global_rotation.y
		controller._target_fov = camera.fov
		for state in [&"normal", &"wrecked"]:
			DevMode.set_camera_setting(&"house_state", state)
			await _render_frames(24)
			await _capture("teaser_gameplay_frame_%s" % state)
		camera.global_transform = default_shot.global_transform
		camera.fov = default_shot.fov
		controller._pitch = camera.global_rotation.x
		controller._yaw = camera.global_rotation.y
		controller._target_fov = camera.fov
		DevMode.set_camera_setting(&"house_state", &"normal")
		await _render_frames(24)
		await _capture("teaser_npcs_visible")
		DevMode.set_camera_setting(&"hide_npcs", true)
		await _render_frames(12)
		await _capture("teaser_npcs_hidden")
		DevMode.set_camera_setting(&"hide_npcs", false)
	if visual and location == "home":
		for entry in [["01_living_dining", "ReviewCamera__01_living_dining*"], ["02_reverse_living", "ReviewCamera__02_reverse_living*"], ["03_bedroom", "ReviewCamera__03_bedroom*"]]:
			var shot := house.get_node("Normal").find_child(entry[1], true, false) as Camera3D
			_check(shot != null, "review shot imported: " + entry[0])
			if shot == null:
				continue
			camera.global_transform = shot.global_transform
			camera.fov = shot.fov
			camera.keep_aspect = shot.keep_aspect
			controller._pitch = camera.global_rotation.x
			controller._yaw = camera.global_rotation.y
			controller._target_fov = camera.fov
			for state in [&"normal", &"wrecked"]:
				DevMode.set_camera_setting(&"house_state", state)
				await _render_frames(24)
				await _capture("teaser_%s_%s" % [entry[0], state])
	_key(KEY_G, true)
	_key(KEY_G, false)
	await get_tree().process_frame
	_check(house.get("state") == &"normal", "G toggles to normal")
	DevMode.set_camera_setting(&"world_paused", false)
	DevMode.set_camera_setting(&"hide_npcs", true)
	DevMode.set_camera_setting(&"hide_items", true)
	for npc in house.get_node("NPCs").get_children():
		_check(not npc.visible, "Hide NPCs affects teaser actors")
	DevMode.set_camera_setting(&"hide_npcs", false)
	for npc in house.get_node("NPCs").get_children():
		_check(npc.visible, "unhiding NPCs restores teaser actors")
	if visual and location == "home":
		camera.global_transform = default_shot.global_transform
		camera.fov = default_shot.fov
		controller._pitch = camera.global_rotation.x
		controller._yaw = camera.global_rotation.y
		controller._target_fov = camera.fov
	for state in [&"normal", &"wrecked"]:
		DevMode.set_camera_setting(&"house_state", state)
		for preset in PRESETS:
			DevMode.set_camera_setting(&"environment_preset", preset)
			var base_exposure: float = house.get("environment").tonemap_exposure
			var multiplier: float = {&"storm":1.0, &"sunrise":1.3, &"sunny":1.65, &"sunset":1.15}[preset]
			_check(is_equal_approx(controller.camera.environment.tonemap_exposure, base_exposure * multiplier), "preset exposure uses one authored state baseline")
			_check(storm_rain._recording_dry == (preset != &"storm"), "dry presets suppress wrecked rain")
			storm_rain._apply_intensity()
			_check(storm_rain.emitting == (preset == &"storm"), "weather refresh cannot override recording rain selection")
			for node: Node3D in original_visibility:
				_check(not node.visible, "preset/hide setting cannot reveal source world")
			if visual and location == "home":
				DevMode.set_camera_setting(&"world_paused", true)
				await _render_frames(30)
				await _capture("teaser_presets_%s_%s" % [state, preset])
	_check(_player.global_transform.is_equal_approx(player_pose) and SceneManager.current_location == gameplay_location, "teaser preserves gameplay position and destination")
	_check(GlobalTimer.current_minutes == clock, "teaser holds the deadline while live and frozen")
	_check(_settings_bytes() == settings_file, "teaser does not save graphics settings")
	DevMode.set_camera_setting(&"recording_location", &"current")
	_check(_player.process_mode == Node.PROCESS_MODE_DISABLED, "location switching keeps camera ownership of player input")
	_check(controller._recording_house == null and not controller._environment._source_environment == house.get("environment"), "current location releases teaser lighting")
	DevMode.set_camera_setting(&"recording_location", &"house_teaser")
	_check(controller._recording_house != null, "returning to teaser restores its shot")
	var retained_pose := camera.global_transform
	DevMode.stop_camera_mode()
	await get_tree().process_frame
	for node: Node3D in original_visibility:
		if is_instance_valid(node):
			_check(node.visible == original_visibility[node], "exit restores visibility: " + str(node.name))
	for node in original_modes:
		_check(node.process_mode == original_modes[node], "exit restores source process mode")
	_check(controller._recording_house == null and not StormAudioController._recording_dry, "exit removes teaser and weather override")
	if await _start_camera():
		_check(camera.global_transform.is_equal_approx(retained_pose), "reentry preserves teaser shot")
		DevMode.reset_camera_pose()
		_check(camera.global_transform.is_equal_approx(controller._recording_house.call("reference_camera").global_transform), "Reset Camera returns to the teaser composition")
		DevMode.stop_camera_mode()
	if visual and location == "home":
		await _test_panel_visuals()
	_reset_settings()


func _test_teaser_transition() -> void:
	DevMode.set_camera_setting(&"recording_location", &"house_teaser")
	if not await _start_camera():
		return
	var old_house: WeakRef = weakref(DevMode._camera_controller._recording_house)
	DevMode.stop_camera_mode()
	_pause._on_dev_teleport_requested("hardware")
	if not await _wait_until(func(): return SceneManager.current_location == "hardware" and not SceneManager.is_travelling and TransitionOverlay.overlay.color.a < 0.01, "teaser exit permits developer teleport", 12.0):
		return
	_check(old_house.get_ref() == null, "teleport leaves no old teaser set")
	_scene = get_tree().current_scene as Node3D
	_player = _scene.get_node("playerv2") as PlayerV2
	_pause = _player.get_node("PauseMenu") as CanvasLayer
	if await _start_camera():
		old_house = weakref(DevMode._camera_controller._recording_house)
		_check(old_house.get_ref() != null, "new gameplay destination can enter the teaser")
		GlobalTimer.add_time(GlobalTimer.TOTAL_MINUTES)
		if await _wait_until(func(): return get_tree().current_scene != null and get_tree().current_scene.scene_file_path == SceneManager.SCENE_PATHS["ending"], "storm cleans up the teaser before ending", 12.0):
			_check(old_house.get_ref() == null and not DevMode.camera_active and not get_tree().paused, "storm removes set and recording ownership")
			_scene = get_tree().current_scene as Node3D
			_player = null
			_pause = null
