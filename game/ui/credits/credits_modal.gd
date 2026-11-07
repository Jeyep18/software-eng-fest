extends CanvasLayer

const UI_STYLE = preload("res://game/ui/theme/GameUIStyle.gd")
const CONTENT = preload("res://game/ui/credits/credits_content.gd")
const VIEWS := ["Credits", "Licenses", "Privacy", "AI use"]
const LICENSE_TOPICS := ["Project terms", "Asset notices", "Godot Engine", "License texts"]

@onready var _panel: PanelContainer = %Panel
@onready var _margin: MarginContainer = %Margin
@onready var _layout: VBoxContainer = %Layout
@onready var _title: Label = %Title
@onready var _studio: Label = %Studio
@onready var _navigation: HBoxContainer = %Navigation
@onready var _close_button: Button = %Close
@onready var _body: RichTextLabel = %Body
@onready var _license_topic: OptionButton = %LicenseTopic
@onready var _sources: HBoxContainer = %Sources
@onready var _source_select: OptionButton = %SourceSelect
@onready var _open_source_button: Button = %OpenSource

var _source_button: Button
var _tabs: Array[Button] = []
var _view: int = 0

func _ready() -> void:
	UI_STYLE.apply_panel(_panel)
	UI_STYLE.apply_label(_title, false, true)
	UI_STYLE.apply_label(_studio, true)
	for button in [_close_button, _license_topic, _source_select, _open_source_button]:
		UI_STYLE.apply_button(button)
	_body.add_theme_font_override("normal_font", UI_STYLE.FONT_REGULAR)
	_body.add_theme_font_override("bold_font", UI_STYLE.FONT_SEMIBOLD)
	_body.add_theme_color_override("default_color", UI_STYLE.TEXT)
	_body.add_theme_stylebox_override("focus", UI_STYLE.GAME_THEME.get_stylebox("focus", "Button"))
	_body.meta_clicked.connect(_open_source)
	_body.gui_input.connect(_on_body_input)
	_close_button.pressed.connect(close)
	_open_source_button.pressed.connect(_open_selected_source)
	_license_topic.item_selected.connect(func(_index: int) -> void: _refresh_body())

	var tab_group := ButtonGroup.new()
	for index in VIEWS.size():
		var button := Button.new()
		button.name = "View%d" % index
		button.toggle_mode = true
		button.button_group = tab_group
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select_view.bind(index))
		_navigation.add_child(button)
		UI_STYLE.apply_button(button)
		_tabs.append(button)
	for entry: Array in CONTENT.SOURCE_LINKS:
		_source_select.add_item(entry[0])
	get_viewport().size_changed.connect(_layout_panel)
	VisualSettings.ui_scale_changed.connect(_on_scale_changed)
	LocalizationManager.language_changed.connect(_refresh_text)
	_layout_panel()
	_refresh_text()
	_select_view(0)

func open(source_button: Button) -> void:
	_source_button = source_button
	_select_view(0)
	show()
	_close_button.grab_focus()

func close() -> void:
	hide()
	if is_instance_valid(_source_button):
		_source_button.grab_focus()
	_source_button = null

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()

func _select_view(index: int) -> void:
	_view = index
	for tab_index in _tabs.size():
		var selected := tab_index == index
		_tabs[tab_index].button_pressed = selected
		_tabs[tab_index].add_theme_stylebox_override("normal",
			UI_STYLE.button_style(UI_STYLE.SECTION_BG, UI_STYLE.BORDER) if selected
			else UI_STYLE.GAME_THEME.get_stylebox("normal", "Button"))
	_license_topic.visible = index == 1
	_sources.visible = index == 0 or index == 1
	_refresh_body()
	_update_focus_chain()

func _refresh_text(_language: String = "") -> void:
	for index in _tabs.size():
		_tabs[index].text = LocalizationManager.translate(VIEWS[index])
	_close_button.text = LocalizationManager.translate_key("ui.credits.close", "Close")
	_open_source_button.text = LocalizationManager.translate("Open source page")
	_open_source_button.tooltip_text = LocalizationManager.translate("Opens the selected website in your browser.")
	var previous_topic := maxi(0, _license_topic.selected)
	_license_topic.clear()
	for topic: String in LICENSE_TOPICS:
		_license_topic.add_item(LocalizationManager.translate(topic))
	_license_topic.select(previous_topic)
	_refresh_body()

func _refresh_body() -> void:
	match _view:
		0:
			_body.text = _sections_text(CONTENT.CREDIT_SECTIONS)
		1:
			match _license_topic.selected:
				0:
					_body.text = _notice("PROJECT_LICENSE")
				1:
					_body.text = _read_plain("res://game/legal/THIRD_PARTY_NOTICES.txt")
				2:
					_body.text = _engine_notices()
				3:
					var notices := PackedStringArray()
					for entry: Array in CONTENT.LICENSE_FILES:
						notices.append("[b]%s[/b]\n\n%s" % [entry[0], _read_plain(entry[1])])
					_body.text = "\n\n".join(notices)
		2:
			_body.text = _notice("PRIVACY")
		3:
			_body.text = _notice("AI_DISCLOSURE")
	_body.deselect()
	_body.scroll_to_line(0)

