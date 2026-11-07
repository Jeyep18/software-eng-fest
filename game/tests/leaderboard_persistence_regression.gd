extends Node

class ControlledEnding extends "res://game/scenes/ending/EndingSequence.gd":
	func _start() -> void:
		pass

const SAVE_PATH := "user://leaderboard_scores_v2.json"
const BACKUP_PATH := SAVE_PATH + ".bak"

var _checks := 0
var _failures := 0
var _changes := 0

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	if OS.get_environment("BAGYONG_ISOLATED_SMOKE") != OS.get_user_data_dir():
		push_error("Leaderboard persistence regression requires isolated userdata.")
		get_tree().quit(1)
		return
	LeaderboardManager.entries_changed.connect(func() -> void: _changes += 1)
	_test_disk_transactions()
	await _test_prompt()
	await _test_clear_feedback()
	print("Leaderboard persistence regression: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)

func _test_disk_transactions() -> void:
	_check(LeaderboardManager.clear_entries() == OK, "clear reports a committed empty file")
	_check(LeaderboardManager.record_run("Existing", ["food"], SideQuestLog.STATE_COMPLETED, 120, "standard") == OK, "record reports a committed score")
	var original_entries := LeaderboardManager.get_entries()
	var original_bytes := FileAccess.get_file_as_bytes(SAVE_PATH)
	var changes_before := _changes
	var temp_path := LeaderboardManager.TEMP_PATH
	_check(not FileAccess.file_exists(BACKUP_PATH) and not FileAccess.file_exists(temp_path), "successful commits leave no backup or temporary scores")
	_check(DirAccess.make_dir_absolute(temp_path) == OK, "fixture blocks temporary writes")
	_check(LeaderboardManager.record_run("Failed", ["roof"], SideQuestLog.STATE_NOT_STARTED, 20, "standard") != OK, "failed save returns an error")
	_check(LeaderboardManager.clear_entries() != OK, "failed clear returns an error")
	_check(LeaderboardManager.get_entries() == original_entries and FileAccess.get_file_as_bytes(SAVE_PATH) == original_bytes and _changes == changes_before,
		"failed save and clear preserve memory, disk bytes and notifications")
	_check(DirAccess.remove_absolute(temp_path) == OK, "fixture releases temporary path")

	if OS.get_name() == "Windows":
		_check(FileAccess.set_read_only_attribute(SAVE_PATH, true) == OK, "fixture makes the prior score read-only")
		_check(LeaderboardManager.clear_entries() != OK, "backup cleanup failure cannot report a successful clear")
		_check(LeaderboardManager.get_entries() == original_entries and FileAccess.get_file_as_bytes(SAVE_PATH) == original_bytes and _changes == changes_before,
			"backup cleanup failure restores the prior score and leaves memory unchanged")
		_check(FileAccess.set_read_only_attribute(SAVE_PATH, false) == OK, "fixture restores writable scores")

	_check(DirAccess.rename_absolute(SAVE_PATH, BACKUP_PATH) == OK, "fixture simulates an interrupted replacement")
	_write(SAVE_PATH, "[]")
	LeaderboardManager._load_entries()
	_check(LeaderboardManager.get_entries() == original_entries, "startup uses the last committed backup over an interrupted candidate")
	_check(LeaderboardManager.record_run("Retry", ["roof"], SideQuestLog.STATE_NOT_STARTED, 20, "standard") == OK, "retry recovers the backup before committing once")
	_check(LeaderboardManager.get_entries().size() == 2 and _changes == changes_before + 1 and not FileAccess.file_exists(BACKUP_PATH),
		"retry commits one new entry and removes the recovered backup")

	var valid: Dictionary = original_entries[0].duplicate(true)
	var malformed := valid.duplicate(true)
	malformed["remaining_minutes"] = {"bad": 4}
	_write(BACKUP_PATH, JSON.stringify([malformed]))
	LeaderboardManager._load_entries()
	_check(LeaderboardManager.get_entries().size() == 2, "an entirely malformed backup cannot hide a valid current file")
	_check(LeaderboardManager.record_run("Recovered current", ["water"], SideQuestLog.STATE_NOT_STARTED, 10, "standard") == OK
		and LeaderboardManager.get_entries().size() == 3, "saving discards an invalid backup while preserving valid current scores")
	var malformed_name := valid.duplicate(true)
	malformed_name["player_name"] = ["bad"]
	var huge_time := valid.duplicate(true)
	huge_time["remaining_minutes"] = 1e100
	huge_time["player_name"] = "Clamped"
	_write(SAVE_PATH, JSON.stringify([malformed, valid, false, malformed_name, huge_time]))
	LeaderboardManager._load_entries()
	var loaded := LeaderboardManager.get_entries()
	_check(loaded.size() == 2 and loaded[1] == original_entries[0], "malformed fields are skipped while valid old scores retain their data")
	_check(loaded[0]["remaining_minutes"] == GlobalTimer.TOTAL_MINUTES, "oversized numeric time is clamped before integer conversion")
	_write("user://leaderboard_scores.json", "archived count-only fixture")
	_write(SAVE_PATH, "{broken JSON")
	LeaderboardManager._load_entries()
	_check(LeaderboardManager.get_entries().is_empty(), "malformed JSON recovers to an empty list without a script error")
	if OS.get_name() == "Windows":
		_check(FileAccess.set_read_only_attribute(SAVE_PATH, true) == OK, "fixture protects malformed score bytes")
		_check(LeaderboardManager.clear_entries() != OK and FileAccess.get_file_as_string(SAVE_PATH) == "{broken JSON",
			"a failed replacement also preserves malformed original bytes")
		_check(FileAccess.set_read_only_attribute(SAVE_PATH, false) == OK, "fixture releases malformed score bytes")
	_write(LeaderboardManager.TEMP_PATH, "interrupted alias fixture")
	_check(LeaderboardManager.clear_entries() == OK and JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH)) == [] and not FileAccess.file_exists(BACKUP_PATH),
		"successful clear leaves an empty current file and no retained score backup")
	_check(not FileAccess.file_exists(LeaderboardManager.TEMP_PATH), "successful clear removes an interrupted temporary score file")
	_check(FileAccess.get_file_as_string("user://leaderboard_scores.json") == "archived count-only fixture", "archived count-only scores remain untouched")

