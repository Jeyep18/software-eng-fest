class_name TutorialModal
extends CanvasLayer

signal closed

const UI_STYLE = preload("res://game/ui/theme/GameUIStyle.gd")
const PAGES: Array[Dictionary] = [
	{
		"id": "before", "title": "Before the storm", "image": "overview",
		"body": "A typhoon is approaching. Help Nanay, Lola and Bunso prepare your home before it arrives.\n\nStore food and water, get Lola's medicine, repair the roof, board both windows, and prepare a working radio and flashlight.",
		"caption": "Prepare the family home before the storm arrives.",
	},
	{
		"id": "inspect", "title": "Inspect the house", "image": "task",
		"body": "WASD: move. Shift: sprint.\n\nPress E near people or glowing task markers to learn what is needed.\n\nPress E or Space to finish a line and continue dialogue.",
		"caption": "Glowing markers identify preparation tasks.",
	},
	{
		"id": "shop", "title": "Buy supplies", "image": "map",
		"body": "Press M to open the map and choose a destination. Travel uses time.\n\nSpend carefully. Shops can become dangerous or close as the storm worsens.\n\nThe clock keeps running while the map or inventory is open.",
		"caption": "Check travel time and shop availability before leaving.",
	},
	{
		"id": "bag", "title": "Use your inventory", "image": "combine",
		"body": "Press Tab to open or close your seven-slot inventory.\n\nClick an item, then a compatible second item. Check the result and press Combine.\n\nTry batteries with a flashlight or radio.",
		"caption": "The combination preview shows what you will make.",
	},
	{
		"id": "finish", "title": "Finish preparations", "image": "finish",
		"body": "Return home with supplies and press E at each task. Check the preparation checklist.\n\nFood needs 4 cans, 1 whole chicken, or 2 half chickens.\n\nThe storm arrives when time runs out. Ready early? Choose End the Day on the map.",
		"caption": "Completed tasks leave the active objectives.",
	},
]

static var _hidden_for_session: bool = false

var _page_index := 0
var _is_open := false
var _previous_paused := false
var _pause_game := false
var _on_close: Callable
var _previous_focus: Control
var _panel: PanelContainer
var _margin: MarginContainer
var _layout: VBoxContainer
var _heading: Label
var _title: Label
var _counter: Label
var _body_row: HBoxContainer
var _image_column: VBoxContainer
var _image: TextureRect
var _caption: Label
var _body: Label
var _hint: Label
var _footer: HBoxContainer
var _do_not_show_button: Button
var _back_button: Button
var _next_button: Button

func _ready() -> void:
	layer = 80
	add_to_group("tutorial_modal")
	hide()
	_build_ui()
	LocalizationManager.language_changed.connect(_on_language_changed)
	VisualSettings.ui_scale_changed.connect(_on_ui_scale_changed)
	get_viewport().size_changed.connect(_apply_layout)
	_refresh_page()

func open(show_do_not_show: bool = false, pause_game: bool = true, on_close: Callable = Callable(), capture_mouse_on_close: bool = false) -> void:
	if _is_open:
		return
	_is_open = true
	_pause_game = pause_game
	_on_close = on_close
	_previous_paused = get_tree().paused
	_previous_focus = get_viewport().gui_get_focus_owner()
	if pause_game:
		get_tree().paused = true
	CursorState.request_visible(self)
	_page_index = 0
	_do_not_show_button.visible = show_do_not_show
	show()
	_refresh_page()
	_next_button.grab_focus()

func close() -> void:
	if not _is_open:
		return
	_release_ownership()
	hide()
	if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
		_previous_focus.grab_focus()
	closed.emit()
	if _on_close.is_valid():
		_on_close.call()

func _exit_tree() -> void:
	_release_ownership()

func _release_ownership() -> void:
	if not _is_open:
		return
	_is_open = false
	if _pause_game:
		get_tree().paused = _previous_paused
	CursorState.release_visible(self)

static func should_show_on_start() -> bool:
	return not _hidden_for_session

static func mark_do_not_show_again() -> void:
	_hidden_for_session = true

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _on_do_not_show_pressed() -> void:
	mark_do_not_show_again()
	close()

func _on_back_pressed() -> void:
	_page_index = maxi(0, _page_index - 1)
	_refresh_page()
	if _back_button.disabled:
		_next_button.grab_focus()

func _on_next_pressed() -> void:
	if _page_index == PAGES.size() - 1:
		close()
		return
	_page_index += 1
	_refresh_page()

func _on_language_changed(_language_id: String) -> void:
	_refresh_page()

func _on_ui_scale_changed(_scale: float) -> void:
	_apply_layout()

