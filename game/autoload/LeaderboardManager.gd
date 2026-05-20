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
		"score": _calculate_score(max(tasks_completed, 0), clampi(remaining_minutes, 0, GlobalTimer.TOTAL_MINUTES), difficulty_id),
		"recorded_at": Time.get_datetime_string_from_system(false, true),
	})
	_sort_entries()
	_trim_entries()
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

func get_ranked_entries() -> Array[Dictionary]:
	var copy: Array[Dictionary] = []
	for entry in _entries:
		copy.append(entry.duplicate(true))
	return copy

func clear_entries(_difficulty_id: String = "") -> void:
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
	var tasks_completed: int = max(int(entry.get("tasks_completed", 0)), 0)
	var remaining_minutes: int = clampi(int(entry.get("remaining_minutes", 0)), 0, GlobalTimer.TOTAL_MINUTES)
	var difficulty_id: String = str(entry.get("difficulty", "standard"))
	return {
		"player_name": str(entry.get("player_name", "Player")).strip_edges(),
		"tasks_completed": tasks_completed,
		"remaining_minutes": remaining_minutes,
		"difficulty": difficulty_id,
		"score": _calculate_score(tasks_completed, remaining_minutes, difficulty_id),
		"recorded_at": str(entry.get("recorded_at", "")),
	}

func _sort_entries() -> void:
	_entries.sort_custom(_compare_entries)

func _compare_entries(a: Dictionary, b: Dictionary) -> bool:
	var a_score: float = float(a.get("score", _calculate_score(int(a.get("tasks_completed", 0)), int(a.get("remaining_minutes", 0)), str(a.get("difficulty", "standard")))))
	var b_score: float = float(b.get("score", _calculate_score(int(b.get("tasks_completed", 0)), int(b.get("remaining_minutes", 0)), str(b.get("difficulty", "standard")))))
	if not is_equal_approx(a_score, b_score):
		return a_score > b_score

	var a_remaining: int = int(a.get("remaining_minutes", 0))
	var b_remaining: int = int(b.get("remaining_minutes", 0))
	if a_remaining != b_remaining:
		return a_remaining > b_remaining

	return str(a.get("recorded_at", "")) > str(b.get("recorded_at", ""))

func _trim_entries() -> void:
	while _entries.size() > MAX_ENTRIES:
		_entries.pop_back()

func _calculate_score(tasks_completed: int, remaining_minutes: int, difficulty_id: String) -> float:
	var base_score: float = float(tasks_completed * 1000 + remaining_minutes)
	return base_score * GameState.get_difficulty_score_multiplier(difficulty_id)
