extends Node

signal unlocked_changed
signal enabled_changed(is_enabled: bool)
signal clock_pause_changed(is_paused: bool)

const MAX_CASH_CHANGE: int = 10000
const TELEPORT_LOCATIONS: Dictionary = {
	"home": "Home",
	"ate_linda": "Ate Linda's",
	"hardware": "Hardware Store",
	"pharmacy": "Pharmacy",
	"grocery": "Grocery / Palengke",
	"bodega": "Bodega",
}

var unlocked: bool = false
var enabled: bool = false
var run_unranked: bool = false
var run_active: bool = false
var clock_paused: bool = false


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
		_release_clock_pause()
	enabled_changed.emit(enabled)
	return true


func begin_run() -> void:
	_release_clock_pause()
	run_active = true
	run_unranked = is_available() and enabled


func end_run() -> void:
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
	var spawn_id := "from_house" if location_id == "bodega" else ""
	SceneManager.travel_to(location_id, spawn_id, 0, true)
	return true


func _release_clock_pause() -> void:
	if not clock_paused:
		return
	clock_paused = false
	GlobalTimer.resume_timer(self)
	clock_pause_changed.emit(false)