func _sections_text(sections: Array) -> String:
	var paragraphs := PackedStringArray()
	for section: Array in sections:
		var heading := LocalizationManager.translate_key(section[0], section[1])
		paragraphs.append("[color=#77cdb3][b]%s[/b][/color]\n\n%s" % [heading, section[2]])
	return "\n\n\n".join(paragraphs)

func _notice(document: String) -> String:
	var suffix := "_TL" if LocalizationManager.get_language() == "tagalog" else ""
	return _read_plain("res://game/legal/%s%s.txt" % [document, suffix])

func _read_plain(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Credits: could not read " + path)
		return LocalizationManager.translate("This notice could not be loaded.")
	return file.get_as_text().replace("[", "[lb]")

func _engine_notices() -> String:
	var text := "[b]Godot Engine[/b]\n\n" + Engine.get_license_text().replace("[", "[lb]")
	text += "\n\n[b]Third-party components[/b]\n"
	for component: Dictionary in Engine.get_copyright_info():
		text += "\n[b]%s[/b]\n" % component["name"]
		for part: Dictionary in component["parts"]:
			text += "\n".join(PackedStringArray(part["copyright"])).replace("[", "[lb]")
			text += "\n" + str(part["license"]) + "\n"
	var license_texts := Engine.get_license_info()
	for license_name: String in license_texts:
		text += "\n[b]%s[/b]\n%s\n" % [license_name, str(license_texts[license_name]).replace("[", "[lb]")]
	return text

func _layout_panel() -> void:
	var scale_factor := VisualSettings.get_ui_scale()
	var panel_size := (Vector2(960, 700) * scale_factor).min(get_viewport().get_visible_rect().size - Vector2(64, 64))
	_panel.offset_left = -panel_size.x * 0.5
	_panel.offset_top = -panel_size.y * 0.5
	_panel.offset_right = panel_size.x * 0.5
	_panel.offset_bottom = panel_size.y * 0.5
	for side in ["left", "top", "right", "bottom"]:
		_margin.add_theme_constant_override("margin_" + side, roundi(24 * scale_factor))
	_layout.add_theme_constant_override("separation", roundi(12 * scale_factor))
	_navigation.add_theme_constant_override("separation", roundi(8 * scale_factor))
	_sources.add_theme_constant_override("separation", roundi(12 * scale_factor))
	_title.add_theme_font_size_override("font_size", roundi(34 * scale_factor))
	_studio.add_theme_font_size_override("font_size", roundi(14 * scale_factor))
	for button in [_close_button, _license_topic, _source_select, _open_source_button] + _tabs:
		button.add_theme_font_size_override("font_size", roundi(16 * scale_factor))
		button.custom_minimum_size.y = 36 * scale_factor
	_body.add_theme_font_size_override("normal_font_size", roundi(18 * scale_factor))
	_body.add_theme_font_size_override("bold_font_size", roundi(19 * scale_factor))
	_body.add_theme_constant_override("line_separation", roundi(6 * scale_factor))
	var alphabet_width := UI_STYLE.FONT_REGULAR.get_string_size("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz", HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(18 * scale_factor)).x
	_body.custom_minimum_size.x = minf(alphabet_width / 52.0 * 65.0, panel_size.x - 48 * scale_factor)

func _on_scale_changed(_scale: float) -> void:
	_layout_panel()

func _update_focus_chain() -> void:
	var controls: Array[Control] = [_close_button]
	controls.append_array(_tabs)
	if _license_topic.visible:
		controls.append(_license_topic)
	controls.append(_body)
	if _sources.visible:
		controls.append_array([_source_select, _open_source_button])
	for index in controls.size():
		var control := controls[index]
		control.focus_next = control.get_path_to(controls[(index + 1) % controls.size()])
		control.focus_previous = control.get_path_to(controls[(index - 1 + controls.size()) % controls.size()])
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			control.set_focus_neighbor(side, NodePath("."))
	for index in _tabs.size():
		_tabs[index].focus_neighbor_left = _tabs[index].get_path_to(_tabs[(index - 1 + _tabs.size()) % _tabs.size()])
		_tabs[index].focus_neighbor_right = _tabs[index].get_path_to(_tabs[(index + 1) % _tabs.size()])

func _on_body_input(event: InputEvent) -> void:
	var scroll := _body.get_v_scroll_bar()
	if event.is_action_pressed("ui_up", true):
		scroll.value -= _body.get_theme_font_size("normal_font_size")
	elif event.is_action_pressed("ui_down", true):
		scroll.value += _body.get_theme_font_size("normal_font_size")
	elif event.is_action_pressed("ui_page_up", true):
		scroll.value -= scroll.page
	elif event.is_action_pressed("ui_page_down", true):
		scroll.value += scroll.page
	elif event.is_action_pressed("ui_home"):
		scroll.value = 0
	elif event.is_action_pressed("ui_end"):
		scroll.value = scroll.max_value
	else:
		return
	_body.accept_event()

func _open_selected_source() -> void:
	_open_source(CONTENT.SOURCE_LINKS[_source_select.selected][1])

func _open_source(meta: Variant) -> void:
	var url := str(meta)
	if url.begins_with("https://"):
		OS.shell_open(url)
