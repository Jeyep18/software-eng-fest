extends Node
## Run in an imported disposable copy with isolated APPDATA/LOCALAPPDATA.

const PRESETS: Array[StringName] = [&"storm", &"sunrise", &"sunny", &"sunset"]
const LOCATIONS: Array[String] = ["home", "ate_linda", "hardware", "pharmacy", "grocery", "bodega"]

var _checks: int = 0
var _failures: int = 0
var _scene: Node3D
var _player: PlayerV2
var _pause: Variant


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("Recording camera regression: " + description)


func _run() -> void:
	if OS.get_environment("BAGYONG_ISOLATED_SMOKE") != OS.get_user_data_dir():
		push_error("Recording camera regression requires explicitly isolated userdata.")
		get_tree().quit(1)
		return
	get_tree().current_scene = null
	TutorialModal.mark_do_not_show_again()
	SceneManager.reset()
	GlobalTimer.start_fresh()
	DevMode.begin_run()
	_check(not DevMode.start_camera_mode(null, null), "locked direct camera entry is denied")
	_check(not DevMode.set_camera_setting(&"speed", 7.0), "locked direct settings are denied")
	if not DevMode.is_available():
		_check(not DevMode.unlock() and not DevMode.set_enabled(true), "packaged release cannot enable developer tools")
		_check(not DevMode.reset_camera_pose() and not DevMode.reset_environment_preset(), "packaged release cannot invoke camera reset APIs")
		DevMode.stop_camera_mode(false)
		_check(not DevMode.camera_active, "release cleanup remains safe while tools are unavailable")
		VhsCrtOverlay.set_recording_override(true, false, 12.0)
		_check(not VhsCrtOverlay._recording_override and VhsCrtOverlay._material.get_shader_parameter("use_capture_time") != true, "release direct VHS override cannot bypass developer authorization")
		StormAudioController.set_recording_dry(true)
		_check(not StormAudioController._recording_dry, "release direct weather override cannot bypass developer authorization")
		_finish()
		return
	_check(DevMode.unlock() and DevMode.set_enabled(true), "authorized developer mode can be enabled")
	DevMode.begin_run()
	_check(DevMode.run_unranked, "camera tools retain unranked developer runs")
	var original_quality := VisualSettings.get_quality_preset()
	VisualSettings.set_quality_preset(VisualSettings.QUALITY_PERFORMANCE if original_quality != VisualSettings.QUALITY_PERFORMANCE else VisualSettings.QUALITY_HIGH)
	VisualSettings.set_quality_preset(original_quality)
	_check(FileAccess.file_exists(VisualSettings.SETTINGS_PATH), "isolated fixture seeds an actual saved graphics preference file")
	_test_settings()
	if OS.get_cmdline_user_args().has("--visual-only"):
		_check(DisplayServer.get_name() != "headless", "visual checks require a rendered display")
		if DisplayServer.get_name() != "headless":
			await _test_visuals()
	else:
		for location_id in LOCATIONS:
			if await _load_location(location_id):
				await _test_location(location_id)
		if await _load_location("grocery"):
			await _test_entry_guards()
			await _test_camera_controls()
			await _test_graphics_refresh()
			await _test_cleanup()
		if await _load_location("home"):
			await _test_restart_and_title()
		if await _load_location("home"):
			await _test_teleport_and_storm()
	await _remove_scene()
	DevMode.end_run()
	_finish()


