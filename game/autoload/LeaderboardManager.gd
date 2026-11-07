extends Node

signal entries_changed

const SAVE_PATH: String = "user://leaderboard_scores_v2.json"
const TEMP_PATH: String = SAVE_PATH + ".tmp"
const BACKUP_PATH: String = SAVE_PATH + ".bak"
const MAX_ENTRIES: int = 25

var _entries: Array[Dictionary] = []
var _pending_remaining_minutes: int = -1

func _ready() -> void:
	_load_entries()

func record_run(player_name: String, resolved_need_ids: Array, nestor_status: String, remaining_minutes: int, difficulty_id: String = "") -> Error:
	if DevMode.run_unranked:
		return ERR_UNAUTHORIZED
	var clean_name: String = player_name.strip_edges()
	if clean_name.is_empty():
		clean_name = "Player"
	if difficulty_id.is_empty():
		difficulty_id = GameState.get_difficulty_id()
	var need_ids := _canonical_need_ids(resolved_need_ids)
	var quest_status := _canonical_nestor_status(nestor_status)
	var safe_minutes := clampi(remaining_minutes, 0, GlobalTimer.TOTAL_MINUTES)

	var next_entries := get_entries()
	next_entries.append({
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
	_sort_entries(next_entries)
	_trim_entries(next_entries)
	return _save_entries(next_entries)

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

func clear_entries(_difficulty_id: String = "") -> Error:
	return _save_entries([])

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
	_entries = []
	# A retained backup means the replacement did not finish committing.
	for path in [BACKUP_PATH, SAVE_PATH]:
		if not FileAccess.file_exists(path):
			continue
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			push_warning("LeaderboardManager: Could not read " + path)
			continue
		var json := JSON.new()
		var parse_error := json.parse(file.get_as_text())
		file.close()
		if parse_error != OK or not (json.data is Array):
			push_warning("LeaderboardManager: Save file was not a leaderboard array.")
			continue
		var loaded_entries := _sanitize_entries(json.data)
		if loaded_entries.is_empty() and not json.data.is_empty():
			continue
		_entries = loaded_entries
		_sort_entries(_entries)
		_trim_entries(_entries)
		return

func _recover_backup() -> Error:
	if not FileAccess.file_exists(BACKUP_PATH):
		return OK
	var file := FileAccess.open(BACKUP_PATH, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	file.close()
	if parse_error != OK or not (json.data is Array):
		return DirAccess.remove_absolute(BACKUP_PATH)
	if not json.data.is_empty() and _sanitize_entries(json.data).is_empty():
		return DirAccess.remove_absolute(BACKUP_PATH)
	return DirAccess.rename_absolute(BACKUP_PATH, SAVE_PATH)

func _save_entries(next_entries: Array[Dictionary]) -> Error:
	var error := _recover_backup()
	if error != OK:
		return error
	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	if not file.store_string(JSON.stringify(next_entries, "\t")):
		error = ERR_FILE_CANT_WRITE
	file.flush()
	if error == OK:
		error = file.get_error()
	file.close()
	if error == OK and FileAccess.file_exists(SAVE_PATH):
		error = DirAccess.rename_absolute(SAVE_PATH, BACKUP_PATH)
	if error == OK:
		error = DirAccess.rename_absolute(TEMP_PATH, SAVE_PATH)
	if error == OK and FileAccess.file_exists(BACKUP_PATH):
		error = DirAccess.remove_absolute(BACKUP_PATH)
	if error != OK:
		if FileAccess.file_exists(BACKUP_PATH):
			var recovery_error := DirAccess.rename_absolute(BACKUP_PATH, SAVE_PATH)
			if recovery_error != OK:
				push_warning("LeaderboardManager: Previous scores remain in the backup. " + error_string(recovery_error))
		if FileAccess.file_exists(TEMP_PATH):
			DirAccess.remove_absolute(TEMP_PATH)
		return error
	_entries = next_entries
	entries_changed.emit()
	return OK

func _sanitize_entries(source: Array) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for entry in source:
		if entry is Dictionary:
			var sanitized := _sanitize_entry(entry)
			if not sanitized.is_empty():
				entries.append(sanitized)
	return entries

func _sanitize_entry(entry: Dictionary) -> Dictionary:
	var minutes: Variant = entry.get("remaining_minutes", 0)
	if not (minutes is int or minutes is float) or not is_finite(float(minutes)):
		return {}
	for key in ["player_name", "difficulty", "nestor_status", "recorded_at"]:
		if entry.has(key) and not (entry[key] is String):
			return {}
	var need_ids := _canonical_need_ids(entry.get("resolved_need_ids", []))
	var quest_status := _canonical_nestor_status(str(entry.get("nestor_status", SideQuestLog.STATE_NOT_STARTED)))
	var remaining_minutes := int(clampf(float(minutes), 0.0, GlobalTimer.TOTAL_MINUTES))
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

func _sort_entries(entries: Array[Dictionary]) -> void:
	entries.sort_custom(_compare_entries)

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

func _trim_entries(entries: Array[Dictionary]) -> void:
	if entries.size() > MAX_ENTRIES:
		entries.resize(MAX_ENTRIES)
