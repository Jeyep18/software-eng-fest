extends Node

var _checks: int = 0
var _failures: int = 0


func _ready() -> void:
	_run.call_deferred()


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("Dev Mode regression failed: " + description)


func _send_sequence(menu: Variant, letters: String) -> void:
	for letter in letters:
		var event := InputEventKey.new()
		event.pressed = true
		event.keycode = OS.find_keycode_from_string(letter)
		menu._unhandled_key_input(event)


func _wait_for_travel(location_id: String) -> bool:
	var deadline := Time.get_ticks_msec() + 12000
	while Time.get_ticks_msec() < deadline:
		if not SceneManager.is_travelling and SceneManager.current_location == location_id:
			return true
		await get_tree().create_timer(0.05).timeout
	return false


func _run() -> void:
	GameState.reset()
	SceneManager.reset()
	StormEnroachment.reset()
	GlobalTimer.start_fresh()
	DevMode.begin_run()
	_check(not DevMode.unlocked and not DevMode.enabled, "new process starts locked and disabled")
	_check(not DevMode.add_money(1), "locked money action denied")
	_check(not DevMode.set_enabled(true), "locked toggle denied")
	var settings := AudioSettingsPanel.new()
	add_child(settings)
	var pause_menu: Variant = load("res://game/ui/pause/PauseMenu.tscn").instantiate()
	add_child(pause_menu)
	if not DevMode.is_available():
		_check(settings._dev_mode_row == null and pause_menu._dev_nav == null, "release UI has no developer controls")
		_check(not DevMode.unlock(), "release build refuses direct unlock")
		_check(not DevMode.set_enabled(true), "release build refuses enable")
		_check(not DevMode.set_clock_paused(true), "release build refuses timer pause")
		_check(not DevMode.reset_clock(), "release build refuses clock rewind")
		_check(not DevMode.teleport_to("home"), "release build refuses teleport")
		SceneManager.travel_to("home", "", 0, true)
		_check(not SceneManager.is_travelling and GameState.get_cash() == 0 and GlobalTimer.current_minutes == 0, "release direct commands leave state unchanged")
		_finish()
		return
	_check(settings._dev_mode_row != null and not settings._dev_mode_row.visible, "developer toggle starts hidden")
	_check(pause_menu._dev_nav != null and not pause_menu._dev_nav.visible, "developer tab starts hidden")

	var menu: Variant = load("res://game/scenes/main_menu/Main_Menu1.tscn").instantiate()
	get_tree().root.add_child(menu)
	menu._settings_layer.show()
	_send_sequence(menu, "HELLOWORLD")
	_check(not DevMode.unlocked, "sequence ignored while menu overlay is open")
	menu._settings_layer.hide()
	_send_sequence(menu, "HELLO")
	menu._on_settings_pressed()
	menu._on_settings_close_requested()
	_send_sequence(menu, "WORLD")
	_check(not DevMode.unlocked, "opening Settings clears a partial sequence")
	var focused_field := LineEdit.new()
	menu.add_child(focused_field)
	focused_field.grab_focus()
	_send_sequence(menu, "HELLOWORLD")
	_check(not DevMode.unlocked, "focused text field ignores sequence")
	focused_field.release_focus()
	focused_field.queue_free()
	await get_tree().process_frame
	_send_sequence(menu, "HELLO")
	menu._dev_sequence_last_key_msec = Time.get_ticks_msec() - 5001
	_send_sequence(menu, "WORLD")
	_check(not DevMode.unlocked, "sequence times out")
	_send_sequence(menu, "HELLOWORLX")
	_check(not DevMode.unlocked, "wrong sequence does not unlock")
	_send_sequence(menu, "HELLO")
	var modified_key := InputEventKey.new()
	modified_key.pressed = true
	modified_key.keycode = KEY_W
	modified_key.shift_pressed = true
	menu._unhandled_key_input(modified_key)
	var repeated_key := InputEventKey.new()
	repeated_key.pressed = true
	repeated_key.keycode = KEY_W
	repeated_key.echo = true
	menu._unhandled_key_input(repeated_key)
	_send_sequence(menu, "WORLD")
	_check(DevMode.unlocked, "correct sequence unlocks while modified and repeated keys are ignored")
	_check(settings._dev_mode_row.visible, "unlock reveals Settings toggle")
	menu.queue_free()
	await get_tree().process_frame

	_check(DevMode.set_enabled(true), "unlocked toggle enables mode")
	_check(DevMode.run_unranked, "enabling during run makes it unranked")
	_check(pause_menu._dev_nav.visible, "enabled mode reveals pause tab")
	_check(not DevMode.add_money(0) and not DevMode.add_money(DevMode.MAX_CASH_CHANGE + 1), "invalid money amounts denied")
	_check(DevMode.add_money(100) and GameState.get_cash() == 100, "money addition uses GameState")
	_check(DevMode.remove_money(150) and GameState.get_cash() == 0, "money removal stops at zero")
	var score_count := LeaderboardManager.get_entries().size()
	LeaderboardManager.record_run("Dev test", 6, 720, "standard")
	_check(LeaderboardManager.get_entries().size() == score_count, "unranked run cannot save score")

	var other_owner := Node.new()
	get_tree().root.add_child(other_owner)
	GlobalTimer.pause_timer(other_owner)
	_check(DevMode.set_clock_paused(true), "developer acquires timer pause")
	_check(DevMode.set_clock_paused(false) and GlobalTimer.is_paused, "developer release preserves another pause owner")
	GlobalTimer.resume_timer(other_owner)
	_check(not GlobalTimer.is_paused, "clock resumes after all owners release")
	GlobalTimer.pause_timer(other_owner)
	GlobalTimer.add_time(360)
	_check(StormEnroachment.get_state("grocery") == "inaccessible", "storm closes grocery at 360")
	_check(DevMode.reset_clock(), "developer rewinds clock")
	_check(GlobalTimer.current_minutes == 0 and GlobalTimer.is_paused, "rewind preserves other pause owner")
	_check(StormEnroachment.get_state("grocery") == "open" and SceneManager.closed_zones.is_empty(), "rewind reopens storm restrictions")
	GlobalTimer.add_time(240)
	_check(StormEnroachment.get_state("grocery") == "danger", "rewound threshold fires again")
	GlobalTimer.add_time(120)
	_check(StormEnroachment.get_state("grocery") == "inaccessible", "grocery closes again")

	_check(not DevMode.teleport_to("ending"), "teleport whitelist rejects ending")
	SceneManager.storm_transition_pending = true
	_check(not DevMode.teleport_to("home") and not DevMode.reset_clock(), "storm transition denies dev actions")
	SceneManager.storm_transition_pending = false
	var minute_before := GlobalTimer.current_minutes
	reparent(get_tree().root)
	_check(DevMode.teleport_to("grocery"), "developer teleport starts into closed location")
	_check(not DevMode.teleport_to("hardware"), "overlapping teleport denied")
	_check(await _wait_for_travel("grocery"), "teleport reaches closed grocery")
	_check(GlobalTimer.current_minutes == minute_before, "teleport charges no time or danger penalty")
	_check(StormEnroachment.get_state("grocery") == "inaccessible", "teleport does not change storm closures")
	_check(DevMode.teleport_to("bodega"), "developer teleport enters bodega")
	_check(await _wait_for_travel("home") and get_tree().current_scene.scene_file_path.ends_with("bodega.tscn"), "bodega aliases home after travel")

	_check(DevMode.set_clock_paused(true), "developer can pause clock after teleport")
	_check(DevMode.set_enabled(false), "developer can disable mode")
	_check(not pause_menu._dev_nav.visible, "disabling hides pause tab")
	_check(not DevMode.clock_paused and GlobalTimer.is_paused, "disabling releases only developer pause")
	_check(DevMode.run_unranked, "disabling does not restore score eligibility")
	_check(not DevMode.add_money(1), "disabled mode refuses commands")
	LeaderboardManager.record_run("Dev test after disable", 6, 720, "standard")
	_check(LeaderboardManager.get_entries().size() == score_count, "unranked guard persists after disable")
	DevMode.end_run()
	_check(DevMode.unlocked and not DevMode.run_unranked, "end run keeps unlock but clears ranking state")
	_check(DevMode.set_enabled(true), "session toggle remains available after run ends")
	DevMode.begin_run()
	_check(DevMode.run_unranked, "new run starts unranked when mode remains enabled")
	DevMode.end_run()
	GlobalTimer.resume_timer(other_owner)
	other_owner.queue_free()
	_finish()


func _finish() -> void:
	print("Dev Mode regression: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(1 if _failures else 0)
