# MapNodeButton.gd
class_name MapNodeButton
extends Control

signal node_selected(loc_id: String)

# ── Children ──────────────────────────────────────────────────────────────────
var _click_area: Button
var _current_label: Label  # The "Nandito ka" indicator

var _loc_id: String = ""

# ── Build ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build()

func _build() -> void:
	# 1. THE INVISIBLE BUTTON (The Hotspot)
	_click_area = Button.new()
	_click_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_click_area.flat = true
	_click_area.focus_mode = Control.FOCUS_NONE
	
	# Force everything to be transparent
	var empty_style = StyleBoxEmpty.new()
	_click_area.add_theme_stylebox_override("normal", empty_style)
	_click_area.add_theme_stylebox_override("hover", empty_style)
	_click_area.add_theme_stylebox_override("pressed", empty_style)
	_click_area.add_theme_stylebox_override("disabled", empty_style)
	_click_area.add_theme_stylebox_override("focus", empty_style)
	
	_click_area.pressed.connect(_on_pressed)
	add_child(_click_area)

	# 2. THE "NANDITO KA" INDICATOR
	_current_label = Label.new()
	_current_label.text = "Nandito ka"
	_current_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_current_label.add_theme_font_size_override("font_size", 18)
	
	# Styling the indicator to look like a small blue tag
	var label_style = StyleBoxFlat.new()
	label_style.bg_color = Color(0.159, 0.13, 0.188, 0.9) # Blue color
	label_style.set_corner_radius_all(4)
	label_style.content_margin_left = 6
	label_style.content_margin_right = 6
	_current_label.add_theme_stylebox_override("normal", label_style)
	
	# Position it at the bottom of the hotspot
	_current_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_current_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_current_label.position.y += 5 # Slight offset below the icon
	
	_current_label.hide() # Hidden by default
	add_child(_current_label)

# ── Public API ────────────────────────────────────────────────────────────────
func setup(loc_id: String, _display_name: String) -> void:
	_loc_id = loc_id
	_apply_state("open")

func refresh(state: String, _travel_label: String) -> void:
	_apply_state(state)

# ── Internals ─────────────────────────────────────────────────────────────────
func _apply_state(state: String) -> void:
	# Show "Nandito ka" only if this is the current location
	if state == "current":
		_current_label.show()
		_click_area.disabled = true # Can't travel to where you already are
	else:
		_current_label.hide()
		_click_area.disabled = (state == "closed")

func _on_pressed() -> void:
	node_selected.emit(_loc_id)
