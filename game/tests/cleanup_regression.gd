extends Node
## Run with --headless --path <project> --scene res://game/tests/cleanup_regression.tscn
## after importing a disposable project copy. A scene loads after autoloads are ready.
## Uses only session state. Does not save settings or leaderboard scores.

var _inventory: Node
var _quests: Node
var _needs: Node
var _events: Array[String] = []
var _checks: int = 0
var _failures: int = 0

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	_inventory = get_node("/root/InventoryManager")
	_quests = get_node("/root/SideQuestLog")
	_needs = get_node("/root/NeedsLog")
	_inventory.inventory_changed.connect(func() -> void: _events.append("inventory"))
	_inventory.item_combined.connect(func(item: ItemData) -> void: _events.append(item.item_id))
	_inventory.discard_changed.connect(func() -> void: _events.append("discard"))
	_test_invalid_mutations()
	_test_recipes()
	_test_stacking_and_discard()
	await _test_hotbar()
	_test_task_requirements()
	_test_windows()
	_test_quest_readiness()
	print("Cleanup regression: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)

func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: " + description)

func _item(id: String) -> ItemData:
	var item := ItemData.new()
	item.item_id = id
	item.item_name = id
	return item

func _reset_inventory() -> void:
	_inventory.reset()
	_events.clear()

func _snapshot() -> Array:
	return [_inventory.inventory.duplicate(), _inventory.item_quantities.duplicate(),
		_inventory.discard_held_item, _inventory.discard_held_quantity]

func _test_invalid_mutations() -> void:
	_reset_inventory()
	_check(not _inventory.add_item(null), "null item rejected")
	_check(_inventory.inventory.is_empty() and _inventory.item_quantities.is_empty(), "null add leaves empty arrays")
	_check(_events.is_empty(), "null add emits no signals")
	_inventory.add_item(_item("batteries"))
	_inventory.add_item(_item("dead_flashlight"))
	_inventory.add_item(_item("canned_goods"))
	_inventory.add_item(_item("canned_goods"))
	var before := _snapshot()
	_events.clear()
	_check(not _inventory.add_item(null), "null item rejected with existing inventory")
	_check(_snapshot() == before and _events.is_empty(), "null add preserves populated inventory")
	var result := _item("working_flashlight")
	var cases: Array = [
		[-1, 1, result], [0, -1, result], [3, 1, result], [0, 3, result],
		[0, 0, result], [0, 2, result], [0, 1, null], [0, 1, _item("working_radio")],
	]
	for i in range(cases.size()):
		var test: Array = cases[i]
		_check(not _inventory.combine_items(test[0], test[1], test[2]), "invalid combine %d rejected" % i)
		_check(_snapshot() == before, "invalid combine %d leaves all state unchanged" % i)
		_check(_events.is_empty(), "invalid combine %d emits no signals" % i)

func _test_recipes() -> void:
	for recipe in [["dead_flashlight", "working_flashlight"], ["broken_radio", "working_radio"]]:
		for reverse in [false, true]:
			_reset_inventory()
			_inventory.add_item(_item("canned_goods"))
			_inventory.add_item(_item("canned_goods"))
			_inventory.add_item(_item("batteries"))
			_inventory.add_item(_item(recipe[0]))
			var first: int = 2 if reverse else 1
			var second: int = 1 if reverse else 2
			_check(_inventory.get_combine_result(first, second) == recipe[1], "recipe lookup in either order")
			_events.clear()
			var result := _item(recipe[1])
			_check(_inventory.combine_items(first, second, result), "valid recipe succeeds in either order")
			_check(_inventory.inventory.size() == 2 and _inventory.inventory[1] == result, "recipe appends supplied result")
			_check(_inventory.item_quantities == [2, 1], "recipe preserves unrelated stack and gives one result")
			_check(_events == ["inventory", "inventory", "inventory", recipe[1]], "combine preserves success signal order")

func _test_stacking_and_discard() -> void:
	_reset_inventory()
	_inventory.add_item(_item("canned_goods"))
	_inventory.add_item(_item("nails"))
	for i in range(5):
		_inventory.add_item(_item("filler_%d" % i))
	_check(_inventory.is_full(), "seven slots fill inventory")
	_check(_inventory.add_item(_item("canned_goods")) and _inventory.add_item(_item("nails")), "both existing stacks accept items at capacity")
	var before := _snapshot()
	_events.clear()
	_check(not _inventory.add_item(_item("overflow")), "nonstacking item rejected at capacity")
	_check(_snapshot() == before and _events.is_empty(), "full rejection leaves state and signals unchanged")
	_check(_inventory.move_item_to_discard(0), "whole stack moves to discard")
	_check(_inventory.discard_held_quantity == 2 and _inventory.discard_held_item.item_id == "canned_goods", "discard retains stack quantity")
	_check(_events == ["inventory", "discard"], "discard notification order preserved")
	_inventory.add_item(_item("replacement"))
	before = _snapshot()
	_events.clear()
	_check(not _inventory.restore_discard_item(), "restore rejected while inventory full")
	_check(_snapshot() == before and _events.is_empty(), "failed restore preserves discard")
	_inventory.remove_item(5)
	_check(_inventory.restore_discard_item(), "restore succeeds after slot freed")
	_check(_inventory.get_total_quantity("canned_goods") == 2 and _inventory.discard_held_item == null, "restore returns complete stack")

func _test_hotbar() -> void:
	_reset_inventory()
	var hotbar = load("res://game/ui/HotbarUI/HotbarUI.tscn").instantiate()
	add_child(hotbar)
	_check(hotbar.slot_container.get_child_count() == 7, "real hotbar builds seven slots")
	for key in range(1, 9):
		var event := InputEventAction.new()
		event.action = "hotbar_slot_%d" % key
		event.pressed = true
		hotbar._unhandled_input(event)
		_check(hotbar.selected_slot == mini(key - 1, 6), "hotbar key %d selection" % key)
	for direction in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_UP]:
		hotbar._select_slot(6 if direction == MOUSE_BUTTON_WHEEL_DOWN else 0)
		var event := InputEventMouseButton.new()
		event.button_index = direction
		event.pressed = true
		hotbar._unhandled_input(event)
		_check(hotbar.selected_slot == (0 if direction == MOUSE_BUTTON_WHEEL_DOWN else 6), "wheel wraps across boundary")
		for i in range(7):
			hotbar._unhandled_input(event)
		_check(hotbar.selected_slot == (0 if direction == MOUSE_BUTTON_WHEEL_DOWN else 6), "wheel completes seven-slot cycle")
	# Let node-added localization finish before freeing the scene under test.
	await get_tree().process_frame
	hotbar.queue_free()
	await get_tree().process_frame

