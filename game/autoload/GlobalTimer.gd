# GlobalTimer.gd — Autoload Singleton
# The central 12-hour in-game clock for Bagyong Bahay.
#
# TICK SYSTEM (Option A):
#   - 1 real second = 1 game minute, always.
#   - Time ticks automatically via _process(delta).
#   - is_paused = true ONLY during: UI screens (map, inventory, shop, dialogue),
#     the TransitionOverlay fade, and Act 1 (before departure).
#   - Time runs freely while the player walks, examines, or stands in any location.
#   - Travel and task completions still call add_time() for their burst cost —
#     those minutes are added instantly on top of the passive tick.
#
# HOW TO PAUSE THE CLOCK:
#   GlobalTimer.pause_timer()   — call when opening any UI or starting a fade
#   GlobalTimer.resume_timer()  — call when closing UI or fade completes
#
# ANYTHING that calls pause_timer() must call resume_timer() when done,
# or the clock will stay frozen. Use a try/finally pattern if needed.

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
# 1.0 = 1 real second per game minute (festival default).
# Lower = faster clock. Raise for slower pacing in playtesting.
const SECONDS_PER_GAME_MINUTE: float = 1.0

# ── State ─────────────────────────────────────────────────────────────────────
var current_minutes: int  = 0
var is_paused:       bool = true   # starts paused — resumed on Act 2 departure

# Accumulates fractional seconds between whole-minute ticks.
var _tick_accumulator: float = 0.0

# Tracks how many UI layers have requested a pause.
# This prevents a resume() from one system unpausing a clock that another
# system (e.g. map open while shop also open) still wants paused.
# Call pause_timer() when opening any UI, resume_timer() when closing it.
var _pause_stack: int = 0

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	# Hard guards — never tick if paused or storm has already arrived.
	if is_paused or current_minutes >= TOTAL_MINUTES:
		return

	_tick_accumulator += delta

	# Convert accumulated real seconds to whole game minutes.
	while _tick_accumulator >= SECONDS_PER_GAME_MINUTE:
		_tick_accumulator -= SECONDS_PER_GAME_MINUTE
		_advance_one_minute()

# ── Public API ────────────────────────────────────────────────────────────────

## Pause the clock. Safe to call multiple times (uses a stack).
## Always pair with resume_timer().
func pause_timer() -> void:
	_pause_stack += 1
	is_paused = true

## Resume the clock. Only actually unpauses when all pausers have resumed.
func resume_timer() -> void:
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
	current_minutes = mini(current_minutes + minutes, TOTAL_MINUTES)
	for m in range(previous + 1, current_minutes + 1):
		emit_signal("time_updated", m)
		_check_thresholds(m)

# ── HUD Helpers ───────────────────────────────────────────────────────────────

## Returns current in-game time as a 12-hour string, e.g. "10:42 AM".
## Game starts at 6:00 AM — current_minutes=0 → "6:00 AM".
func get_time_string() -> String:
	var total:   int = current_minutes + 360   # 360 min = 6:00 AM offset
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
	var hours: int = remaining / 60
	var mins:  int = remaining % 60
	return "%dh %02dm" % [hours, mins]

## Returns 0.0–1.0 — used by music crossfade and storm visual darkening.
func get_storm_progress() -> float:
	return float(current_minutes) / float(TOTAL_MINUTES)

# ── Reset ─────────────────────────────────────────────────────────────────────
func reset() -> void:
	current_minutes    = 0
	is_paused          = true
	_tick_accumulator  = 0.0
	_pause_stack       = 0
	for threshold in THRESHOLDS:
		threshold["fired"] = false

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
				_pause_stack = 0
				is_paused    = true
				emit_signal("storm_arrived")
			else:
				emit_signal("encroachment_threshold_reached", threshold["zone_id"])
