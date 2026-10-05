class_name MapNodeButton
extends Control

signal node_selected(loc_id: String)

const UI_STYLE = preload("res://game/ui/GameUIStyle.gd")
const BUTTON_SIZE := Vector2(240, 245)
const ICON_SIZE := Vector2(216, 216)
const ICON_Y := 0.0
const ICON_CENTER := Vector2(BUTTON_SIZE.x * 0.5, ICON_Y + ICON_SIZE.y * 0.5)

var _loc_id := ""
var _display_name := ""
var _selected := false
var _hovered := false
var _hover_tween: Tween
var _click_area: Button
var _glow: Panel
var _icon: TextureRect
var _name_label: Label
var _current_label: Label
var _state_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func _build() -> void:
	_glow = Panel.new()
	_glow.position = Vector2(18, 14)
	_glow.size = Vector2(204, 190)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_style := StyleBoxFlat.new()
	glow_style.bg_color = Color(0.35, 0.80, 0.65, 0.08)
	glow_style.border_color = Color(0.35, 0.80, 0.65, 0.7)
	glow_style.set_border_width_all(2)
	glow_style.set_corner_radius_all(20)
	glow_style.shadow_color = Color(0.35, 0.80, 0.65, 0.32)
	glow_style.shadow_size = 8
	_glow.add_theme_stylebox_override("panel", glow_style)
	_glow.modulate.a = 0.0
	add_child(_glow)

	_icon = TextureRect.new()
	_icon.position = Vector2((size.x - ICON_SIZE.x) * 0.5, ICON_Y)
	_icon.size = ICON_SIZE
	_icon.pivot_offset = ICON_SIZE * 0.5
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)

	_name_label = _make_label(202.0, 31.0, 24)
	_name_label.add_theme_font_override("font", UI_STYLE.FONT_HEADING)
	_name_label.add_theme_color_override("font_color", Color(0.14, 0.18, 0.17))
	_name_label.add_theme_color_override("font_outline_color", Color(0.98, 0.94, 0.82, 0.95))
	_name_label.add_theme_constant_override("outline_size", 4)
	add_child(_name_label)

	_current_label = _make_label(-3.0, 27.0, 18)
	_current_label.add_theme_color_override("font_color", UI_STYLE.TEXT)
	_current_label.add_theme_stylebox_override("normal", _badge_style(Color(0.12, 0.30, 0.25, 0.94)))
	_current_label.hide()
	add_child(_current_label)

	_state_label = _make_label(-3.0, 27.0, 18)
	_state_label.add_theme_color_override("font_color", UI_STYLE.TEXT)
	_state_label.hide()
	add_child(_state_label)

	_click_area = Button.new()
	add_child(_click_area)
	_click_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_click_area.flat = true
	_click_area.focus_mode = Control.FOCUS_ALL
	_click_area.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty_style := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "disabled"]:
		_click_area.add_theme_stylebox_override(state, empty_style)
	_click_area.add_theme_stylebox_override("focus", UI_STYLE.GAME_THEME.get_stylebox("focus", "Button"))
	_click_area.mouse_entered.connect(_on_mouse_entered)
	_click_area.mouse_exited.connect(_on_mouse_exited)
	_click_area.focus_entered.connect(_update_emphasis)
	_click_area.focus_exited.connect(_update_emphasis)
	_click_area.pressed.connect(func() -> void: node_selected.emit(_loc_id))


func _make_label(y: float, height: float, font_size: int) -> Label:
	var label := Label.new()
	label.position = Vector2.ZERO + Vector2(0, y)
	label.size = Vector2(size.x, height)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", UI_STYLE.FONT_SEMIBOLD)
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _badge_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(5)
	style.content_margin_left = 6
	style.content_margin_right = 6
	return style


func setup(loc_id: String, display_name: String, icon: Texture2D) -> void:
	_loc_id = loc_id
	_display_name = display_name
	_icon.texture = icon
	refresh("open", false)


func refresh(state: String, is_current: bool) -> void:
	_name_label.text = LocalizationManager.translate(_display_name)
	_current_label.text = LocalizationManager.translate("Nandito ka")
	_current_label.visible = is_current
	var is_closed := state == "closed" or state == "inaccessible"
	_state_label.visible = state == "danger" or is_closed
	_state_label.position.y = 23.0 if is_current else -3.0
	if state == "danger":
		_state_label.text = "⚠ " + LocalizationManager.translate("Danger")
		_state_label.add_theme_stylebox_override("normal", _badge_style(Color(0.44, 0.18, 0.14, 0.95)))
	elif is_closed:
		_state_label.text = LocalizationManager.translate("Closed")
		_state_label.add_theme_stylebox_override("normal", _badge_style(Color(0.20, 0.24, 0.23, 0.95)))
	_click_area.disabled = is_current or is_closed
	_click_area.tooltip_text = _name_label.text
	_icon.modulate = Color(0.80, 0.82, 0.80) if is_closed else Color.WHITE
	_update_emphasis()


func set_selected(selected: bool) -> void:
	_selected = selected
	_update_emphasis()


func _on_mouse_entered() -> void:
	_hovered = true
	_update_emphasis()


func _on_mouse_exited() -> void:
	_hovered = false
	_update_emphasis()


func _update_emphasis() -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	var active := not _click_area.disabled and (_selected or _hovered or _click_area.has_focus())
	_hover_tween = create_tween().set_parallel(true)
	_hover_tween.tween_property(_icon, "position:y", ICON_Y - (5.0 if active else 0.0), 0.16)
	_hover_tween.tween_property(_glow, "modulate:a", 1.0 if active else 0.0, 0.16)