func _test_task_requirements() -> void:
	_reset_inventory()
	var task := TaskObject.new()
	task.required_item_ids.assign(["canned_goods", "canned_goods", "canned_goods", "canned_goods"])
	for i in range(3):
		_inventory.add_item(_item("canned_goods"))
	_check(not task._has_all_required_items(), "three cans do not satisfy four-can requirement")
	_inventory.add_item(_item("canned_goods"))
	_check(task._has_all_required_items(), "four cans satisfy repeated requirement")
	_inventory.add_item(_item("canned_goods"))
	task._consume_required_items()
	_check(_inventory.get_total_quantity("canned_goods") == 1, "task consumes exactly four cans")
	task.required_item_ids.assign(["hammer", "wrench"])
	_check(not task._has_all_required_items(), "changed exported requirements recomputed")
	_inventory.add_item(load("res://game/resources/items/hammer.tres"))
	_inventory.add_item(load("res://game/resources/items/wrench.tres"))
	_check(task._has_all_required_items(), "authored hammer and wrench meet requirement")
	task._consume_required_items()
	_check(_inventory.get_total_quantity("hammer") == 1, "authored hammer tool retained")
	_check(_inventory.get_total_quantity("wrench") == 0, "authored default-type wrench consumed as before")
	task.free()

func _test_windows() -> void:
	_needs.reset()
	var window_script = load("res://game/objects/interactables/WindowTask.gd")
	for id in ["bedroom_window", "living_room_window"]:
		var window = window_script.new()
		window.window_id = id
		window.need = _needs.Need.WINDOWS
		window.time_cost_minutes = 0
		window._apply_completion_state()
		_check(_needs.is_window_boarded(id), "window completion tracks " + id)
		var count: int = _needs.boarded_window_count()
		window._apply_completion_state()
		_check(_needs.boarded_window_count() == count, "repeat window completion is idempotent")
		window._sync_completion_state()
		_check(window._is_completed, "window completion restored on revisit")
		_check(_needs.is_resolved(_needs.Need.WINDOWS) == (count == 2), "windows resolve only after both IDs")
		window.free()

func _test_quest_readiness() -> void:
	_reset_inventory()
	_quests.reset()
	var id: String = _quests.QUEST_MANG_NESTOR_CHICKEN
	_quests.start_mang_nestor_chicken()
	_check(_quests.get_quest_state(id) == _quests.STATE_ACTIVE, "accepted quest active")
	_inventory.add_item(_item("half_chicken"))
	_check(_quests.get_quest_state(id) == _quests.STATE_READY_TO_TURN_IN, "inventory signal alone makes quest ready")
	_inventory.remove_item_by_id("half_chicken")
	_check(_quests.get_quest_state(id) == _quests.STATE_ACTIVE, "removing chicken clears readiness")
	_inventory.add_item(_item("half_chicken"))
	_quests.complete_mang_nestor_chicken()
	_inventory.remove_item_by_id("half_chicken")
	_quests.refresh_mang_nestor_chicken()
	_quests.start_mang_nestor_chicken()
	_check(_quests.get_quest_state(id) == _quests.STATE_COMPLETED, "completed quest stays completed after removal and revisit")
