extends CanvasLayer

const UI_STYLE = preload("res://game/ui/theme/GameUIStyle.gd")
const CONTENT = preload("res://game/ui/credits/credits_content.gd")
const VIEWS := ["Credits", "Licenses", "Privacy", "AI use"]

@onready var _panel: PanelContainer = %Panel
@onready var _margin: MarginContainer = %Margin
@onready var _layout: VBoxContainer = %Layout
@onready var _title: Label = %Title
@onready var _studio: Label = %Studio
@onready var _navigation: HBoxContainer = %Navigation
@onready var _close_button: Button = %Close
@onready var _body: RichTextLabel = %Body
@onready var _reader: PanelContainer = %Reader
@onready var _scroll: ScrollContainer = %Scroll
@onready var _reading_margin: MarginContainer = %ReadingMargin
@onready var _document: VBoxContainer = %Document
@onready var _sources: VBoxContainer = %Sources
@onready var _source_heading: Label = %SourceHeading

var _source_button: Button
var _source_links: Array[LinkButton] = []
var _tabs: Array[Button] = []
var _view: int = 0

func _ready() -> void:
	UI_STYLE.apply_panel(_panel)
	UI_STYLE.apply_label(_title, false, true)
	UI_STYLE.apply_label(_studio, true)
	var reader_style := UI_STYLE.panel_style(Color(0.025, 0.028, 0.03, 0.98))
	reader_style.set_border_width_all(2)
	var reader_focus := reader_style.duplicate() as StyleBoxFlat
	reader_focus.border_color = (UI_STYLE.GAME_THEME.get_stylebox("focus", "Button") as StyleBoxFlat).border_color
	_reader.add_theme_stylebox_override("panel", reader_style)
	_scroll.focus_entered.connect(func(): _reader.add_theme_stylebox_override("panel", reader_focus))
	_scroll.focus_exited.connect(func(): _reader.add_theme_stylebox_override("panel", reader_style))
	UI_STYLE.apply_secondary_button(_close_button)
	UI_STYLE.apply_label(_source_heading)
	_source_heading.add_theme_font_override("font", UI_STYLE.FONT_SEMIBOLD)
	_body.add_theme_font_override("normal_font", UI_STYLE.FONT_REGULAR)
	_body.add_theme_font_override("bold_font", UI_STYLE.FONT_SEMIBOLD)
	_body.add_theme_color_override("default_color", UI_STYLE.TEXT)
	_body.meta_clicked.connect(_open_source)
	_scroll.gui_input.connect(_on_body_input)
	_close_button.pressed.connect(close)

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
		var link := LinkButton.new()
		link.text = entry[0]
		link.tooltip_text = entry[1]
		link.focus_mode = Control.FOCUS_ALL
		link.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		link.add_theme_font_override("font", UI_STYLE.FONT_REGULAR)
		link.add_theme_color_override("font_color", UI_STYLE.ACCENT)
		link.add_theme_stylebox_override("focus", UI_STYLE.GAME_THEME.get_stylebox("focus", "Button"))
		link.pressed.connect(_open_source.bind(entry[1]))
		link.gui_input.connect(_on_body_input)
		_sources.add_child(link)
		_source_links.append(link)
	get_viewport().size_changed.connect(_on_scale_changed)
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
	_sources.visible = index == 0 or index == 1
	_refresh_body()
	_update_focus_chain()

func _refresh_text(_language: String = "") -> void:
	for index in _tabs.size():
		_tabs[index].text = LocalizationManager.translate(VIEWS[index])
	_close_button.text = LocalizationManager.translate_key("ui.credits.close", "Close")
	_source_heading.text = LocalizationManager.translate_key("ui.credits.sources", "Sources")
	_refresh_body()

func _refresh_body() -> void:
	match _view:
		0:
			_body.text = _sections_text(CONTENT.CREDIT_SECTIONS)
		1:
			var notices := PackedStringArray([
				_heading(LocalizationManager.translate("Project terms")) + _notice("PROJECT_LICENSE"),
				_heading(LocalizationManager.translate("Asset notices")) + _read_plain("res://game/legal/THIRD_PARTY_NOTICES.txt"),
				_engine_notices(),
			])
			for entry: Array in CONTENT.LICENSE_FILES:
				notices.append(_heading(entry[0]) + _read_plain(entry[1]))
			_body.text = "\n\n\n".join(notices)
		2:
			_body.text = _notice("PRIVACY")
		3:
			_body.text = _notice("AI_DISCLOSURE")
	_body.deselect()
	_scroll.set_deferred("scroll_vertical", 0)

func _heading(text: String) -> String:
	return "[font_size=%d][color=#77cdb3][b]%s[/b][/color][/font_size]\n\n" % [roundi(24.0 * _layout_scale()), text]

