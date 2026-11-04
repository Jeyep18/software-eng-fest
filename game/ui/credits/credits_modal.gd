extends CanvasLayer

const UI_STYLE = preload("res://game/ui/theme/GameUIStyle.gd")
const CONTENT = preload("res://game/ui/credits/credits_content.gd")
const ASSET_AUDIT_URL := "https://github.com/Jeyep18/software-eng-fest/blob/dev/docs/audits/2026-11-04-asset-credits.md"

@onready var _panel: PanelContainer = %Panel
@onready var _margin: MarginContainer = %Margin
@onready var _layout: VBoxContainer = %Layout
@onready var _title: Label = %Title
@onready var _close_button: Button = %Close
@onready var _sources_button: Button = %Sources
@onready var _body: RichTextLabel = %Body

var _source_button: Button

func _ready() -> void:
	UI_STYLE.apply_panel(_panel)
	UI_STYLE.apply_label(_title, false, true)
	UI_STYLE.apply_button(_close_button)
	UI_STYLE.apply_button(_sources_button)
	_body.add_theme_font_override("normal_font", UI_STYLE.FONT_REGULAR)
	_body.add_theme_font_override("bold_font", UI_STYLE.FONT_SEMIBOLD)
	_body.add_theme_color_override("default_color", UI_STYLE.TEXT)
	_body.add_theme_stylebox_override("focus", UI_STYLE.GAME_THEME.get_stylebox("focus", "Button"))
	_body.meta_clicked.connect(_open_source)
	_body.gui_input.connect(_on_body_input)
	_close_button.pressed.connect(close)
	_sources_button.pressed.connect(_open_source.bind(ASSET_AUDIT_URL))
	get_viewport().size_changed.connect(_layout_panel)
	VisualSettings.ui_scale_changed.connect(_on_scale_changed)
	LocalizationManager.language_changed.connect(_refresh_text)
	_layout_panel()
	_refresh_text()

func open(source_button: Button) -> void:
	_source_button = source_button
	_show_first_page()
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

func _layout_panel() -> void:
	var scale_factor := VisualSettings.get_ui_scale()
	var panel_size := (Vector2(850, 630) * scale_factor).min(get_viewport().get_visible_rect().size - Vector2(48, 48))
	_panel.offset_left = -panel_size.x * 0.5
	_panel.offset_top = -panel_size.y * 0.5
	_panel.offset_right = panel_size.x * 0.5
	_panel.offset_bottom = panel_size.y * 0.5
	for side in ["left", "top", "right", "bottom"]:
		_margin.add_theme_constant_override("margin_" + side, roundi(18 * scale_factor))
	_layout.add_theme_constant_override("separation", roundi(12 * scale_factor))
	_title.add_theme_font_size_override("font_size", roundi(32 * scale_factor))
	for button in [_close_button, _sources_button]:
		button.add_theme_font_size_override("font_size", roundi(16 * scale_factor))
		button.custom_minimum_size = Vector2(80, 34) * scale_factor
	_body.add_theme_font_size_override("normal_font_size", roundi(17 * scale_factor))
	_body.add_theme_font_size_override("bold_font_size", roundi(18 * scale_factor))
	_body.add_theme_constant_override("line_separation", roundi(4 * scale_factor))

func _on_scale_changed(_scale: float) -> void:
	_layout_panel()

func _refresh_text(_language: String = "") -> void:
	var paragraphs := PackedStringArray()
	for section: Array in CONTENT.SECTIONS:
		var heading := LocalizationManager.translate_key(section[0], section[1])
		paragraphs.append("[color=#77cdb3][b]%s[/b][/color]\n%s" % [heading, section[2]])
	_body.text = "\n\n".join(paragraphs)
	_show_first_page()

func _show_first_page() -> void:
	_body.deselect()
	_body.scroll_to_line(0)

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

func _open_source(meta: Variant) -> void:
	var url := str(meta)
	if url.begins_with("https://"):
		OS.shell_open(url)
