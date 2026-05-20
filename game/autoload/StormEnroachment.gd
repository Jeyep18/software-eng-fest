# StormEncroachment.gd — Autoload Singleton
# Listens to GlobalTimer encroachment signals and closes locations progressively.
# SceneManager checks can_travel_to() before executing any travel.

extends Node

# ── Location IDs must match SceneManager's location keys exactly ─────────────
# Beta scope: Mang Romy and Barangay Hall are CUT — not listed here.
const ENCROACHMENT_MAP: Dictionary = {
	"outer_danger": {
		"danger":      ["grocery"],
		"inaccessible": []
	},
	"outer_closed": {
		"danger":      ["barangay_hall"],   # kept in map data, just inaccessible in beta
		"inaccessible": ["grocery"]
	},
	"inner_danger": {
		"danger":      ["hardware", "pharmacy"],
		"inaccessible": ["grocery"]         # already closed, stays closed
	},
}

# ── State ─────────────────────────────────────────────────────────────────────
# location_id → "open" | "danger" | "inaccessible"
var _location_states: Dictionary = {
	"home":           "open",
	"ate_linda":      "open",
	"grocery":        "open",
	"pharmacy":       "open",
	"hardware":       "open",
}

# Time penalty applied when entering a danger zone (minutes)
const DANGER_TIME_PENALTY: int = 15

# ── Signals ───────────────────────────────────────────────────────────────────
signal location_state_changed(location_id: String, new_state: String)

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	if not GlobalTimer.encroachment_threshold_reached.is_connected(_on_threshold_reached):
		GlobalTimer.encroachment_threshold_reached.connect(_on_threshold_reached)

# ── Signal Handler ────────────────────────────────────────────────────────────
func _on_threshold_reached(zone_id: String) -> void:
	if not ENCROACHMENT_MAP.has(zone_id):
		return

	var zone: Dictionary = ENCROACHMENT_MAP[zone_id]

	for loc_id in zone["danger"]:
		_set_state(loc_id, "danger")

	for loc_id in zone["inaccessible"]:
		_set_state(loc_id, "inaccessible")

func _set_state(location_id: String, new_state: String) -> void:
	if not _location_states.has(location_id):
		return
	if _location_states[location_id] == new_state:
		return
	_location_states[location_id] = new_state
	location_state_changed.emit(location_id, new_state)

# ── Public API ────────────────────────────────────────────────────────────────

# SceneManager calls this before travel. Returns false if inaccessible.
func can_travel_to(location_id: String) -> bool:
	var state: String = get_state(location_id)
	return state != "inaccessible"

# Returns "open" | "danger" | "inaccessible"
func get_state(location_id: String) -> String:
	return _location_states.get(location_id, "open")

# Call this after confirming travel to a danger zone — adds time penalty.
func apply_danger_penalty(location_id: String) -> void:
	if get_state(location_id) == "danger":
		GlobalTimer.add_time(DANGER_TIME_PENALTY)
		push_warning("StormEncroachment: Danger zone penalty applied for '%s' (+%d min)." 
				% [location_id, DANGER_TIME_PENALTY])

func reset() -> void:
	var default_states: Dictionary = {
		"home":           "open",
		"ate_linda":      "open",
		"grocery":        "open",
		"pharmacy":       "open",
		"hardware":       "open",
	}
	for location_id in default_states.keys():
		if _location_states.get(location_id, "open") != default_states[location_id]:
			location_state_changed.emit(location_id, default_states[location_id])
	_location_states = default_states
