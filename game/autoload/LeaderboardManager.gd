extends Node

signal entries_changed

const SAVE_PATH: String = "user://leaderboard_scores_v2.json"
const MAX_ENTRIES: int = 25

var _entries: Array[Dictionary] = []
var _pending_remaining_minutes: int = -1

func _ready() -> void:
	_load_entries()

func record_run(player_name: String, resolved_need_ids: Array, nestor_status: String, remaining_minutes: int, difficulty_id: String = "") -> void:
	if DevMode.run_unranked:
		return
	var clean_name: String = player_name.strip_edges()
	if clean_name.is_empty():
		clean_name = "Player"
	if difficulty_id.is_empty():
		difficulty_id = GameState.get_difficulty_id()
	var need_ids := _canonical_need_ids(resolved_need_ids)
	var quest_status := _canonical_nestor_status(nestor_status)
	var safe_minutes := clampi(remaining_minutes, 0, GlobalTimer.TOTAL_MINUTES)

	_entries.append({
		"player_name": clean_name,
		"resolved_need_ids": need_ids,
		"tasks_completed": need_ids.size(),
		"weighted_preparation": NeedsLog.weight_for_ids(need_ids),
		"nestor_status": quest_status,
		"remaining_minutes": safe_minutes,
		"difficulty": difficulty_id,
		"score": calculate_score(need_ids, quest_status == SideQuestLog.STATE_COMPLETED, safe_minutes, difficulty_id),
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

func calculate_score(resolved_need_ids: Array, nestor_completed: bool, remaining_minutes: int, difficulty_id: String = "") -> float:
	if difficulty_id.is_empty():
		difficulty_id = GameState.get_difficulty_id()
	var base_score := NeedsLog.weight_for_ids(resolved_need_ids) * 2000
	if nestor_completed:
		base_score += 1000
	base_score += clampi(remaining_minutes, 0, GlobalTimer.TOTAL_MINUTES)
	return float(base_score) * GameState.get_difficulty_score_multiplier(difficulty_id)

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
		_trim_entries()
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
	var need_ids := _canonical_need_ids(entry.get("resolved_need_ids", []))
	var quest_status := _canonical_nestor_status(str(entry.get("nestor_status", SideQuestLog.STATE_NOT_STARTED)))
	var remaining_minutes: int = clampi(int(entry.get("remaining_minutes", 0)), 0, GlobalTimer.TOTAL_MINUTES)
	var difficulty_id: String = str(entry.get("difficulty", "standard"))
	var clean_name := str(entry.get("player_name", "Player")).strip_edges()
	if clean_name.is_empty():
		clean_name = "Player"
	return {
		"player_name": clean_name,
		"resolved_need_ids": need_ids,
		"tasks_completed": need_ids.size(),
		"weighted_preparation": NeedsLog.weight_for_ids(need_ids),
		"nestor_status": quest_status,
		"remaining_minutes": remaining_minutes,
		"difficulty": difficulty_id,
		"score": calculate_score(need_ids, quest_status == SideQuestLog.STATE_COMPLETED, remaining_minutes, difficulty_id),
		"recorded_at": str(entry.get("recorded_at", "")),
	}

func _canonical_need_ids(source: Variant) -> Array[String]:
	var ids: Array[String] = []
	if not (source is Array):
		return ids
	for need in range(NeedsLog.Need.size()):
		var need_id := str(NeedsLog.NEED_IDS[need])
		if source.has(need_id):
			ids.append(need_id)
	return ids

func _canonical_nestor_status(status: String) -> String:
	if status in [SideQuestLog.STATE_NOT_STARTED, SideQuestLog.STATE_ACTIVE,
			SideQuestLog.STATE_READY_TO_TURN_IN, SideQuestLog.STATE_COMPLETED]:
		return status
	return SideQuestLog.STATE_NOT_STARTED

func _sort_entries() -> void:
	_entries.sort_custom(_compare_entries)

func _compare_entries(a: Dictionary, b: Dictionary) -> bool:
	var a_score: float = float(a.get("score", 0.0))
	var b_score: float = float(b.get("score", 0.0))
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
