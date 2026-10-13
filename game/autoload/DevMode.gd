extends Node

signal unlocked_changed
signal enabled_changed(is_enabled: bool)
signal clock_pause_changed(is_paused: bool)
signal camera_mode_changed(is_active: bool)
signal camera_settings_changed

const MAX_CASH_CHANGE: int = 10000
const TELEPORT_LOCATIONS: Dictionary = {
	"home": "Home",
	"ate_linda": "Ate Linda's",
	"hardware": "Hardware Store",
	"pharmacy": "Pharmacy",
	"grocery": "Grocery / Palengke",
	"bodega": "Bodega",
}
const CAMERA_ENVIRONMENTS: Dictionary = {
	&"storm": "Default Stormy", &"sunrise": "Sunrise Morning",
	&"sunny": "Clear Sunny", &"sunset": "Sunset",
}
const CAMERA_LOCATIONS: Dictionary = {&"current": "Current location", &"house_teaser": "House teaser"}
const CAMERA_HOUSE_STATES: Dictionary = {&"normal": "Normal", &"wrecked": "Wrecked"}
const CAMERA_SETTING_RANGES: Dictionary = {
	&"speed": Vector2(0.5, 20.0), &"sensitivity": Vector2(0.02, 0.5),
	&"brightness": Vector2(0.25, 2.0), &"sun_strength": Vector2(0.0, 2.0),
	&"fog_amount": Vector2(0.0, 2.0), &"sky_rotation": Vector2(-180.0, 180.0),
}
const ENVIRONMENT_TUNING_DEFAULTS: Dictionary = {
	&"brightness": 1.0, &"sun_strength": 1.0, &"fog_amount": 1.0, &"sky_rotation": 0.0,
}

var unlocked: bool = false
var enabled: bool = false
var run_unranked: bool = false
var run_active: bool = false
var clock_paused: bool = false
var camera_active: bool:
	get:
		return is_instance_valid(_camera_controller) and _camera_controller.active
var _camera_controller: DevCameraController
var _camera_preferences: Dictionary = {
	&"speed": 5.0, &"sensitivity": 0.1, &"cinematic": false, &"world_paused": false,
	&"hide_player": true, &"hide_npcs": false, &"hide_animals": false,
	&"hide_items": false, &"hide_indicators": true, &"environment_preset": &"storm",
	&"vhs_enabled": null, &"dof_enabled": null,
	&"recording_location": &"current", &"house_state": &"normal",
}
var _environment_tuning: Dictionary = {}


func is_available() -> bool:
	return OS.is_debug_build() and (OS.has_feature("editor_runtime") or OS.has_feature("bagyong_dev_tools"))


func unlock() -> bool:
	if not is_available():
		return false
	if not unlocked:
		unlocked = true
		unlocked_changed.emit()
	return true


func set_enabled(value: bool) -> bool:
	if not is_available() or not unlocked:
		return false
	if enabled == value:
		return true
	enabled = value
	if enabled and run_active:
		run_unranked = true
	if not enabled:
		stop_camera_mode(false)
		_release_clock_pause()
	enabled_changed.emit(enabled)
	return true


func begin_run() -> void:
	stop_camera_mode(false)
	_release_clock_pause()
	run_active = true
	run_unranked = is_available() and enabled


func end_run() -> void:
	stop_camera_mode(false)
	_release_clock_pause()
	run_active = false
	run_unranked = false


func can_use() -> bool:
	return is_available() and unlocked and enabled and run_active \
		and not SceneManager.is_travelling and not SceneManager.storm_transition_pending \
		and GlobalTimer.current_minutes < GlobalTimer.TOTAL_MINUTES


func is_valid_destination(location_id: String) -> bool:
	return TELEPORT_LOCATIONS.has(location_id)


func add_money(amount: int) -> bool:
	if not can_use() or amount < 1 or amount > MAX_CASH_CHANGE:
		return false
	GameState.add_cash(amount)
	return true


func remove_money(amount: int) -> bool:
	if not can_use() or amount < 1 or amount > MAX_CASH_CHANGE:
		return false
	var removed: int = mini(amount, GameState.get_cash())
	if removed > 0:
		GameState.spend_cash(removed)
	return true


func set_clock_paused(value: bool) -> bool:
	if not can_use():
		return false
	if clock_paused == value:
		return true
	if value:
		GlobalTimer.pause_timer(self)
		clock_paused = true
	else:
		_release_clock_pause()
	clock_pause_changed.emit(clock_paused)
	return true


func reset_clock() -> bool:
	if not can_use():
		return false
	SceneManager.danger_zones.clear()
	SceneManager.closed_zones.clear()
	StormEnroachment.reset()
	return GlobalTimer.reset_elapsed_for_dev()


