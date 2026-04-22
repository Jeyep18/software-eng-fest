
# GlobalTimer.gd — Autoload Singleton
# The central 12-hour in-game clock for Bagyong Bahay.
# Time only advances during travel, searches, repairs, and NPC interactions.
# Time is STATIC when the player is stationary inside a location.

extends Node

# ── Signals ──────────────────────────────────────────────────────────────────
signal time_updated(current_minute: int)
signal encroachment_threshold_reached(zone_id: String)
signal storm_arrived

# ── Constants ────────────────────────────────────────────────────────────────
const TOTAL_MINUTES: int = 720  # 12 hours

# Encroachment thresholds in minutes
# Each entry: { "minute": int, "zone_id": String, "fired": bool }
var THRESHOLDS: Array = [
	{ "minute": 240, "zone_id": "outer_danger",  "fired": false },
	{ "minute": 360, "zone_id": "outer_closed",  "fired": false },
	{ "minute": 540, "zone_id": "inner_danger",  "fired": false },
	{ "minute": 720, "zone_id": "storm_arrival", "fired": false },
]

# ── State ─────────────────────────────────────────────────────────────────────
var current_minutes: int = 0
var is_paused: bool = true  # starts paused — clock runs only after breakfast ends


# ── Public API ────────────────────────────────────────────────────────────────

func pause_timer() -> void:
	is_paused = true


func resume_timer() -> void:
	if current_minutes >= TOTAL_MINUTES:
		return  # don't resume if storm already arrived
	is_paused = false

func add_time(minutes: int) -> void:
	if is_paused:
		push_warning("GlobalTimer: add_time() called while paused. Did you forget to resume_timer()?")
	
	var previous: int = current_minutes
	current_minutes = mini(current_minutes + minutes, TOTAL_MINUTES)

	# Fire time_updated once per in-game minute added
	for m in range(previous + 1, current_minutes + 1):
		emit_signal("time_updated", m)
		_check_thresholds(m)


# ── HUD Helpers ───────────────────────────────────────────────────────────────

# Returns current time as a 12-hour formatted string e.g. "10:42 AM"
func get_time_string() -> String:
	# Game starts at 6:00 AM
	var total: int = current_minutes + 360  # 360 = 6 hours offset
	var hour_24: int = (total / 60) % 24
	var minute: int = total % 60
	var hour_12: int = hour_24 % 12
	if hour_12 == 0:
		hour_12 = 12
	var period: String = "AM" if hour_24 < 12 else "PM"
	return "%d:%02d %s" % [hour_12, minute, period]


# Returns remaining time as "Xh Xm" string e.g. "Storm ETA: 7h 23m"
func get_storm_eta_string() -> String:
	var remaining: int = TOTAL_MINUTES - current_minutes
	if remaining <= 0:
		return "Storm has arrived"
	var hours: int = remaining / 60
	var mins: int = remaining % 60
	return "%dh %02dm" % [hours, mins]


# Returns 0.0 to 1.0 — useful for music bus crossfade and visual storm darkening
func get_storm_progress() -> float:
	return float(current_minutes) / float(TOTAL_MINUTES)


# ── Internal ──────────────────────────────────────────────────────────────────

func _check_thresholds(minute: int) -> void:
	for threshold in THRESHOLDS:
		if not threshold["fired"] and minute >= threshold["minute"]:
			threshold["fired"] = true
			if threshold["zone_id"] == "storm_arrival":
				is_paused = true  # freeze the clock
				emit_signal("storm_arrived")
			else:
				emit_signal("encroachment_threshold_reached", threshold["zone_id"])

# Add to GlobalTimer.gd
func reset() -> void:
	current_minutes = 0
	is_paused = true
	for threshold in THRESHOLDS:
		threshold["fired"] = false
