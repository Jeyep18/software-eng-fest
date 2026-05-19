extends Node

signal entries_changed

const SAVE_PATH: String = "user://leaderboard_scores.json"
const MAX_ENTRIES: int = 25

var _entries: Array[Dictionary] = []
var _pending_remaining_minutes: int = -1

func _ready() -> void:
	_load_entries()

func record_run(player_name: String, tasks_completed: int, remaining_minutes: int) -> void:
	var clean_name: String = player_name.strip_edges()
	if clean_name.is_empty():
		clean_name = "Player"

	_entries.append({
		"player_name": clean_name,
		"tasks_completed": max(tasks_completed, 0),
		"remaining_minutes": clampi(remaining_minutes, 0, GlobalTimer.TOTAL_MINUTES),
		"recorded_at": Time.get_datetime_string_from_system(false, true),
	})
	_sort_entries()
	if _entries.size() > MAX_ENTRIES:
		_entries.resize(MAX_ENTRIES)
	_save_entries()
	entries_changed.emit()

func get_entries() -> Array[Dictionary]:
	var copy: Array[Dictionary] = []
	for entry in _entries:
		copy.append(entry.duplicate(true))
	return copy

func clear_entries() -> void:
	_entries.clear()
	_save_entries()
	entries_changed.emit()

func snapshot_remaining_time(remaining_minutes: int) -> void:
	_pending_remaining_minutes = clampi(remaining_minutes, 0, GlobalTimer.TOTAL_MINUTES)

func consume_remaining_time_snapshot() -> int:
	var remaining_minutes: int = _pending_remaining_minutes
	_pending_remaining_minutes = -1
	if remaining_minutes >= 0:
		return remaining_minutes
	return max(GlobalTimer.TOTAL_MINUTES - GlobalTimer.current_minutes, 0)

func _load_entries() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_entries = []
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("LeaderboardManager: Could not read " + SAVE_PATH)
		_entries = []
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		_entries.clear()
		for entry in parsed:
			if entry is Dictionary:
				_entries.append(_sanitize_entry(entry))
		_sort_entries()
	else:
		push_warning("LeaderboardManager: Save file was not a leaderboard array.")
		_entries = []

func _save_entries() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("LeaderboardManager: Could not write " + SAVE_PATH)
		return
	file.store_string(JSON.stringify(_entries, "\t"))

func _sanitize_entry(entry: Dictionary) -> Dictionary:
	return {
		"player_name": str(entry.get("player_name", "Player")).strip_edges(),
		"tasks_completed": max(int(entry.get("tasks_completed", 0)), 0),
		"remaining_minutes": clampi(int(entry.get("remaining_minutes", 0)), 0, GlobalTimer.TOTAL_MINUTES),
		"recorded_at": str(entry.get("recorded_at", "")),
	}

func _sort_entries() -> void:
	_entries.sort_custom(_compare_entries)

func _compare_entries(a: Dictionary, b: Dictionary) -> bool:
	var a_tasks: int = int(a.get("tasks_completed", 0))
	var b_tasks: int = int(b.get("tasks_completed", 0))
	if a_tasks != b_tasks:
		return a_tasks > b_tasks

	var a_remaining: int = int(a.get("remaining_minutes", 0))
	var b_remaining: int = int(b.get("remaining_minutes", 0))
	if a_remaining != b_remaining:
		return a_remaining > b_remaining

	return str(a.get("recorded_at", "")) > str(b.get("recorded_at", ""))
