# GlobalTimer.gd — Autoload Singleton
# Central 12-hour clock. Difficulty controls seconds per game minute.
# New runs call start_fresh() on entering home; map/backpack and fades do not
# pause the clock themselves. Dialogue, shops and tasks acquire timer pauses;
# PauseMenu separately pauses the SceneTree. Burst costs apply even when paused.
# Pair pause_timer(self) with resume_timer(self); scene exit also releases it.

extends Node

# ── Signals ───────────────────────────────────────────────────────────────────
signal time_updated(current_minute: int)
signal encroachment_threshold_reached(zone_id: String)
signal storm_arrived

# ── Constants ─────────────────────────────────────────────────────────────────
const TOTAL_MINUTES: int = 720  # 12 hours

# Encroachment thresholds in minutes.
# Stored as Dictionaries so "fired" can be mutated at runtime.
# IMPORTANT: do NOT use const for arrays/dicts with mutable inner values.
var THRESHOLDS: Array = [
	{ "minute": 240, "zone_id": "outer_danger",  "fired": false },  # 4h
	{ "minute": 360, "zone_id": "outer_closed",  "fired": false },  # 6h
	{ "minute": 540, "zone_id": "inner_danger",  "fired": false },  # 9h
	{ "minute": 720, "zone_id": "storm_arrival", "fired": false },  # 12h
]

# ── Tick Configuration ────────────────────────────────────────────────────────
# Standard defaults to 1.5 real seconds per game minute; GameState sets difficulty.
# Lower = faster clock. Raise for slower pacing in playtesting.
var seconds_per_game_minute: float = 1.5

# ── State ─────────────────────────────────────────────────────────────────────
var current_minutes: int  = 0
var is_paused:       bool = true   # starts paused until a run starts

# Accumulates fractional seconds between whole-minute ticks.
var _tick_accumulator: float = 0.0

# Tracks how many UI layers have requested a pause.
# This prevents a resume() from one system unpausing a clock that another
# system with an outstanding pause still wants paused.
# Only release pauses acquired by the corresponding flow.
var _pause_stack: int = 0
var _pause_owners: Dictionary = {}

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	# Hard guards — never tick if paused or storm has already arrived.
	if is_paused or current_minutes >= TOTAL_MINUTES:
		return

	_tick_accumulator += delta

	# Convert accumulated real seconds to whole game minutes.
	while _tick_accumulator >= seconds_per_game_minute:
		_tick_accumulator -= seconds_per_game_minute
		_advance_one_minute()

# ── Public API ────────────────────────────────────────────────────────────────

## One pause per supplied owner; anonymous calls retain the legacy counter API.
## Release explicitly when closing UI. Scene exit releases owned pauses too.
func pause_timer(pause_owner: Node = null) -> void:
	# Scene-owned pauses are idempotent and cannot survive their owner or a reset.
	if pause_owner != null:
		if _pause_owners.has(pause_owner):
			return
		_pause_owners[pause_owner] = true
		pause_owner.tree_exiting.connect(resume_timer.bind(pause_owner), CONNECT_ONE_SHOT)
	_pause_stack += 1
	is_paused = true

## Resume the clock. Only actually unpauses when all pausers have resumed.
func resume_timer(pause_owner: Node = null) -> void:
	if pause_owner != null:
		if not _pause_owners.erase(pause_owner):
			return
		var release := resume_timer.bind(pause_owner)
		if pause_owner.tree_exiting.is_connected(release):
			pause_owner.tree_exiting.disconnect(release)
	_pause_stack = max(_pause_stack - 1, 0)
	if _pause_stack == 0 and current_minutes < TOTAL_MINUTES:
		is_paused = false
		_tick_accumulator = 0.0  # reset so we don't rush-tick after a UI close

## Add minutes instantly (travel burst, task completion, NPC trade).
## Works regardless of pause state — burst costs are always applied.
func add_time(minutes: int) -> void:
	if minutes <= 0:
		return
	var previous: int = current_minutes
	current_minutes = min(current_minutes + minutes, TOTAL_MINUTES)
	for m in range(previous + 1, current_minutes + 1):
		emit_signal("time_updated", m)
		_check_thresholds(m)

## Rewind only for an authorized Dev Mode run. Keep existing pause owners intact.
func reset_elapsed_for_dev() -> bool:
	if not DevMode.can_use():
		return false
	current_minutes = 0
	_tick_accumulator = 0.0
	for threshold in THRESHOLDS:
		threshold["fired"] = false
	time_updated.emit(0)
	return true

# ── HUD Helpers ───────────────────────────────────────────────────────────────

## Returns current in-game time as a 12-hour string, e.g. "10:42 AM".
## Game starts at 6:00 AM — current_minutes=0 → "6:00 AM".
func get_time_string() -> String:
	var total:   int = current_minutes + 360   # 360 min = 6:00 AM offset
	# Whole hours; the remaining minutes are formatted separately.
	@warning_ignore("integer_division")
	var hour_24: int = (total / 60) % 24
	var minute:  int = total % 60
	var hour_12: int = hour_24 % 12
	if hour_12 == 0:
		hour_12 = 12
	var period: String = "AM" if hour_24 < 12 else "PM"
	return "%d:%02d %s" % [hour_12, minute, period]

## Returns remaining time as "Xh Xm", e.g. "Storm ETA: 7h 23m".
func get_storm_eta_string() -> String:
	var remaining: int = TOTAL_MINUTES - current_minutes
	if remaining <= 0:
		return "Storm has arrived"
	# Whole hours; the remaining minutes are formatted separately.
	@warning_ignore("integer_division")
	var hours: int = remaining / 60
	var mins:  int = remaining % 60
	return "%dh %02dm" % [hours, mins]

## Returns 0.0–1.0 — used by music crossfade and storm visual darkening.
func get_storm_progress() -> float:
	return float(current_minutes) / float(TOTAL_MINUTES)

# ── Reset ─────────────────────────────────────────────────────────────────────
func reset() -> void:
	for pause_owner: Node in _pause_owners:
		pause_owner.tree_exiting.disconnect(resume_timer.bind(pause_owner))
	_pause_owners.clear()
	current_minutes    = 0
	is_paused          = true
	_tick_accumulator  = 0.0
	_pause_stack       = 0
	apply_difficulty_settings()
	for threshold in THRESHOLDS:
		threshold["fired"] = false

func start_fresh() -> void:
	reset()
	resume_timer()

func apply_difficulty_settings() -> void:
	if get_node_or_null("/root/GameState") != null:
		seconds_per_game_minute = GameState.get_seconds_per_game_minute()
	else:
		seconds_per_game_minute = 1.5
# ── Internal ──────────────────────────────────────────────────────────────────
func _advance_one_minute() -> void:
	if current_minutes >= TOTAL_MINUTES:
		return
	current_minutes += 1
	emit_signal("time_updated", current_minutes)
	_check_thresholds(current_minutes)

func _check_thresholds(minute: int) -> void:
	for threshold in THRESHOLDS:
		if not threshold["fired"] and minute >= threshold["minute"]:
			threshold["fired"] = true
			if threshold["zone_id"] == "storm_arrival":
				# Freeze everything — storm has arrived.
				is_paused    = true
				emit_signal("storm_arrived")
			else:
				emit_signal("encroachment_threshold_reached", threshold["zone_id"])

func force_storm_arrival() -> void:
	var previous: int = current_minutes
	current_minutes = TOTAL_MINUTES
	# Fire any thresholds that were skipped.
	for m in range(previous + 1, TOTAL_MINUTES + 1):
		_check_thresholds(m)