func _test_prompt() -> void:
	_check(LeaderboardManager.clear_entries() == OK, "prompt fixture starts without scores")
	_check(DirAccess.remove_absolute(SAVE_PATH) == OK, "prompt fixture removes the empty score file")
	var ending := preload("res://game/scenes/ending/EndingSequence.tscn").instantiate()
	ending.set_script(ControlledEnding)
	add_child(ending)
	await get_tree().process_frame
	var changes_before := _changes
	ending._submit_leaderboard_score()
	await get_tree().process_frame
	var prompt: CanvasLayer = ending.get_node("LeaderboardNamePrompt")
	var input: LineEdit = prompt.find_child("NameInput", true, false)
	var skip: Button = prompt.find_child("SkipButton", true, false)
	var save: Button = prompt.find_child("SubmitButton", true, false)
	_check(input.has_focus() and save.disabled and not skip.disabled, "empty nickname permits continuing without saving")
	skip.pressed.emit()
	await get_tree().process_frame
	_check(not ending.has_node("LeaderboardNamePrompt") and ending._leaderboard_prompt_completed and _changes == changes_before and not FileAccess.file_exists(SAVE_PATH),
		"skip finishes without writing a score or notifying leaderboard changes")
	ending._submit_leaderboard_score()
	_check(not ending.has_node("LeaderboardNamePrompt"), "the completed nickname choice is idempotent")

	ending._leaderboard_prompt_completed = false
	ending._submit_leaderboard_score()
	await get_tree().process_frame
	prompt = ending.get_node("LeaderboardNamePrompt")
	input = prompt.find_child("NameInput", true, false)
	save = prompt.find_child("SubmitButton", true, false)
	input.text = "Retry nickname"
	input.text_changed.emit(input.text)
	var temp_path := LeaderboardManager.TEMP_PATH
	_check(DirAccess.make_dir_absolute(temp_path) == OK, "prompt fixture blocks writes")
	save.pressed.emit()
	await get_tree().process_frame
	_check(prompt.visible and prompt.find_child("Error", true, false).visible and not ending._leaderboard_prompt_completed
		and LeaderboardManager.get_entries().is_empty() and _changes == changes_before,
		"failed submission stays open with a visible error and leaves the result unsaved")
	_check(DirAccess.remove_absolute(temp_path) == OK, "prompt fixture releases writes")
	save.pressed.emit()
	await get_tree().process_frame
	_check(not ending.has_node("LeaderboardNamePrompt") and ending._leaderboard_prompt_completed
		and LeaderboardManager.get_entries().size() == 1 and _changes == changes_before + 1, "retry saves once and closes the same prompt")

	for language in ["english", "tagalog"]:
		for scale_percent in [100, 175]:
			LocalizationManager.set_language(language)
			VisualSettings.set_ui_scale_percent(scale_percent)
			ending._leaderboard_prompt_completed = false
			ending._submit_leaderboard_score()
			await get_tree().process_frame
			await get_tree().process_frame
			prompt = ending.get_node("LeaderboardNamePrompt")
			input = prompt.find_child("NameInput", true, false)
			skip = prompt.find_child("SkipButton", true, false)
			save = prompt.find_child("SubmitButton", true, false)
			input.text = "Keyboard nickname"
			input.text_changed.emit(input.text)
			_key(KEY_TAB)
			_check(skip.has_focus(), "Tab reaches Continue without saving " + language + str(scale_percent))
			_key(KEY_TAB)
			_check(save.has_focus(), "Tab reaches Save " + language + str(scale_percent))
			_key(KEY_TAB)
			_check(input.has_focus(), "Tab stays within the nickname prompt " + language + str(scale_percent))
			_check(DirAccess.make_dir_absolute(temp_path) == OK, "layout fixture blocks writes")
			save.pressed.emit()
			await get_tree().process_frame
			await get_tree().process_frame
			var panel: Control = prompt.get_node("Panel")
			_check(get_viewport().get_visible_rect().encloses(panel.get_global_rect())
				and panel.get_global_rect().encloses(skip.get_global_rect()) and panel.get_global_rect().encloses(save.get_global_rect()),
				"nickname notice, error and actions fit " + language + str(scale_percent))
			_check(prompt.find_child("PrivacyNotice", true, false).text == LocalizationManager.translate_key("ui.leaderboard.nickname_notice"),
				"nickname notice is localized " + language)
			await _capture("score_prompt_%s_%d" % [language, scale_percent])
			_check(DirAccess.remove_absolute(temp_path) == OK, "layout fixture releases writes")
			skip.pressed.emit()
			await get_tree().process_frame
	ending.queue_free()
	await get_tree().process_frame
	_check(_changes == changes_before + 1 and LeaderboardManager.get_entries().size() == 1, "all skipped layout prompts preserve the one saved score")
	LocalizationManager.set_language("english")
	VisualSettings.set_ui_scale_percent(140)

