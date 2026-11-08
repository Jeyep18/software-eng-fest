extends Node

const FRIDGE = preload("res://game/objects/interactables/fridge.tscn")
const CHICKEN_SHOP = preload("res://game/resources/shops/ChooksToGoShop.tres")
const CANS = preload("res://game/resources/items/canned_goods.tres")

var _checks := 0
var _failures := 0


func _ready() -> void:
	_run.call_deferred()


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FOOD FAIL: " + description)


func _run() -> void:
	if OS.get_environment("BAGYONG_ISOLATED_SMOKE") != OS.get_user_data_dir():
		push_error("Food regression requires isolated user data.")
		get_tree().quit(1)
		return
	get_tree().current_scene = null
	GlobalTimer.set_process(false)
	for counts in [[0, 0, 0], [3, 0, 0], [0, 0, 1], [3, 0, 1], [2, 0, 1]]:
		var fridge := _fresh_fridge(counts)
		var task := fridge.get_node("Area3D") as TaskObject
		_check(not task._has_all_required_items(), "incomplete options rejected: " + str(counts))
		task._complete_task()
		_check(not task._is_completing and not NeedsLog.is_resolved(NeedsLog.Need.FOOD), "incomplete options cannot start completion")
		_check(_quantities() == counts and GlobalTimer.current_minutes == 100, "rejection preserves all food and time")
		fridge.free()
	for test_case in [
		[[4, 0, 0], [0, 0, 0], "exactly four cans feed the family"],
		[[5, 1, 2], [1, 1, 2], "cans take priority"],
		[[3, 2, 2], [3, 1, 2], "one whole chicken takes priority over halves"],
		[[3, 0, 3], [3, 0, 1], "exactly two halves feed the family"],
	]:
		var fridge := _fresh_fridge(test_case[0])
		var task := fridge.get_node("Area3D") as TaskObject
		SideQuestLog.start_mang_nestor_chicken()
		SideQuestLog.refresh_mang_nestor_chicken()
		_check(task._has_all_required_items(), "complete option accepted: " + test_case[2])
		var quest_state := SideQuestLog.STATE_READY_TO_TURN_IN if test_case[0][2] > 0 else SideQuestLog.STATE_ACTIVE
		_check(SideQuestLog.get_quest_state(SideQuestLog.QUEST_MANG_NESTOR_CHICKEN) == quest_state, "only held half chicken readies Nestor's errand")
		task._complete_task()
		await _wait_until(func(): return not task._is_completing, "completion finishes: " + test_case[2])
		_check(NeedsLog.is_resolved(NeedsLog.Need.FOOD) and task._is_completed, "food resolves: " + test_case[2])
		_check(not task._is_showing and task._get_active_lines() == task.completed_lines, "completion adds no extra dialogue and retains the completed branch")
		_check(_quantities() == test_case[1], "only selected food is consumed: " + test_case[2])
		_check(GlobalTimer.current_minutes == 105 and not GlobalTimer.is_paused, "completion costs five minutes and releases pause")
		task._complete_task()
		_check(_quantities() == test_case[1] and GlobalTimer.current_minutes == 105, "repeat completion consumes nothing")
		_check(SideQuestLog.get_quest_state(SideQuestLog.QUEST_MANG_NESTOR_CHICKEN) == quest_state, "household task preserves Nestor's unfinished errand")
		fridge.free()
	await _test_supply_changes()
	_test_text()
	_test_ready_dialogue()
	await _test_deadline()
	print("Food options regression: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)


func _fresh_fridge(counts: Array) -> Node3D:
	SceneManager.reset()
	GlobalTimer.reset()
	StormEnroachment.reset()
	NeedsLog.reset()
	InventoryManager.reset()
	SideQuestLog.reset()
	GameState.reset()
	GameState.house_tasks_unlocked = true
	GlobalTimer.start_fresh()
	GlobalTimer.current_minutes = 100
	for index in counts.size():
		var item: ItemData = [CANS, CHICKEN_SHOP.items[0].item_data, CHICKEN_SHOP.items[1].item_data][index]
		for _quantity in counts[index]:
			_check(InventoryManager.add_item(item), "authored shop food enters inventory")
	var fridge := FRIDGE.instantiate() as Node3D
	add_child(fridge)
	return fridge


func _quantities() -> Array:
	return [InventoryManager.get_total_quantity("canned_goods"), InventoryManager.get_total_quantity("whole_chicken"), InventoryManager.get_total_quantity("half_chicken")]


func _wait_until(condition: Callable, description: String) -> void:
	var deadline := Time.get_ticks_msec() + 8000
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	_check(condition.call(), description)


func _test_supply_changes() -> void:
	var fridge := _fresh_fridge([3, 0, 2])
	var task := fridge.get_node("Area3D") as TaskObject
	SideQuestLog.start_mang_nestor_chicken()
	SideQuestLog.refresh_mang_nestor_chicken()
	task._complete_task()
	_check(task._is_completing, "two halves begin completion")
	InventoryManager.remove_item_by_id("half_chicken")
	await _wait_until(func(): return not task._is_completing, "removing a half during fade cancels completion")
	_check(not NeedsLog.is_resolved(NeedsLog.Need.FOOD) and _quantities() == [3, 0, 1], "cancellation preserves remaining food")
	_check(GlobalTimer.current_minutes == 100 and not GlobalTimer.is_paused and TransitionOverlay.overlay.color.a < 0.01, "cancellation restores view and charges no time")
	InventoryManager.add_item(CHICKEN_SHOP.items[1].item_data)
	task._complete_task()
	await _wait_until(func(): return not task._is_completing, "restoring second half allows retry")
	_check(NeedsLog.is_resolved(NeedsLog.Need.FOOD) and _quantities() == [3, 0, 0] and GlobalTimer.current_minutes == 105, "retry consumes exactly two halves once")
	_check(SideQuestLog.get_quest_state(SideQuestLog.QUEST_MANG_NESTOR_CHICKEN) == SideQuestLog.STATE_ACTIVE, "family's meal removes Nestor readiness without completing his errand")
	fridge.free()
	fridge = _fresh_fridge([0, 1, 2])
	task = fridge.get_node("Area3D") as TaskObject
	task._complete_task()
	InventoryManager.remove_item_by_id("whole_chicken")
	await _wait_until(func(): return not task._is_completing, "available option is rechecked after fade")
	_check(NeedsLog.is_resolved(NeedsLog.Need.FOOD) and _quantities() == [0, 0, 0], "two remaining halves can replace removed whole chicken")
	fridge.free()


func _test_text() -> void:
	var fridge := _fresh_fridge([0, 0, 0])
	var task := fridge.get_node("Area3D") as TaskObject
	for language in ["english", "tagalog"]:
		LocalizationManager.set_language(language)
		var line := LocalizationManager.translate(task.missing_lines[0])
		_check(line.contains("[b]") and ("four cans" in line if language == "english" else "apat na de lata" in line), "fridge asks for four cans in " + language)
		_check(not line.to_lower().contains("chicken") and not line.to_lower().contains("manok"), "fridge does not advertise chicken in " + language)
		var hint: String = ChecklistPanel._ITEMS[2][1]
		var translated := LocalizationManager.translate(hint)
		_check(translated == ("4 cans" if language == "english" else "4 na de lata"), "checklist keeps cans as the main food need in " + language)
	LocalizationManager.set_language("english")
	fridge.free()


func _test_ready_dialogue() -> void:
	for language in ["english", "tagalog"]:
		LocalizationManager.set_language(language)
		for counts in [[4, 1, 2], [0, 1, 0], [0, 0, 2], [3, 0, 1]]:
			var fridge := _fresh_fridge(counts)
			var task := fridge.get_node("Area3D") as TaskObject
			task._begin_dialogue()
			var chicken_selected: bool = counts[0] < 4 and (counts[1] >= 1 or counts[2] >= 2)
			var line := LocalizationManager.translate(task._ui._source_text)
			var chicken_line := "This will do. There is enough for everyone." if language == "english" else "Puwede na ito. Sapat na para sa lahat."
			_check((line == chicken_line) == chicken_selected, "only a complete selected chicken option gets its own ready line: %s %s" % [language, counts])
			_check(not NeedsLog.is_resolved(NeedsLog.Need.FOOD) and _quantities() == counts, "ready dialogue itself consumes no food")
			task._hide_monologue()
			_check(not GlobalTimer.is_paused, "closing the ready dialogue releases its timer pause")
			fridge.free()
	LocalizationManager.set_language("english")


func _test_deadline() -> void:
	var fridge := _fresh_fridge([0, 1, 0])
	var task := fridge.get_node("Area3D") as TaskObject
	GlobalTimer.current_minutes = 715
	task._complete_task()
	await _wait_until(func(): return get_tree().current_scene != null and get_tree().current_scene.scene_file_path == SceneManager.SCENE_PATHS["ending"], "food task at deadline reaches ending")
	_check(NeedsLog.is_resolved(NeedsLog.Need.FOOD) and _quantities() == [0, 0, 0], "deadline commits chicken consumption and food before ending")
	if get_tree().current_scene != null and get_tree().current_scene.scene_file_path == SceneManager.SCENE_PATHS["ending"]:
		_check(get_tree().current_scene._snapshot["resolved_ids"].has("food"), "ending snapshot includes deadline food preparation")
	fridge.free()
