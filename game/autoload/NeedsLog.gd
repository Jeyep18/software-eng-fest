# NeedsLog.gd
extends Node

#region Need Definitions
# All discoverable needs in Act 1. Populated during house exploration.
# Other systems (NPC dialogue, InnerMonologue, Act1Sequence) gate on these.

enum Need {
	ROOF,       # Ceiling hole in living room — requires tarp
	MEDICINE,   # Lola's bottle nearly empty — requires medicine
	FOOD,       # Fridge empty — requires canned goods
	WINDOWS,    # Second-floor windows weak — requires plywood
	WATER,      # No filled containers — requires water jugs
	FLASHLIGHT, # Dead flashlight in bodega — requires batteries
}

# Human-readable labels — used by any debug UI or future hint system
const NEED_LABELS: Dictionary = {
	Need.ROOF:       "Bubong — leaking roof",
	Need.MEDICINE:   "Gamot ni Lola — medicine needed",
	Need.FOOD:       "Pagkain — fridge is empty",
	Need.WINDOWS:    "Bintana — weak second-floor windows",
	Need.WATER:      "Tubig — no filled water containers",
	Need.FLASHLIGHT: "Flashlight — dead batteries",
}
#endregion

#region Internal State
# Tracks which needs have been discovered and which have been resolved.

var _discovered: Dictionary = {}  # Need (int) -> true
var _resolved: Dictionary = {}    # Need (int) -> true
var _boarded_windows: Dictionary = {} # window_id (String) -> true
#endregion

#region Signals
signal need_discovered(need: Need)
signal need_resolved(need: Need)
signal window_boarded(window_id: String, boarded_count: int)
#endregion

#region Public API — Discovery

func discover(need: Need) -> void:
	if _discovered.has(need):
		return
	_discovered[need] = true
	need_discovered.emit(need)
	if _discovered.size() >= Need.size():
		GameState.complete_house_exploration()

func is_discovered(need: Need) -> bool:
	return _discovered.has(need)

func get_all_discovered() -> Array:
	return _discovered.keys()
#endregion

#region Public API — Resolution
# Called by InventoryManager or task completion logic when a need is met.
# A need can only be resolved if it was first discovered.

func resolve(need: Need) -> void:
	# Auto-discover if not yet discovered —
	# TaskObject may complete before player manually explores
	if not _discovered.has(need):
		discover(need)
	if _resolved.has(need):
		return
	_resolved[need] = true
	print("NeedsLog: emitting need_resolved for: ", NEED_LABELS.get(need))
	need_resolved.emit(need)

func is_resolved(need: Need) -> bool:
	return _resolved.has(need)

func get_all_resolved() -> Array:
	return _resolved.keys()
#endregion

#region Public API - Window Progress
func board_window(window_id: String) -> void:
	if window_id.strip_edges().is_empty():
		push_warning("NeedsLog: board_window called with an empty window_id.")
		return
	if _boarded_windows.has(window_id):
		return

	_boarded_windows[window_id] = true
	window_boarded.emit(window_id, _boarded_windows.size())

	if _boarded_windows.size() >= 2:
		resolve(Need.WINDOWS)

func is_window_boarded(window_id: String) -> bool:
	return _boarded_windows.has(window_id)

func boarded_window_count() -> int:
	return _boarded_windows.size()
#endregion

#region Public API — Queries

func get_unresolved_discovered() -> Array:
	# Returns all needs the player found but hasn't addressed yet.
	# Useful for NPC hint dialogue and Lola's departure hints.
	var result: Array = []
	for need in _discovered.keys():
		if not _resolved.has(need):
			result.append(need)
	return result

func discovery_count() -> int:
	return _discovered.size()

func all_critical_discovered() -> bool:
	# ROOF and MEDICINE are the two critical needs.
	# Act1Sequence can gate departure on this if desired.
	return is_discovered(Need.ROOF) and is_discovered(Need.MEDICINE)
#endregion

#region Reset
func reset() -> void:
	_discovered.clear()
	_resolved.clear()
	_boarded_windows.clear()
#endregion

func debug_print_status() -> void:
	print("=== NeedsLog Status ===")
	if _discovered.is_empty():
		print("  No needs discovered yet.")
		return
	for need in Need.values():
		if not _discovered.has(need):
			continue
		var label: String = NEED_LABELS.get(need, str(need))
		if _resolved.has(need):
			print("  [RESOLVED]   ", label)
		else:
			print("  [UNRESOLVED] ", label)
	print("=======================")