func _test_clear_feedback() -> void:
	var board := preload("res://game/ui/leaderboards/leaderboards_modal.tscn").instantiate()
	add_child(board)
	board.open()
	await get_tree().create_timer(0.2).timeout
	var original_entries := LeaderboardManager.get_entries()
	var original_bytes := FileAccess.get_file_as_bytes(SAVE_PATH)
	var changes_before := _changes
	var temp_path := LeaderboardManager.TEMP_PATH
	_check(DirAccess.make_dir_absolute(temp_path) == OK, "clear UI fixture blocks writes")
	board.clear_button.pressed.emit()
	board.clear_button.pressed.emit()
	_check(board.error_label.visible and board._clear_armed and not board.empty_label.visible
		and LeaderboardManager.get_entries() == original_entries and FileAccess.get_file_as_bytes(SAVE_PATH) == original_bytes and _changes == changes_before,
		"failed Clear shows an error and keeps all displayed and saved scores")
	_check(DirAccess.remove_absolute(temp_path) == OK, "clear UI fixture releases writes")
	board.clear_button.pressed.emit()
	_check(not board.error_label.visible and board.empty_label.visible and board.close_button.has_focus()
		and LeaderboardManager.get_entries().is_empty() and not FileAccess.file_exists(BACKUP_PATH) and _changes == changes_before + 1,
		"Clear retry commits erasure and returns focus to Close")
	board.queue_free()
	await get_tree().process_frame

func _write(path: String, contents: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	_check(file != null, "fixture opens " + path)
	if file != null:
		file.store_string(contents)
		file.close()

func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	get_viewport().push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	get_viewport().push_input(event, true)

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	_check(get_viewport().get_texture().get_image().save_png("user://%s.png" % label) == OK, "saved " + label)

func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print("LEADERBOARD ", "PASS " if condition else "FAIL ", description)
