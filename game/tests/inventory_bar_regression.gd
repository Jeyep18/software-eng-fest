extends Node

var _checks := 0
var _failures := 0

func _ready() -> void:
	_run.call_deferred()

func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("INVENTORY BAR FAIL: " + description)

func _run() -> void:
	if OS.get_environment("BAGYONG_ISOLATED_SMOKE") != OS.get_user_data_dir():
		push_error("Inventory bar regression requires isolated user data.")
		get_tree().quit(1)
		return
	InventoryManager.reset()
	var canned: ItemData = preload("res://game/resources/items/canned_goods.tres")
	InventoryManager.add_item(canned)
	InventoryManager.add_item(canned)
	InventoryManager.add_item(preload("res://game/resources/items/medicine.tres"))
	var hotbar := preload("res://game/ui/inventory/hotbar/HotbarUI.tscn").instantiate()
	var backpack := preload("res://game/ui/inventory/backpack/BackpackUI.tscn").instantiate()
	add_child(hotbar)
	add_child(backpack)
	await _settle()
	var slots: Array = hotbar._slot_panels.duplicate()
	var items := InventoryManager.get_all_items().duplicate()
	var quantities := InventoryManager.item_quantities.duplicate()
	for number in range(1, 9):
		var event := InputEventKey.new()
		event.physical_keycode = KEY_0 + number
		event.keycode = KEY_0 + number
		event.pressed = true
		Input.parse_input_event(event)
		event = event.duplicate()
		event.pressed = false
		Input.parse_input_event(event)
	for direction in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var event := InputEventMouseButton.new()
		event.button_index = direction
		event.pressed = true
		Input.parse_input_event(event)
	await _settle()
	_check(InventoryManager.get_all_items() == items and InventoryManager.item_quantities == quantities, "wheel and number keys preserve all items, order and quantities")
	_check(not backpack.visible and hotbar._slot_panels == slots, "wheel and number keys neither open the bag nor rebuild slots")
	_check(not hotbar.has_method("_select_slot") and not hotbar.has_method("get_selected_item"), "preview has no item-selection API")
	_check(slots.size() == 7, "preview retains all seven inventory slots")
	for slot in slots:
		_check(slot.get_theme_stylebox("panel") == hotbar._normal_style, "every slot uses the same passive style")
		_check(slot.mouse_filter == Control.MOUSE_FILTER_IGNORE, "preview slots do not intercept input")
	_check(slots[0].get_child_count() == 3 and slots[2].get_child_count() == 0, "occupied slot retains icon/name/quantity while empty slot has no key badge")
	hotbar._redraw_hotbar()
	await _settle()
	_check(hotbar._slot_panels == slots and slots[0].get_child_count() == 3, "unchanged redraw reuses cached slot contents")
	_tab()
	await get_tree().create_timer(0.25).timeout
	_check(backpack.visible and CursorState.is_requesting_visible(backpack), "physical Tab opens the real backpack")
	_tab()
	await get_tree().create_timer(0.25).timeout
	_check(not backpack.visible and not CursorState.is_requesting_visible(backpack), "physical Tab closes the real backpack")
	for language in ["english", "tagalog"]:
		LocalizationManager.set_language(language)
		for scale_percent in [100, 140, 175]:
			VisualSettings.set_ui_scale_percent(scale_percent)
			await _settle()
			var hint: Control = hotbar.inventory_hint
			_check(hotbar.tab_label.text == "Tab" and hotbar.hint_label.text == ("Open inventory" if language == "english" else "Buksan ang imbentaryo"), "hint matches " + language)
			_check(get_viewport().get_visible_rect().encloses(hotbar.hotbar_root.get_global_rect()), "full bar fits at %s %d%%" % [language, scale_percent])
			_check(hint.get_global_rect().encloses(hotbar.hint_label.get_global_rect()) and hint.size.y >= hint.get_combined_minimum_size().y, "translated instruction fits at %s %d%%" % [language, scale_percent])
			_check(hint.get_global_rect().position.x >= hotbar.slot_container.get_global_rect().end.x, "hint stays beside the slots")
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("user://inventory_bar_%s_%d.png" % [language, scale_percent])
	hotbar.set_hotbar_visible(false)
	_check(not hotbar.visible, "dialogue visibility hook hides preview and hint together")
	hotbar.set_hotbar_visible(true)
	_check(hotbar.visible, "dialogue visibility hook restores preview and hint together")
	print("Inventory bar regression: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)

func _tab() -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_TAB
	event.keycode = KEY_TAB
	event.pressed = true
	Input.parse_input_event(event)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)

func _settle() -> void:
	for frame in range(3):
		await get_tree().process_frame
