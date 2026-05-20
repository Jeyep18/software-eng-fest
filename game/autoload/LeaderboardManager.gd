extends Node

signal entries_changed

const SAVE_PATH: String = "user://leaderboard_scores.json"
const MAX_ENTRIES: int = 25

var _entries: Array[Dictionary] = []
var _pending_remaining_minutes: int = -1

func _ready() -> void:
	_load_entries()

func record_run(player_name: String, tasks_completed: int, remaining_minutes: int, difficulty_id: String = "") -> void:
	var clean_name: String = player_name.strip_edges()
	if clean_name.is_empty():
		clean_name = "Player"
	if difficulty_id.is_empty():
		difficulty_id = GameState.get_difficulty_id()

	_entries.append({
		"player_name": clean_name,
		"tasks_completed": max(tasks_completed, 0),
		"remaining_minutes": clampi(remaining_minutes, 0, GlobalTimer.TOTAL_MINUTES),
		"difficulty": difficulty_id,
		"recorded_at": Time.get_datetime_string_from_system(false, true),
	})
	_sort_entries()
	_trim_entries_for_difficulty(difficulty_id)
	_save_entries()
	entries_changed.emit()

func get_entries() -> Array[Dictionary]:
	var copy: Array[Dictionary] = []
	for entry in _entries:
		copy.append(entry.duplicate(true))
	return copy

func get_entries_for_difficulty(difficulty_id: String) -> Array[Dictionary]:
	var filtered: Array[Dictionary] = []
	for entry in _entries:
		if str(entry.get("difficulty", "standard")) == difficulty_id:
			filtered.append(entry.duplicate(true))
	return filtered

func clear_entries(difficulty_id: String = "") -> void:
	if difficulty_id.is_empty():
		_entries.clear()
	else:
		for i in range(_entries.size() - 1, -1, -1):
			if str(_entries[i].get("difficulty", "standard")) == difficulty_id:
				_entries.remove_at(i)
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
		"difficulty": str(entry.get("difficulty", "standard")),
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

func _trim_entries_for_difficulty(difficulty_id: String) -> void:
	var seen: int = 0
	var remove_indices: Array[int] = []
	for i in range(_entries.size()):
		if str(_entries[i].get("difficulty", "standard")) != difficulty_id:
			continue
		seen += 1
		if seen > MAX_ENTRIES:
			remove_indices.append(i)
	for i in range(remove_indices.size() - 1, -1, -1):
		_entries.remove_at(remove_indices[i])