func teleport_to(location_id: String) -> bool:
	if not can_use() or not is_valid_destination(location_id):
		return false
	stop_camera_mode(false)
	var spawn_id := "from_house" if location_id == "bodega" else ""
	SceneManager.travel_to(location_id, spawn_id, 0, true)
	return true


func camera_settings() -> Dictionary:
	var settings := _camera_preferences.duplicate()
	if settings[&"vhs_enabled"] == null:
		settings[&"vhs_enabled"] = VisualSettings.is_vhs_crt_enabled()
	if settings[&"dof_enabled"] == null:
		settings[&"dof_enabled"] = VisualSettings.should_use_camera_depth_of_field()
	settings.merge(_environment_tuning.get(settings[&"environment_preset"], ENVIRONMENT_TUNING_DEFAULTS), true)
	return settings


func set_camera_setting(key: StringName, value: Variant) -> bool:
	if not can_use():
		return false
	if key in [&"environment_preset", &"recording_location", &"house_state"]:
		if typeof(value) != TYPE_STRING and typeof(value) != TYPE_STRING_NAME:
			return false
		value = StringName(value)
		var choices: Dictionary = CAMERA_ENVIRONMENTS if key == &"environment_preset" else (CAMERA_LOCATIONS if key == &"recording_location" else CAMERA_HOUSE_STATES)
		if not choices.has(value):
			return false
	elif CAMERA_SETTING_RANGES.has(key):
		if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
			return false
		value = float(value)
		var bounds: Vector2 = CAMERA_SETTING_RANGES[key]
		if not is_finite(value) or value < bounds.x or value > bounds.y:
			return false
	elif not _camera_preferences.has(key) or typeof(value) != TYPE_BOOL:
		return false
	if ENVIRONMENT_TUNING_DEFAULTS.has(key):
		var preset: StringName = _camera_preferences[&"environment_preset"]
		if not _environment_tuning.has(preset):
			_environment_tuning[preset] = ENVIRONMENT_TUNING_DEFAULTS.duplicate()
		_environment_tuning[preset][key] = value
	else:
		_camera_preferences[key] = value
	if camera_active:
		_camera_controller.apply_settings(camera_settings())
	camera_settings_changed.emit()
	return true


func reset_environment_preset() -> bool:
	if not can_use():
		return false
	_environment_tuning.erase(_camera_preferences[&"environment_preset"])
	if camera_active:
		_camera_controller.apply_settings(camera_settings())
	camera_settings_changed.emit()
	return true


func reset_camera_pose() -> bool:
	if not can_use():
		return false
	if is_instance_valid(_camera_controller):
		_camera_controller.reset_pose()
	return true


func camera_has_active_sun() -> bool:
	if camera_settings()[&"recording_location"] == &"house_teaser":
		return true
	var sun := DevCameraEnvironment.find_sun(get_tree().current_scene)
	return is_instance_valid(sun) and sun.is_visible_in_tree()


func start_camera_mode(player: PlayerV2, pause_menu: CanvasLayer) -> bool:
	if not can_use() or camera_active or not is_instance_valid(player) or not is_instance_valid(pause_menu):
		return false
	var scene := get_tree().current_scene
	if scene == null or not scene.is_ancestor_of(player) or not player.is_ancestor_of(pause_menu):
		return false
	if not pause_menu.visible or not pause_menu.has_method("begin_camera_capture") or pause_menu.get("_transitioning"):
		return false
	if player._is_input_locked or player._is_movement_locked or ShopUi.is_open():
		return false
	if TransitionOverlay.overlay.color.a >= 0.05 or (TransitionOverlay.tween != null and TransitionOverlay.tween.is_running()):
		return false
	for tutorial in get_tree().get_nodes_in_group("tutorial_modal"):
		if tutorial is TutorialModal and tutorial.visible:
			return false
	if get_tree().get_first_node_in_group("lotto_ui") != null or _camera_entry_blocked(scene):
		return false
	if not is_instance_valid(_camera_controller) or _camera_controller.get_parent() != scene:
		_camera_controller = DevCameraController.new()
		scene.add_child(_camera_controller)
	return _camera_controller.begin(player, pause_menu, camera_settings())


func stop_camera_mode(return_to_pause: bool = true) -> void:
	# Cleanup remains available after authorization or scene state changes.
	if is_instance_valid(_camera_controller):
		_camera_controller.stop(return_to_pause)


func _camera_entry_blocked(node: Node) -> bool:
	if node is Interactable and node.is_showing:
		return true
	if node is TaskObject and node._is_completing:
		return true
	for child in node.get_children():
		if _camera_entry_blocked(child):
			return true
	return false


func _release_clock_pause() -> void:
	if not clock_paused:
		return
	clock_paused = false
	GlobalTimer.resume_timer(self)
	clock_pause_changed.emit(false)