func _refresh_page() -> void:
	var page := PAGES[_page_index]
	_heading.text = LocalizationManager.translate_key("tutorial.title", "How to prepare")
	_title.text = LocalizationManager.translate_key("tutorial.%s.title" % page["id"], page["title"])
	_body.text = LocalizationManager.translate_key("tutorial.%s.body" % page["id"], page["body"])
	_caption.text = LocalizationManager.translate_key("tutorial.%s.caption" % page["id"], page["caption"])
	_counter.text = LocalizationManager.trfk("tutorial.page_count", [_page_index + 1, PAGES.size()], "%d / %d")
	_back_button.text = LocalizationManager.translate_key("tutorial.back", "Back")
	_next_button.text = LocalizationManager.translate_key("tutorial.done", "Done") if _page_index == PAGES.size() - 1 else LocalizationManager.translate_key("tutorial.next", "Next")
	_do_not_show_button.text = LocalizationManager.translate_key("tutorial.hide_session", "Do not show again")
	_hint.text = LocalizationManager.translate_key("tutorial.paused", "The game is paused while you read. Esc closes this guide.")
	_back_button.disabled = _page_index == 0
	var image_path := "res://game/assets/tutorial/%s_%s.png" % [page["image"], LocalizationManager.get_language()]
	_image.texture = load(image_path) if ResourceLoader.exists(image_path) else null
	_update_focus_loop()
	_apply_layout()

func _update_focus_loop() -> void:
	var buttons: Array[Control] = []
	for button in [_do_not_show_button, _back_button, _next_button]:
		if button.visible and not button.disabled:
			buttons.append(button)
	for index in buttons.size():
		var button := buttons[index]
		var previous := button.get_path_to(buttons[(index - 1 + buttons.size()) % buttons.size()])
		var next := button.get_path_to(buttons[(index + 1) % buttons.size()])
		button.focus_previous = previous
		button.focus_next = next
		button.focus_neighbor_left = previous
		button.focus_neighbor_right = next
		button.focus_neighbor_top = previous
		button.focus_neighbor_bottom = next

func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.02, 0.025, 0.03, 0.88)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	UI_STYLE.apply_panel(_panel)
	root.add_child(_panel)
	_margin = MarginContainer.new()
	_panel.add_child(_margin)
	_layout = VBoxContainer.new()
	_margin.add_child(_layout)
	_heading = _make_label(_layout, true)
	var header := HBoxContainer.new()
	_layout.add_child(header)
	_title = _make_label(header)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_counter = _make_label(header, true)
	_counter.autowrap_mode = TextServer.AUTOWRAP_OFF
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_body_row = HBoxContainer.new()
	_body_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_layout.add_child(_body_row)
	_image_column = VBoxContainer.new()
	_image_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_image_column.size_flags_stretch_ratio = 1.05
	_body_row.add_child(_image_column)
	_image = TextureRect.new()
	_image.name = "PageImage"
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_image_column.add_child(_image)
	_caption = _make_label(_image_column, true)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body = _make_label(_body_row)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hint = _make_label(_layout, true)
	_footer = HBoxContainer.new()
	_layout.add_child(_footer)
	_do_not_show_button = _make_button("DoNotShowButton", _on_do_not_show_pressed)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer.add_child(spacer)
	_back_button = _make_button("BackButton", _on_back_pressed)
	_next_button = _make_button("NextButton", _on_next_pressed)

func _make_label(parent: Node, muted: bool = false) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI_STYLE.apply_label(label, muted)
	parent.add_child(label)
	return label

func _make_button(node_name: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.pressed.connect(callback)
	UI_STYLE.apply_button(button)
	_footer.add_child(button)
	return button

func _apply_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	# Bound scaled text as well as the panel so every page fits without scrolling.
	var scale := minf(VisualSettings.get_ui_scale(), viewport_size.y / 640.0)
	var panel_size := (Vector2(1220, 780) * scale).min(viewport_size - Vector2(48, 48))
	_panel.position = (viewport_size - panel_size) * 0.5
	for side in ["left", "right", "top", "bottom"]:
		_margin.add_theme_constant_override("margin_" + side, roundi(24.0 * scale))
	_layout.add_theme_constant_override("separation", roundi(12.0 * scale))
	_body_row.add_theme_constant_override("separation", roundi(28.0 * scale))
	_image_column.add_theme_constant_override("separation", roundi(8.0 * scale))
	_footer.add_theme_constant_override("separation", roundi(12.0 * scale))
	_heading.add_theme_font_size_override("font_size", roundi(17.0 * scale))
	_title.add_theme_font_size_override("font_size", roundi(30.0 * scale))
	_counter.add_theme_font_size_override("font_size", roundi(18.0 * scale))
	_body.add_theme_font_size_override("font_size", roundi(20.0 * scale))
	for label in [_caption, _hint]:
		label.add_theme_font_size_override("font_size", roundi(15.0 * scale))
	for button in [_do_not_show_button, _back_button, _next_button]:
		button.add_theme_font_size_override("font_size", roundi(18.0 * scale))
		button.custom_minimum_size = Vector2(0, 44) * scale
	_panel.set_deferred("size", panel_size)
