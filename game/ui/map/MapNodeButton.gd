# MapNodeButton.gd
class_name MapNodeButton
extends Control

signal node_selected(loc_id: String)

# ── Theme ─────────────────────────────────────────────────────────────────────
const COLOR_OPEN:    Color = Color(0.468, 0.468, 0.48, 1.0)
const COLOR_DANGER:  Color = Color(0.80, 0.45, 0.10)
const COLOR_CLOSED:  Color = Color(0.40, 0.15, 0.15)
const COLOR_CURRENT: Color = Color(0.20, 0.40, 0.70)

# ── Children ──────────────────────────────────────────────────────────────────
var _background:   Panel
var _icon_rect:    TextureRect
var _name_label:   Label
var _time_label:   Label
var _click_area:   Button

var _loc_id:       String = ""
var _current_state: String = "open"

# ── Build ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build()

func _build() -> void:
	# Root panel (colored background)
	_background = Panel.new()
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vbox)
	
	# IMPORTANT: Ensure the VBox doesn't squash the icon
	_icon_rect = TextureRect.new()
	_icon_rect.custom_minimum_size = Vector2(48, 48)
	_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE # Change this for better scaling
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Do not hide() by default if you want to see them immediately
	vbox.add_child(_icon_rect)
	
	# Location name
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 14)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_label.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_name_label)

	# Travel time
	_time_label = Label.new()
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_time_label.add_theme_font_size_override("font_size", 14)
	_time_label.modulate     = Color(1, 1, 1, 0.65)
	_time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_time_label)
	
	vbox.add_theme_constant_override("separation", 5)
	
	# Invisible button stretched over the whole node — captures clicks cleanly
	_click_area = Button.new()
	_click_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_click_area.flat           = true
	_click_area.focus_mode     = Control.FOCUS_NONE
	# Make button visually transparent — styling done by _background Panel
	_click_area.add_theme_color_override("font_color",          Color(0, 0, 0, 0))
	_click_area.add_theme_color_override("font_hover_color",    Color(0, 0, 0, 0))
	_click_area.add_theme_color_override("font_pressed_color",  Color(0, 0, 0, 0))
	_click_area.pressed.connect(_on_pressed)
	add_child(_click_area)

# ── Public API ────────────────────────────────────────────────────────────────
func setup(
		loc_id:       String,
		display_name: String,
		icon:         Texture2D = null) -> void:
	_loc_id       = loc_id
	_name_label.text = display_name

	if icon != null:
		_icon_rect.texture = icon
		_icon_rect.show()
	else:
		_icon_rect.hide()

	_apply_state("open")

func refresh(state: String, travel_label: String) -> void:
	_time_label.text = travel_label
	_apply_state(state)

# ── Internals ─────────────────────────────────────────────────────────────────
func _apply_state(state: String) -> void:
	_current_state = state
	var col: Color
	match state:
		"current": col = COLOR_CURRENT
		"danger":  col = COLOR_DANGER
		"closed":  col = COLOR_CLOSED
		_:         col = COLOR_OPEN   # "open"

	# Tint the panel background
	var style := StyleBoxFlat.new()
	style.bg_color      = col
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	_background.add_theme_stylebox_override("panel", style)

	# Dim closed nodes entirely
	modulate             = Color(1, 1, 1, 0.40) if state == "closed" else Color.WHITE
	_click_area.disabled = (state == "closed" or state == "current")

	# Danger nodes pulse slightly — simple modulate animation
	if state == "danger":
		_time_label.text = "⚠ " + _time_label.text

func _on_pressed() -> void:
	node_selected.emit(_loc_id)