func _finish() -> void:
	print("Recording camera regression: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(1 if _failures else 0)


func _test_settings() -> void:
	var defaults := DevMode.camera_settings()
	_check(is_equal_approx(float(defaults.speed), 5.0) and is_equal_approx(float(defaults.sensitivity), 0.1), "default camera speed and sensitivity")
	_check(not defaults.cinematic and not defaults.world_paused and defaults.environment_preset == &"storm", "default live world, ordinary motion, and authored storm")
	_check(defaults.hide_player and defaults.hide_indicators and not defaults.hide_npcs and not defaults.hide_animals and not defaults.hide_items, "default visibility keeps scene characters and pickups")
	_check(defaults.vhs_enabled == VisualSettings.is_vhs_crt_enabled() and defaults.dof_enabled == VisualSettings.should_use_camera_depth_of_field(), "recording effects start from current graphics preferences")
	defaults.speed = 17.0
	_check(is_equal_approx(float(DevMode.camera_settings().speed), 5.0), "settings reads cannot mutate stored preferences")
	var ranges := {
		&"speed": Vector2(0.5, 20.0), &"sensitivity": Vector2(0.02, 0.5),
		&"brightness": Vector2(0.25, 2.0), &"sun_strength": Vector2(0.0, 2.0),
		&"fog_amount": Vector2(0.0, 2.0), &"sky_rotation": Vector2(-180.0, 180.0),
	}
	for key: StringName in ranges:
		var bounds: Vector2 = ranges[key]
		for invalid in [NAN, INF, -INF, "invalid"]:
			var old_value: Variant = DevMode.camera_settings()[key]
			_check(not DevMode.set_camera_setting(key, invalid) and DevMode.camera_settings()[key] == old_value, "%s rejects invalid number without changing its value" % key)
		for requested in [bounds.x - 10.0, bounds.x, bounds.y, bounds.y + 10.0]:
			DevMode.set_camera_setting(key, requested)
			var value: float = DevMode.camera_settings()[key]
			_check(is_finite(value) and value >= bounds.x and value <= bounds.y, "%s always stays in its approved range" % key)
	_check(not DevMode.set_camera_setting(&"unknown", true), "unknown camera preference is rejected")
	_check(not DevMode.set_camera_setting(&"cinematic", "true"), "boolean preference rejects a string")
	_check(not DevMode.set_camera_setting(&"environment_preset", &"unknown"), "unknown environment is rejected")
	_check(DevMode.reset_environment_preset(), "preset adjustment reset is available to authorized developers")
	DevMode.set_camera_setting(&"environment_preset", &"sunrise")
	DevMode.set_camera_setting(&"brightness", 0.7)
	DevMode.set_camera_setting(&"environment_preset", &"sunny")
	DevMode.set_camera_setting(&"brightness", 1.4)
	DevMode.reset_environment_preset()
	_check(is_equal_approx(float(DevMode.camera_settings().brightness), 1.0), "Reset Preset restores the selected look's default adjustments")
	DevMode.set_camera_setting(&"environment_preset", &"sunrise")
	_check(is_equal_approx(float(DevMode.camera_settings().brightness), 0.7), "Reset Preset preserves adjustments for a different look")
	DevMode.reset_environment_preset()
	_reset_settings()


func _reset_settings() -> void:
	var defaults := {
		&"speed": 5.0, &"sensitivity": 0.1, &"cinematic": false, &"world_paused": false,
		&"hide_player": true, &"hide_npcs": false, &"hide_animals": false,
		&"hide_items": false, &"hide_indicators": true, &"environment_preset": &"storm",
		&"recording_location": &"current", &"house_state": &"normal",
		&"vhs_enabled": VisualSettings.is_vhs_crt_enabled(),
		&"dof_enabled": VisualSettings.should_use_camera_depth_of_field(),
	}
	for key: StringName in defaults:
		DevMode.set_camera_setting(key, defaults[key])
	DevMode.reset_environment_preset()


func _nodes(root: Node) -> Array[Node]:
	var result: Array[Node] = [root]
	for child in root.get_children():
		result.append_array(_nodes(child))
	return result


func _wait_until(condition: Callable, description: String, seconds: float = 8.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await get_tree().create_timer(0.02, true).timeout
	var passed: bool = condition.call()
	_check(passed, description)
	return passed


func _load_location(location_id: String) -> bool:
	await _remove_scene()
	get_tree().paused = false
	ShopUi.reset()
	SceneManager.reset()
	StormEnroachment.reset()
	InventoryManager.reset()
	NeedsLog.reset()
	SideQuestLog.reset()
	GameState.reset()
	GlobalTimer.start_fresh()
	GlobalTimer.seconds_per_game_minute = 0.05
	DevMode.begin_run()
	SceneManager.has_played_opening = true
	SceneManager.current_location = "home" if location_id == "bodega" else location_id
	GameState.house_tasks_unlocked = true
	var packed := load(SceneManager.SCENE_PATHS[location_id]) as PackedScene
	_check(packed != null, location_id + " production location loads")
	if packed == null:
		return false
	_scene = packed.instantiate() as Node3D
	get_tree().root.add_child(_scene)
	get_tree().current_scene = _scene
	await get_tree().process_frame
	await get_tree().process_frame
	_player = _scene.get_node_or_null("playerv2") as PlayerV2
	_pause = null
	for node in _nodes(_scene):
		if node is CanvasLayer and node.get_script() != null and node.get_script().resource_path.ends_with("/pause/PauseMenu.gd"):
			_pause = node
	_check(_player != null and _pause != null, location_id + " has the active player and production pause menu")
	if _player == null or _pause == null:
		return false
	if not await _wait_until(func(): return TransitionOverlay.overlay.color.a < 0.01 and (TransitionOverlay.tween == null or not TransitionOverlay.tween.is_running()) and not _player._is_input_locked, location_id + " finishes its opening fade"):
		return false
	GlobalTimer.seconds_per_game_minute = 0.05
	_reset_settings()
	return true


func _remove_scene() -> void:
	DevMode.stop_camera_mode(false)
	if is_instance_valid(_scene):
		get_tree().current_scene = null
		_scene.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	_scene = null
	_player = null
	_pause = null
	get_tree().paused = false


func _open_dev_tab() -> bool:
	if not is_instance_valid(_pause):
		return false
	if not _pause.visible:
		_pause._open()
	if not await _wait_until(func(): return not _pause._transitioning, "pause menu finishes its fade"):
		return false
	_pause._on_nav_dev()
	await get_tree().process_frame
	return true


func _start_camera() -> bool:
	if not await _open_dev_tab():
		return false
	var started := DevMode.start_camera_mode(_player, _pause)
	_check(started and DevMode.camera_active, "production pause menu enters recording camera")
	if not started:
		print("RECORDING ENTRY STATE can_use=", DevMode.can_use(), " pause=", _pause.visible, " fading=", _pause._transitioning,
			" locks=", _player._is_input_locked, "/", _player._is_movement_locked, " shop=", ShopUi.is_open(),
			" overlay=", TransitionOverlay.overlay.color.a, " blocked=", DevMode._camera_entry_blocked(_scene))
	return started


func _world_environment() -> WorldEnvironment:
	for node in _nodes(_scene):
		if node is WorldEnvironment:
			return node
	return null


func _sun() -> DirectionalLight3D:
	for node in _nodes(_scene):
		if node is DirectionalLight3D:
			return node
	return null


func _test_location(location_id: String) -> void:
	await _test_location_visibility(location_id)
	var world := _world_environment()
	var sun := _sun()
	_check(world != null and world.environment != null, location_id + " has an authored environment")
	if world == null or world.environment == null:
		return
	var environment := world.environment
	var environment_before := {
		"sky": environment.sky, "brightness": environment.adjustment_brightness,
		"ambient": environment.ambient_light_energy, "fog": environment.fog_density,
		"background": environment.background_mode,
	}
	var lights_before := {}
	for node in _nodes(_scene):
		if node is Light3D and not node.get_parent() is TaskCue3D:
			lights_before[node] = [node.visible, node.light_energy, node.light_color, node.global_transform,
				node.get_meta("visual_quality_base_energy", -1.0)]
	var rain_before := {}
	var audio_before := {}
	for node in _nodes(_scene):
		if node is GPUParticles3D and node.has_method("set_recording_dry"):
			rain_before[node] = [node.visible, node.emitting]
		elif node is AudioStreamPlayer3D:
			audio_before[node] = [node.volume_db, node.stream_paused]
	var preferences_before := _settings_bytes()
	var timer_owner := Node.new()
	add_child(timer_owner)
	GlobalTimer.pause_timer(timer_owner)
	for preset in PRESETS:
		DevMode.set_camera_setting(&"environment_preset", preset)
		DevMode.reset_environment_preset()
		if not await _start_camera():
			break
		var controller: Variant = DevMode._camera_controller
		var camera: Camera3D = controller.camera
		_check(camera.current and not _player.is_ancestor_of(controller), location_id + " free camera lives outside the disabled player")
		_check(camera.environment != null and camera.environment != environment, location_id + " " + String(preset) + " owns its temporary environment")
		_check(world.environment == environment and environment.sky == environment_before.sky, location_id + " preset leaves authored environment and sky attached")
		_check(environment.adjustment_brightness == environment_before.brightness and environment.ambient_light_energy == environment_before.ambient and environment.fog_density == environment_before.fog and environment.background_mode == environment_before.background, location_id + " preset does not mutate authored environment fields")
		_check(GlobalTimer._pause_owners.has(controller), "recording camera holds its own deadline pause")
		if preset != &"storm":
			for rain: GPUParticles3D in rain_before:
				rain.call("_apply_intensity")
				_check(not rain.visible and not rain.emitting, location_id + " dry preset suppresses rain even after weather refresh")
			for audio: AudioStreamPlayer3D in audio_before:
				if audio.stream == null:
					continue
				var stream_path: String = audio.stream.resource_path.to_lower()
				if "wind-rain" in stream_path:
					_check(audio.stream_paused or audio.volume_db <= -75.0, "dry preset suppresses local weather audio")
				else:
					_check(audio.volume_db == audio_before[audio][0] and audio.stream_paused == audio_before[audio][1], "dry preset preserves nonweather local ambience")
			if sun != null and not lights_before[sun][0]:
				_check(not sun.visible, location_id + " preset preserves intentionally hidden sunlight")
		DevMode.stop_camera_mode()
		_check(not DevMode.camera_active and get_tree().paused and _pause.visible and _pause._dev_panel.visible, "exit restores the paused developer tab")
		_check(not GlobalTimer._pause_owners.has(controller) and GlobalTimer._pause_owners.has(timer_owner), "camera exit releases only its timer owner")
		for light: Light3D in lights_before:
			var old: Array = lights_before[light]
			_check(light.visible == old[0] and is_equal_approx(light.light_energy, old[1]) and light.light_color == old[2] and light.global_transform.is_equal_approx(old[3]) and light.get_meta("visual_quality_base_energy", -1.0) == old[4], location_id + " restores lighting and quality baseline: " + light.name)
		for rain: GPUParticles3D in rain_before:
			_check(rain.visible == rain_before[rain][0] and rain.emitting == rain_before[rain][1], location_id + " restores authored weather visibility")
		_check(_settings_bytes() == preferences_before, "recording preset leaves the saved graphics file unchanged")
	GlobalTimer.resume_timer(timer_owner)
	timer_owner.queue_free()
	DevMode.stop_camera_mode(false)
	get_tree().paused = false


func _settings_bytes() -> PackedByteArray:
	return FileAccess.get_file_as_bytes(VisualSettings.SETTINGS_PATH) if FileAccess.file_exists(VisualSettings.SETTINGS_PATH) else PackedByteArray()


func _test_location_visibility(location_id: String) -> void:
	var targets := {&"hide_player": [_player.get_node("visuals")], &"hide_npcs": [],
		&"hide_animals": [], &"hide_items": [], &"hide_indicators": []}
	var completed_visuals: Array[Node3D] = []
	for node in _nodes(_scene):
		if node is NPC:
			var actor := node.get_parent() as Node3D
			targets[&"hide_npcs"].append(actor if actor != null and actor != _scene else node)
		elif node is AmbientAnimal:
			targets[&"hide_animals"].append(node)
		elif node is WorldItem:
			targets[&"hide_items"].append(node)
		elif node is TaskCue3D or (node is Node3D and node.get_script() != null and node.get_script().resource_path.ends_with("/PickupGuidance3D.gd")):
			targets[&"hide_indicators"].append(node)
		if node is TaskObject and node.completion_visual_cue is Node3D:
			completed_visuals.append(node.completion_visual_cue)
	var original_visibility := {}
	for key: StringName in targets:
		DevMode.set_camera_setting(key, false)
		for target: Node3D in targets[key]:
			original_visibility[target] = target.visible
		if not targets[key].is_empty():
			targets[key][0].hide()
	var staged_visibility := {}
	for target: Node3D in original_visibility:
		staged_visibility[target] = target.visible
	var completed_visibility := {}
	for visual in completed_visuals:
		completed_visibility[visual] = visual.visible
		visual.show()
	if await _start_camera():
		for key: StringName in targets:
			_check(DevMode.set_camera_setting(key, true), location_id + " accepts the " + String(key) + " setting")
			for target: Node3D in targets[key]:
				_check(not target.is_visible_in_tree(), location_id + " hides the production " + String(key) + " target " + target.name)
			if key == &"hide_indicators":
				for visual in completed_visuals:
					_check(visual.is_visible_in_tree(), "indicator hiding preserves physical preparation results")
			DevMode.set_camera_setting(key, false)
			for target: Node3D in targets[key]:
				_check(target.visible == staged_visibility[target], location_id + " showing " + String(key) + " preserves previously hidden targets")
		DevMode.stop_camera_mode()
		for target: Node3D in staged_visibility:
			_check(target.visible == staged_visibility[target], location_id + " exit restores original visibility for " + target.name)
	for target: Node3D in original_visibility:
		target.visible = original_visibility[target]
	for visual in completed_visibility:
		visual.visible = completed_visibility[visual]
	_reset_settings()
	_pause._prepare_scene_exit()
	await get_tree().process_frame


func _test_entry_guards() -> void:
	await _open_dev_tab()
	_check(not DevMode.start_camera_mode(null, _pause), "entry denies a missing player")
	_check(not DevMode.start_camera_mode(_player, null), "entry denies a missing pause menu")
	_player._is_input_locked = true
	_check(not DevMode.start_camera_mode(_player, _pause), "entry denies the startup animation input lock")
	_player._is_input_locked = false
	_player._is_movement_locked = true
	_check(not DevMode.start_camera_mode(_player, _pause), "entry denies a dialogue or task movement lock")
	_player._is_movement_locked = false
	SceneManager.is_travelling = true
	_check(not DevMode.start_camera_mode(_player, _pause), "entry denies an active travel transition")
	SceneManager.is_travelling = false
	SceneManager.storm_transition_pending = true
	_check(not DevMode.start_camera_mode(_player, _pause), "entry denies a pending storm transition")
	SceneManager.storm_transition_pending = false
	TransitionOverlay.overlay.color.a = 0.5
	_check(not DevMode.start_camera_mode(_player, _pause), "entry denies a covered fade")
	TransitionOverlay.overlay.color.a = 0.0
	var npc: NPC
	for node in _nodes(_scene):
		if node is NPC:
			npc = node
			break
	if npc != null:
		npc._is_showing = true
		npc.is_showing = true
		_check(not DevMode.start_camera_mode(_player, _pause), "entry denies a running NPC dialogue")
		npc._is_showing = false
		npc.is_showing = false
	ShopUi.open_shop(load("res://game/resources/items/shops/HardwareShop.tres"))
	_check(not DevMode.start_camera_mode(_player, _pause), "entry denies a running shop")
	ShopUi.close_shop(true)
	var tutorial := load("res://game/ui/tutorial/TutorialModal.tscn").instantiate() as TutorialModal
	_player.add_child(tutorial)
	tutorial.open(false, false, Callable())
	_check(not DevMode.start_camera_mode(_player, _pause), "entry denies the active tutorial")
	tutorial.queue_free()
	await get_tree().process_frame
	get_tree().paused = true
	DevMode.end_run()
	_check(not DevMode.start_camera_mode(_player, _pause), "entry denies a finished run")
	DevMode.begin_run()
	_check(DevMode.set_enabled(false), "developer mode disables")
	_check(not DevMode.start_camera_mode(_player, _pause), "disabled mode denies direct entry")
	DevMode.set_enabled(true)


func _test_camera_controls() -> void:
	var original_transform := _player.global_transform
	var original_process_mode := _player.process_mode
	var gameplay_camera := get_viewport().get_camera_3d()
	var gameplay_pose := gameplay_camera.global_transform
	var gameplay_fov := gameplay_camera.fov
	var hotbar: Variant = get_tree().get_first_node_in_group("hotbar_ui")
	var selected_slot: int = hotbar.selected_slot
	var old_visibility := {}
	var hidden_npc: Node3D
	var hidden_item: WorldItem
	for node in _nodes(_scene):
		if node is AmbientAnimal or node is WorldItem or node is TaskCue3D or (node is Node3D and node.name == "visuals"):
			old_visibility[node] = node.visible
		if node is NPC and hidden_npc == null:
			hidden_npc = node.get_parent().get_node_or_null("visuals") as Node3D
		if node is WorldItem and hidden_item == null:
			hidden_item = node
	if hidden_npc != null:
		hidden_npc.hide()
	if hidden_item != null:
		hidden_item.hide()
	for key in [&"hide_npcs", &"hide_animals", &"hide_items"]:
		DevMode.set_camera_setting(key, true)
	if not await _start_camera():
		return
	var controller: Variant = DevMode._camera_controller
	var camera: Camera3D = controller.camera
	_check(camera.global_transform.is_equal_approx(gameplay_pose) and is_equal_approx(camera.fov, gameplay_fov), "first camera entry copies the gameplay camera framing")
	_check(_player.process_mode == Node.PROCESS_MODE_DISABLED, "recording disables player gameplay processing")
	_check(not _pause.visible and not CursorState.is_requesting_visible(_pause), "recording closes pause and releases its visible cursor request")
	_check(not get_tree().paused and GlobalTimer.is_paused, "live world still holds the preparation clock")
	var minute_before := GlobalTimer.current_minutes
	await get_tree().create_timer(0.25, true).timeout
	_check(GlobalTimer.current_minutes == minute_before, "live recording keeps a deadline fixed while real time elapses")
	for node in _nodes(_player):
		if node is CanvasLayer:
			_check(not node.visible, "recording hides player HUD and gameplay menu: " + node.name)
	for node in _nodes(_scene):
		if node is AmbientAnimal or node is WorldItem:
			_check(not node.is_visible_in_tree(), "recording hide option suppresses " + node.name)
		elif node is NPC:
			var visuals := node.get_parent().get_node_or_null("visuals") as Node3D
			if visuals != null:
				_check(not visuals.is_visible_in_tree(), "recording hide option suppresses NPC model " + node.get_parent().name)
		elif node is TaskCue3D:
			_check(not node.is_visible_in_tree(), "recording hides task indicators")
	for action in [&"toggle_backpack", &"open_map", &"hotbar_slot_4", &"interact"]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = true
		Input.parse_input_event(event)
		event = InputEventAction.new()
		event.action = action
		event.pressed = false
		Input.parse_input_event(event)
	await get_tree().process_frame
	_check(not get_tree().get_first_node_in_group("backpack_ui").visible and not get_tree().get_first_node_in_group("map_screen").visible and hotbar.selected_slot == selected_slot, "recording inputs cannot open gameplay menus or select hotbar slots")
	_key(KEY_P, true)
	_key(KEY_P, false)
	_check(DevMode.camera_settings().world_paused and get_tree().paused, "P freezes the world without exiting camera mode")
	await get_tree().process_frame
	var frozen_time: float = controller._capture_time
	var animation_positions := _animation_positions()
	await get_tree().create_timer(0.25, true).timeout
	_check(is_equal_approx(controller._capture_time, frozen_time), "freeze holds the recording effect clock")
	_check(_animations_unchanged(animation_positions), "freeze holds actual location animation playback")
	_check(GlobalTimer.current_minutes == minute_before, "frozen recording keeps deadline fixed")
	_key(KEY_W, true)
	await get_tree().create_timer(0.2, true).timeout
	_key(KEY_W, false)
	_check(camera.global_position.distance_to(gameplay_pose.origin) > 0.1, "W moves the free camera while the world is frozen")
	_key(KEY_E, true)
	var before_up := camera.global_position
	await get_tree().create_timer(0.1, true).timeout
	_key(KEY_E, false)
	_check(camera.global_position.y > before_up.y, "E moves upward")
	_key(KEY_Q, true)
	var before_down := camera.global_position
	await get_tree().create_timer(0.1, true).timeout
	_key(KEY_Q, false)
	_check(camera.global_position.y < before_down.y, "Q moves downward")
	for _index in 80:
		_wheel(MOUSE_BUTTON_WHEEL_UP)
	controller._process(0.01)
	_check(is_equal_approx(camera.fov, 20.0), "scroll zoom stops at 20 degrees")
	for _index in 80:
		_wheel(MOUSE_BUTTON_WHEEL_DOWN)
	controller._process(0.01)
	_check(is_equal_approx(camera.fov, 100.0), "scroll zoom stops at 100 degrees")
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(0.0, 1000000.0)
	motion.screen_relative = motion.relative
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	controller._process(0.01)
	_check(absf(camera.global_rotation.x) >= deg_to_rad(88.0) and absf(camera.global_rotation.x) < deg_to_rad(90.0), "mouse pitch clamps instead of crossing the vertical limit")
	_check(DevMode.reset_camera_pose() and camera.global_transform.is_equal_approx(gameplay_pose) and is_equal_approx(camera.fov, gameplay_fov), "Reset Camera restores gameplay framing")
	await _test_motion(controller)
	_check(_player.global_transform.is_equal_approx(original_transform), "recording leaves the player at their original position")
	var retained_pose := camera.global_transform
	var retained_fov := camera.fov
	_key(KEY_ESCAPE, true)
	_key(KEY_ESCAPE, false)
	await get_tree().process_frame
	_check(not DevMode.camera_active and get_tree().paused and _pause.visible and _pause._dev_panel.visible, "Esc returns to paused developer tab")
	_check(gameplay_camera.current and _player.process_mode == original_process_mode, "Esc restores gameplay camera and player processing")
	_check(CursorState.is_requesting_visible(_pause), "Esc restores pause menu cursor ownership")
	_check((hidden_npc == null or not hidden_npc.visible) and (hidden_item == null or not hidden_item.visible), "exit preserves objects hidden before recording")
	if await _start_camera():
		_check(controller.camera.global_transform.is_equal_approx(retained_pose) and is_equal_approx(controller.camera.fov, retained_fov), "reentry retains framing within the same location")
		DevMode.stop_camera_mode()
	DevMode.stop_camera_mode()
	_check(not DevMode.camera_active, "repeated cleanup is safe")
	for node: Node3D in old_visibility:
		if node != hidden_npc and node != hidden_item:
			_check(node.visible == old_visibility[node], "camera visibility restoration: " + node.name)
	_reset_settings()


func _test_motion(controller: Variant) -> void:
	var camera: Camera3D = controller.camera
	controller.set_process(false)
	DevMode.reset_camera_pose()
	var obstacle := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(10.0, 10.0, 10.0)
	shape.shape = box
	obstacle.add_child(shape)
	_scene.add_child(obstacle)
	obstacle.global_position = camera.global_position
	var origin := camera.global_position
	_key(KEY_W, true)
	for _index in 60:
		controller._process(1.0 / 60.0)
	_key(KEY_W, false)
	var ordinary_distance := camera.global_position.distance_to(origin)
	_check(ordinary_distance > 4.5, "free camera crosses blocking geometry without collision")
	var directions := {KEY_W: Vector3.FORWARD, KEY_S: Vector3.BACK, KEY_A: Vector3.LEFT, KEY_D: Vector3.RIGHT}
	for key: Key in directions:
		DevMode.reset_camera_pose()
		origin = camera.global_position
		var expected: Vector3 = camera.global_basis * directions[key]
		_key(key, true)
		controller._process(0.05)
		_key(key, false)
		_check((camera.global_position - origin).normalized().dot(expected.normalized()) > 0.99, "WASD flight follows camera direction: " + OS.get_keycode_string(key))
	DevMode.reset_camera_pose()
	origin = camera.global_position
	_key(KEY_SHIFT, true)
	_key(KEY_W, true)
	for _index in 60:
		controller._process(1.0 / 60.0)
	_key(KEY_W, false)
	_key(KEY_SHIFT, false)
	_check(absf(camera.global_position.distance_to(origin) - ordinary_distance * 3.0) < 0.02, "Shift triples ordinary flight speed")
	DevMode.reset_camera_pose()
	_key(KEY_ALT, true)
	_key(KEY_C, true, true)
	_key(KEY_C, false, true)
	_key(KEY_ALT, false)
	_check(DevMode.camera_settings().cinematic, "Alt+C enables cinematic movement")
	origin = camera.global_position
	_key(KEY_W, true)
	for _index in 60:
		controller._process(1.0 / 60.0)
	_key(KEY_W, false)
	var cinematic_distance := camera.global_position.distance_to(origin)
	_check(cinematic_distance > 0.1 and cinematic_distance < ordinary_distance * 0.35, "cinematic motion moves at the approved slower speed")
	var first_pose := camera.global_transform
	DevMode.reset_camera_pose()
	_key(KEY_W, true)
	for _index in 144:
		controller._process(1.0 / 144.0)
	_key(KEY_W, false)
	_check(camera.global_position.distance_to(first_pose.origin) < 0.05, "cinematic translation remains stable across frame rates")
	DevMode.set_camera_setting(&"cinematic", false)
	obstacle.queue_free()
	controller.set_process(true)


func _key(code: Key, pressed: bool, alt: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	event.alt_pressed = alt
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _wheel(button: MouseButton) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _animation_positions() -> Dictionary:
	var result := {}
	for node in _nodes(_scene):
		if node is AnimationPlayer and node.is_playing():
			result[node] = [node.current_animation, node.current_animation_position]
	return result


func _animations_unchanged(snapshot: Dictionary) -> bool:
	for player: AnimationPlayer in snapshot:
		if not is_instance_valid(player) or player.current_animation != snapshot[player][0] or not is_equal_approx(player.current_animation_position, snapshot[player][1]):
			return false
	return not snapshot.is_empty()


func _test_cleanup() -> void:
	DevMode.set_camera_setting(&"world_paused", true)
	if await _start_camera():
		var controller: Variant = DevMode._camera_controller
		DevMode.set_enabled(false)
		_check(not DevMode.camera_active and not _pause.visible and not GlobalTimer._pause_owners.has(controller), "developer disable removes camera and its timer pause without reopening menu")
		_check(_player.process_mode != Node.PROCESS_MODE_DISABLED, "developer disable restores player processing")
	DevMode.set_enabled(true)
	DevMode.begin_run()
	if await _start_camera():
		DevMode.end_run()
		_check(not DevMode.camera_active and not _pause.visible, "run end clears recording without reopening menu")
	DevMode.begin_run()
	if await _start_camera():
		SceneManager.transition_generation += 1
		SceneManager.is_travelling = true
		get_tree().paused = false
		await get_tree().process_frame
		await get_tree().process_frame
		_check(not DevMode.camera_active and not get_tree().paused and not _pause.visible, "generation cancellation preserves a transition's live scene state")
		SceneManager.is_travelling = false
	if await _start_camera():
		SceneManager.reset()
		await get_tree().process_frame
		await get_tree().process_frame
		_check(not DevMode.camera_active and not _pause.visible, "manager reset invalidates recording continuations")
	DevMode.begin_run()
	if await _start_camera():
		var controller: Variant = DevMode._camera_controller
		get_tree().current_scene = null
		_scene.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
		_check(not DevMode.camera_active and not GlobalTimer._pause_owners.has(controller), "location removal clears active camera and timer ownership")
		_check(CursorState._visible_owners.is_empty(), "location removal leaves no stale visible cursor requests")
		_scene = null
		_player = null
		_pause = null


func _test_graphics_refresh() -> void:
	var original_quality := VisualSettings.get_quality_preset()
	var original_file := _settings_bytes()
	var original_override: Variant = DevMode._camera_preferences[&"dof_enabled"]
	DevMode._camera_preferences[&"dof_enabled"] = null
	VisualSettings.set_quality_preset(VisualSettings.QUALITY_HIGH)
	if await _start_camera():
		var attributes := DevMode._camera_controller.camera.attributes as CameraAttributesPractical
		_check(attributes != null and attributes.dof_blur_far_enabled, "inherited recording depth of field starts from High quality")
		VisualSettings.set_quality_preset(VisualSettings.QUALITY_PERFORMANCE)
		await get_tree().process_frame
		_check(attributes != null and not attributes.dof_blur_far_enabled, "inherited recording depth of field follows a quality refresh")
		DevMode.set_camera_setting(&"dof_enabled", true)
		VisualSettings.set_quality_preset(VisualSettings.QUALITY_HIGH)
		VisualSettings.set_quality_preset(VisualSettings.QUALITY_PERFORMANCE)
		_check(attributes != null and attributes.dof_blur_far_enabled, "explicit recording depth of field stays enabled across quality refresh")
		DevMode.set_camera_setting(&"dof_enabled", false)
		VisualSettings.set_quality_preset(VisualSettings.QUALITY_HIGH)
		_check(attributes != null and not attributes.dof_blur_far_enabled, "explicit recording depth of field stays disabled across quality refresh")
		DevMode.stop_camera_mode()
	VisualSettings.set_quality_preset(original_quality)
	DevMode._camera_preferences[&"dof_enabled"] = original_override
	DevMode.camera_settings_changed.emit()
	_check(VisualSettings.get_quality_preset() == original_quality and DevMode._camera_preferences[&"dof_enabled"] == original_override, "graphics refresh fixture restores its previous preferences")
	_check(_settings_bytes() == original_file, "graphics refresh fixture restores saved preferences exactly")


func _test_restart_and_title() -> void:
	for restart in [true, false]:
		DevMode.set_camera_setting(&"environment_preset", &"sunrise")
		DevMode.set_camera_setting(&"world_paused", true)
		DevMode.set_camera_setting(&"vhs_enabled", false)
		if not await _start_camera():
			return
		var old_controller: WeakRef = weakref(DevMode._camera_controller)
		var old_scene: WeakRef = weakref(_scene)
		var old_pause_id: int = _pause.get_instance_id()
		# Exercise the production cleanup path even when recording is still active.
		if restart:
			_pause._do_restart()
		else:
			_pause._do_quit()
		var destination := "home" if restart else "main_menu"
		if not await _wait_until(func(): return get_tree().current_scene != null and get_tree().current_scene != old_scene.get_ref() and get_tree().current_scene.scene_file_path == SceneManager.SCENE_PATHS[destination] and TransitionOverlay.overlay.color.a < 0.01, "recording %s reaches its production destination" % ("restart" if restart else "quit"), 12.0):
			return
		_scene = get_tree().current_scene as Node3D if restart else null
		_check(old_scene.get_ref() == null and old_controller.get_ref() == null and not DevMode.camera_active, "restart/title discards old recording nodes")
		_check(not get_tree().paused and not StormAudioController._recording_dry and not VhsCrtOverlay._recording_override, "restart/title clears world freeze and rendering/weather overrides")
		_check(GlobalTimer._pause_owners.is_empty(), "restart/title leaves no recording clock owner")
		_check(not CursorState._visible_owners.has(old_pause_id), "restart/title leaves no stale pause cursor owner")
		for owner_id: int in CursorState._visible_owners:
			var cursor_owner := instance_from_id(owner_id) as Node
			_check(is_instance_valid(cursor_owner) and cursor_owner.is_inside_tree(), "remaining cursor request belongs to a live menu")
		_check(DevMode.run_active == restart and (not restart or DevMode.run_unranked), "restart/title preserves developer run policy")
		if restart:
			_player = _scene.get_node("playerv2") as PlayerV2
			_pause = _player.get_node("PauseMenu") as CanvasLayer
			if not await _wait_until(func(): return not _player._is_input_locked, "restarted player completes startup", 12.0):
				return
		else:
			get_tree().current_scene.queue_free()
			get_tree().current_scene = null
			await get_tree().process_frame
			_player = null
			_pause = null


func _test_teleport_and_storm() -> void:
	if not await _start_camera():
		return
	DevMode._camera_controller.camera.global_position += Vector3(10.0, 10.0, 10.0)
	_key(KEY_ESCAPE, true)
	_key(KEY_ESCAPE, false)
	await get_tree().process_frame
	var old_scene: WeakRef = weakref(_scene)
	_pause._on_dev_teleport_requested("hardware")
	if not await _wait_until(func(): return SceneManager.current_location == "hardware" and not SceneManager.is_travelling and TransitionOverlay.overlay.color.a < 0.01, "pause developer teleport finishes at hardware", 12.0):
		return
	_scene = get_tree().current_scene as Node3D
	_player = _scene.get_node("playerv2") as PlayerV2
	_pause = _player.get_node("PauseMenu") as CanvasLayer
	_check(old_scene.get_ref() == null and not DevMode.camera_active, "teleport discards the old scene's camera")
	var gameplay_pose := get_viewport().get_camera_3d().global_transform
	if await _start_camera():
		_check(DevMode._camera_controller.camera.global_transform.is_equal_approx(gameplay_pose), "destination starts at its own gameplay camera instead of the previous shot")
		DevMode.set_camera_setting(&"world_paused", true)
		GlobalTimer.add_time(GlobalTimer.TOTAL_MINUTES)
		if await _wait_until(func(): return get_tree().current_scene != null and get_tree().current_scene.scene_file_path == SceneManager.SCENE_PATHS["ending"], "forced storm reaches ending during recording", 12.0):
			_check(not DevMode.camera_active and not get_tree().paused and CursorState._visible_owners.is_empty(), "storm cleanup leaves ending live without stale camera or pause menu")
			_scene = get_tree().current_scene as Node3D
			_player = null
			_pause = null


func _test_visuals() -> void:
	get_window().size = Vector2i(1280, 720)
	get_window().content_scale_size = Vector2i(1280, 720)
	for location_id in LOCATIONS:
		if not await _load_location(location_id):
			continue
		GlobalTimer.add_time(300)
		for preset in PRESETS:
			DevMode.set_camera_setting(&"environment_preset", preset)
			DevMode.reset_environment_preset()
			DevMode.set_camera_setting(&"world_paused", true)
			DevMode.set_camera_setting(&"vhs_enabled", false)
			DevMode.set_camera_setting(&"dof_enabled", false)
			if not await _start_camera():
				break
			var camera: Camera3D = DevMode._camera_controller.camera
			if location_id == "grocery":
				camera.global_position = Vector3(-6.0, 4.0, -5.0)
				camera.look_at(Vector3(2.0, 1.0, -12.0))
			elif location_id == "hardware":
				camera.global_position = Vector3(-4.0, 4.0, 2.0)
				camera.look_at(Vector3(-7.0, 1.0, -7.0))
			else:
				var target := _player.global_position + Vector3.UP
				camera.global_position = target + Vector3(4.0, 2.0, 5.0)
				camera.look_at(target)
			DevMode._camera_controller._pitch = camera.global_rotation.x
			DevMode._camera_controller._yaw = camera.global_rotation.y
			await _render_frames(12)
			await _capture("%s_%s" % [location_id, preset])
			DevMode.stop_camera_mode()
	if await _load_location("grocery"):
		await _test_rendered_freeze()
	if await _load_location("home"):
		await _test_panel_visuals()


func _render_frames(count: int) -> void:
	for _index in count:
		await get_tree().process_frame
		await RenderingServer.frame_post_draw


func _capture(label: String) -> Image:
	await _render_frames(2)
	var image := get_viewport().get_texture().get_image()
	var path := "user://recording_camera_%s.png" % label
	_check(not image.is_empty() and image.save_png(path) == OK, "saved recording review image " + label)
	print("RECORDING CAMERA IMAGE ", ProjectSettings.globalize_path(path))
	return image


func _image_difference(first: Image, second: Image) -> float:
	var a := first.duplicate() as Image
	var b := second.duplicate() as Image
	a.resize(96, 54, Image.INTERPOLATE_BILINEAR)
	b.resize(96, 54, Image.INTERPOLATE_BILINEAR)
	var difference := 0.0
	for y in 54:
		for x in 96:
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			difference += (absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b)) / 3.0
	return difference / (96.0 * 54.0)


func _test_rendered_freeze() -> void:
	GlobalTimer.add_time(300)
	DevMode.set_camera_setting(&"vhs_enabled", true)
	DevMode.set_camera_setting(&"hide_indicators", true)
	DevMode.set_camera_setting(&"dof_enabled", false)
	if not await _start_camera():
		return
	var controller: Variant = DevMode._camera_controller
	var camera: Camera3D = controller.camera
	camera.global_position = Vector3(3.0, 3.0, -5.0)
	camera.look_at(Vector3(3.0, 1.0, -13.0))
	controller._pitch = camera.global_rotation.x
	controller._yaw = camera.global_rotation.y
	await _render_frames(24)
	var live_time: float = controller._capture_time
	var live := await _capture("grocery_live_a")
	await get_tree().create_timer(0.35, true).timeout
	var live_later := await _capture("grocery_live_b")
	_check(controller._capture_time > live_time, "rendered live mode advances the VHS effect clock")
	_check(_image_difference(live, live_later) > 0.00001, "rendered rain, animals, and VHS continue moving in live mode")
	_key(KEY_P, true)
	_key(KEY_P, false)
	await _render_frames(32)
	var animations := _animation_positions()
	var animal_positions := {}
	for node in _nodes(_scene):
		if node is AmbientAnimal:
			animal_positions[node] = node.global_transform
	var frozen_time: float = controller._capture_time
	var frozen := await _capture("grocery_frozen_a")
	await get_tree().create_timer(0.35, true).timeout
	var frozen_later := await _capture("grocery_frozen_b")
	var difference := _image_difference(frozen, frozen_later)
	print("RECORDING CAMERA FROZEN FRAME DIFFERENCE ", difference)
	_check(difference < 0.01, "frozen rendered view stays stable within temporal-rendering tolerance")
	_check(_animations_unchanged(animations) and controller._capture_time == frozen_time, "rendered freeze holds animations and VHS time")
	_check(VhsCrtOverlay._material.get_shader_parameter("use_capture_time") == true and is_equal_approx(float(VhsCrtOverlay._material.get_shader_parameter("capture_time")), frozen_time), "active VHS shader receives the frozen recording time")
	for animal: AmbientAnimal in animal_positions:
		_check(animal.global_transform.is_equal_approx(animal_positions[animal]), "rendered freeze holds actual animal movement")
	for node in _nodes(_scene):
		if node is GPUParticles3D and node.has_method("set_recording_dry"):
			_check(node.visible and node.emitting and not node.can_process(), "authored rain remains present while its movement is paused")
	DevMode.stop_camera_mode()
	_check(VhsCrtOverlay._material.get_shader_parameter("use_capture_time") == false, "exit clears VHS recording time override")


func _test_panel_visuals() -> void:
	var original_scale := VisualSettings.get_ui_scale_percent()
	var original_language := LocalizationManager.get_language()
	VisualSettings.set_ui_scale_percent(175)
	for language in ["english", "tagalog"]:
		LocalizationManager.set_language(language)
		await _open_dev_tab()
		await _render_frames(4)
		var panel: DevModePanel = _pause._dev_panel
		_check(get_viewport().get_visible_rect().encloses(panel.get_card_rect()), "175 percent developer card fits on screen in " + language)
		var scroll: ScrollContainer
		for node in _nodes(panel):
			if node is ScrollContainer:
				scroll = node
				break
		_check(scroll != null, "recording settings provide vertical scrolling")
		if scroll == null:
			continue
		var anchors := {"camera": "recording camera", "visibility": "hide player",
			"environment": "recording environment", "effects": "vhs / crt"}
		for section: String in anchors:
			var title: Control
			for node in _nodes(panel):
				if (node is Label or node is CheckBox) and anchors[section] in str(node.get_meta("_localization_source_text", node.text)).to_lower():
					title = node
					break
			_check(title != null, section + " heading exists in the developer panel")
			if title != null:
				scroll.ensure_control_visible(title)
				await _render_frames(2)
				scroll.scroll_vertical += roundi(title.global_position.y - scroll.global_position.y)
				await _render_frames(4)
				await _capture("panel_%s_%s_175" % [section, language])
		_check(not scroll.get_h_scroll_bar().visible, "175 percent camera settings do not require horizontal scrolling")
		_check(get_viewport().get_visible_rect().encloses(_pause._dev_nav.get_global_rect()), "developer tab remains reachable at 175 percent")
	VisualSettings.set_ui_scale_percent(original_scale)
	LocalizationManager.set_language(original_language)
