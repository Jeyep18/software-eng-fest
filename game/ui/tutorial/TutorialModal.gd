class_name TutorialModal
extends CanvasLayer

signal closed

const UI_STYLE = preload("res://game/ui/GameUIStyle.gd")

static var _hidden_for_session: bool = false

var _previous_paused: bool = false
var _pause_game: bool = false
var _capture_mouse_on_close: bool = false
var _on_close: Callable = Callable()
var _do_not_show_button: Button

func _ready() -> void:
	layer = 80
	hide()
	_build_ui()

func open(show_do_not_show: bool = false, pause_game: bool = true, on_close: Callable = Callable(), capture_mouse_on_close: bool = false) -> void:
	_pause_game = pause_game
	_capture_mouse_on_close = capture_mouse_on_close
	_on_close = on_close
	_previous_paused = get_tree().paused
	if pause_game:
		get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_do_not_show_button.visible = show_do_not_show
	show()
	_grab_continue_focus()

func close() -> void:
	hide()
	if _pause_game:
		get_tree().paused = _previous_paused
	if _capture_mouse_on_close and not get_tree().paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	closed.emit()
	if _on_close.is_valid():
		_on_close.call()

static func should_show_on_start() -> bool:
	return not _hidden_for_session

static func mark_do_not_show_again() -> void:
	_hidden_for_session = true

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _on_do_not_show_pressed() -> void:
	mark_do_not_show_again()
	close()

func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.02, 0.025, 0.03, 0.82)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(980, 760)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -490
	panel.offset_top = -380
	panel.offset_right = 490
	panel.offset_bottom = 380
	UI_STYLE.apply_panel(panel)
	root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "Tutorial and Controls"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	UI_STYLE.apply_label(title, false, true)
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Prepare your home before the storm arrives. Watch your time, money, and checklist."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	UI_STYLE.apply_label(subtitle, true)
	layout.add_child(subtitle)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)

	_add_section(content, "Move and Interact", [
		"WASD: move around. Shift: sprint.",
		"E: interact with people, doors, shops, and task spots.",
		"Space: continue dialogue when someone is speaking.",
		"Esc: pause the game. M: open the travel map. Tab: open your backpack."
	])
	_add_section(content, "Your Goal", [
		"Talk to family members, check the house, and complete the preparation checklist.",
		"Buy or collect important supplies before the storm closes locations.",
		"Some choices compete for limited time and money, so prioritize what matters most."
	])
	_add_section(content, "Items and Combining", [
		"Open the backpack, click an item to inspect it, then click a second item to try combining them.",
		"When a valid result appears, press Combine. Examples include putting batteries with a flashlight or radio.",
		"Drag unwanted items to the discard area only when you are sure you do not need them."
	])
	_add_image_card(
		content,
		"res://game/assets/tutorial/combine_items_example.png",
		"Combining items shows the result before you commit."
	)
	_add_section(content, "Tasks and Shops", [
		"Task spots tell you what they need, such as food, water, medicine, plywood, or working equipment.",
		"Look for glowing indicators around the house. They mark where preparation tasks can be completed.",
		"Stand near a task spot and press E. If you have the required item, the task can be completed.",
		"At shops, use cash from Nanay to buy supplies. Your cash and checklist stay visible during preparation."
	])
	_add_image_card(
		content,
		"res://game/assets/tutorial/task_indicator_example.png",
		"Glowing task indicators show where an item should go."
	)
	_add_section(content, "Storm and Travel", [
		"The map lets you travel to stores and return home, but travel costs time.",
		"As the storm worsens, some places become dangerous or close completely.",
		"Return home and finish the most important preparations before time runs out.",
		"If you feel confident, finished all the tasks, or want to give up early, use End the Day on the map to let the storm arrive."
	])

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 12)
	layout.add_child(footer)

	_do_not_show_button = Button.new()
	_do_not_show_button.text = "Do not show again"
	_do_not_show_button.custom_minimum_size = Vector2(180, 44)
	_do_not_show_button.pressed.connect(_on_do_not_show_pressed)
	UI_STYLE.apply_button(_do_not_show_button)
	footer.add_child(_do_not_show_button)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)

	var close_button := Button.new()
	close_button.name = "ContinueButton"
	close_button.text = "Continue"
	close_button.custom_minimum_size = Vector2(140, 44)
	close_button.pressed.connect(close)
	UI_STYLE.apply_button(close_button)
	footer.add_child(close_button)

func _add_section(parent: VBoxContainer, heading: String, lines: Array[String]) -> void:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UI_STYLE.panel_style(UI_STYLE.SECTION_BG, UI_STYLE.BORDER_SOFT, 6))
	parent.add_child(box)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	box.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 5)
	margin.add_child(layout)

	var title := Label.new()
	title.text = heading
	title.add_theme_font_size_override("font_size", 22)
	UI_STYLE.apply_label(title, false, true)
	layout.add_child(title)

	for line in lines:
		var label := Label.new()
		label.text = "- " + line
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 17)
		UI_STYLE.apply_label(label)
		layout.add_child(label)

func _add_image_card(parent: VBoxContainer, image_path: String, caption: String) -> void:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UI_STYLE.panel_style(Color(1, 1, 1, 0.035), UI_STYLE.BORDER_SOFT, 6))
	parent.add_child(box)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	box.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	var image := TextureRect.new()
	image.texture = load(image_path)
	image.custom_minimum_size = Vector2(0, 360)
	image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layout.add_child(image)

	var label := Label.new()
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)
	UI_STYLE.apply_label(label, true)
	layout.add_child(label)

func _grab_continue_focus() -> void:
	var button := get_node_or_null("Root/Panel/MarginContainer/VBoxContainer/HBoxContainer/ContinueButton") as Button
	if button != null:
		button.grab_focus()