func _sections_text(sections: Array) -> String:
	var paragraphs := PackedStringArray()
	for section: Array in sections:
		var heading := LocalizationManager.translate_key(section[0], section[1])
		paragraphs.append(_heading(heading) + section[2])
	return "\n\n\n".join(paragraphs)

func _notice(document: String) -> String:
	var suffix := "_TL" if LocalizationManager.get_language() == "tagalog" else ""
	return _read_plain("res://game/legal/%s%s.txt" % [document, suffix])

func _read_plain(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Credits: could not read " + path)
		return LocalizationManager.translate("This notice could not be loaded.")
	return _reflow_plain(file.get_as_text()).replace("[", "[lb]")

func _reflow_plain(text: String) -> String:
	var result := PackedStringArray()
	var list_item := RegEx.create_from_string("^([a-zA-Z0-9]+[.)]|[-*])\\s")
	var previous := ""
	for line in text.replace("\r\n", "\n").split("\n"):
		var trimmed := line.strip_edges()
		# Join authored wrap continuations, preserving paragraph and list starts.
		if previous.length() >= 50 and not trimmed.is_empty() and list_item.search(trimmed) == null and not previous.begins_with("http"):
			result[result.size() - 1] += " " + trimmed
		else:
			result.append(line)
		previous = trimmed
	return "\n".join(result)

func _engine_notices() -> String:
	var text := _heading("Godot Engine") + _reflow_plain(Engine.get_license_text()).replace("[", "[lb]")
	text += "\n\n[b]Third-party components[/b]\n"
	for component: Dictionary in Engine.get_copyright_info():
		text += "\n[b]%s[/b]\n" % component["name"]
		for part: Dictionary in component["parts"]:
			text += "\n".join(PackedStringArray(part["copyright"])).replace("[", "[lb]")
			text += "\n" + str(part["license"]) + "\n"
	var license_texts := Engine.get_license_info()
	for license_name: String in license_texts:
		text += "\n[b]%s[/b]\n%s\n" % [license_name, _reflow_plain(str(license_texts[license_name])).replace("[", "[lb]")]
	return text

func _layout_panel() -> void:
	var scale_factor := _layout_scale()
	var panel_size := Vector2(980, 720) * scale_factor
	_panel.offset_left = -panel_size.x * 0.5
	_panel.offset_top = -panel_size.y * 0.5
	_panel.offset_right = panel_size.x * 0.5
	_panel.offset_bottom = panel_size.y * 0.5
	for side in ["left", "top", "right", "bottom"]:
		_margin.add_theme_constant_override("margin_" + side, roundi(24 * scale_factor))
		_reading_margin.add_theme_constant_override("margin_" + side, roundi(24 * scale_factor))
	_layout.add_theme_constant_override("separation", roundi(12 * scale_factor))
	_navigation.add_theme_constant_override("separation", roundi(8 * scale_factor))
	_document.add_theme_constant_override("separation", roundi(24 * scale_factor))
	_sources.add_theme_constant_override("separation", roundi(12 * scale_factor))
	_title.add_theme_font_size_override("font_size", roundi(32 * scale_factor))
	_studio.add_theme_font_size_override("font_size", roundi(16 * scale_factor))
	_source_heading.add_theme_font_size_override("font_size", roundi(24 * scale_factor))
	for button in [_close_button] + _tabs:
		button.add_theme_font_size_override("font_size", roundi(18 * scale_factor))
		button.custom_minimum_size.y = 42 * scale_factor
	for link in _source_links:
		link.add_theme_font_size_override("font_size", roundi(18 * scale_factor))
	_body.add_theme_font_size_override("normal_font_size", roundi(20 * scale_factor))
	_body.add_theme_font_size_override("bold_font_size", roundi(20 * scale_factor))
	_body.add_theme_constant_override("line_separation", roundi(6 * scale_factor))

func _layout_scale() -> float:
	var available := get_viewport().get_visible_rect().size - Vector2(64, 64)
	return minf(VisualSettings.get_ui_scale(), minf(available.x / 980.0, available.y / 720.0))

func _on_scale_changed(_scale: float = 1.0) -> void:
	_layout_panel()
	_refresh_body()

func _update_focus_chain() -> void:
	var controls: Array[Control] = [_close_button]
	controls.append_array(_tabs)
	controls.append(_scroll)
	if _sources.visible:
		controls.append_array(_source_links)
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
	var scroll := _scroll.get_v_scroll_bar()
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
	_scroll.accept_event()

func _open_source(meta: Variant) -> void:
	var url := str(meta)
	if url.begins_with("https://"):
		OS.shell_open(url)
