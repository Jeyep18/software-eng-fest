# MapNodeButton.gd
# A single node on the map. Handles visual state: open / danger / closed / current.
# Attach to a Control node (MapNodeButton.tscn) sized ~110x52.
# 
# Scene tree expected:
#   MapNodeButton (Control, 110x52)
#     └── PanelContainer
#           ├── VBoxContainer
#           │     ├── NameLabel  (Label)
#           │     └── SubLabel   (Label)
#           └── (optional) DangerIcon (TextureRect or Label "!")

extends Control

# ── Signals ──────────────────────────────────────────────────────────────────
signal node_selected(location_id: String)

# ── Node References ───────────────────────────────────────────────────────────
@onready var panel:      PanelContainer = $PanelContainer
@onready var name_label: Label          = $PanelContainer/VBoxContainer/NameLabel
@onready var sub_label:  Label          = $PanelContainer/VBoxContainer/SubLabel

# ── StyleBoxes (assign in Inspector or via code below) ────────────────────────
# We build them procedurally so the file is self-contained.
var _style_open:    StyleBoxFlat
var _style_current: StyleBoxFlat
var _style_danger:  StyleBoxFlat
var _style_closed:  StyleBoxFlat

# ── State ──────────────────────────────────────────────────────────────────────
var _location_id:     String = ""
var _current_state:   String = "open"   # open | current | danger | closed
var _is_hovered:      bool   = false

# ── Colors ────────────────────────────────────────────────────────────────────
const COL_OPEN_BG:      Color = Color(0.96, 0.94, 0.88)    # warm off-white paper
const COL_OPEN_BORDER:  Color = Color(0.55, 0.50, 0.40)    # warm brown outline
const COL_OPEN_TEXT:    Color = Color(0.18, 0.15, 0.10)

const COL_CURR_BG:      Color = Color(0.09, 0.37, 0.64)    # blue — "you are here"
const COL_CURR_BORDER:  Color = Color(0.71, 0.83, 0.95)
const COL_CURR_TEXT:    Color = Color(0.90, 0.95, 0.98)

const COL_DANG_BG:      Color = Color(0.99, 0.92, 0.92)    # pale red
const COL_DANG_BORDER:  Color = Color(0.89, 0.30, 0.29)    # red, dashed in art
const COL_DANG_TEXT:    Color = Color(0.64, 0.17, 0.17)

const COL_CLOS_BG:      Color = Color(0.82, 0.81, 0.79, 0.5)
const COL_CLOS_BORDER:  Color = Color(0.65, 0.63, 0.60, 0.4)
const COL_CLOS_TEXT:    Color = Color(0.55, 0.53, 0.50)

const HOVER_DARKEN:     float = 0.08

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	print("=== MapNodeButton _ready fired: ", name)
	_build_styleboxes()
	mouse_entered.connect(_on_hover_enter)
	mouse_exited.connect(_on_hover_exit)
	mouse_filter = Control.MOUSE_FILTER_STOP
	print("mouse_filter is: ", mouse_filter)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		print("Button clicked: ", _location_id, " state: ", _current_state)
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if _current_state not in ["closed", "current"]:
				node_selected.emit(_location_id)

func _build_styleboxes() -> void:
	_style_open    = _make_style(COL_OPEN_BG,  COL_OPEN_BORDER,  false)
	_style_current = _make_style(COL_CURR_BG,  COL_CURR_BORDER,  false)
	_style_danger  = _make_style(COL_DANG_BG,  COL_DANG_BORDER,  true)   # dashed border
	_style_closed  = _make_style(COL_CLOS_BG,  COL_CLOS_BORDER,  false)

func _make_style(bg: Color, border: Color, dashed: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color           = bg
	s.border_color       = border
	s.border_width_left  = 1
	s.border_width_right = 1
	s.border_width_top   = 1
	s.border_width_bottom = 1
	s.corner_radius_top_left     = 8
	s.corner_radius_top_right    = 8
	s.corner_radius_bottom_left  = 8
	s.corner_radius_bottom_right = 8
	s.content_margin_left   = 10
	s.content_margin_right  = 10
	s.content_margin_top    = 6
	s.content_margin_bottom = 6
	# Godot's StyleBoxFlat doesn't natively support dashed borders,
	# but we mark danger visually via the red color + a pulsing modulate
	# in _process. Set a slightly thicker border for danger nodes.
	if dashed:
		s.border_width_left   = 2
		s.border_width_right  = 2
		s.border_width_top    = 2
		s.border_width_bottom = 2
	return s

# ── Public API ─────────────────────────────────────────────────────────────────
func setup(loc_id: String, display_name: String, travel_label: String) -> void:
	_location_id = loc_id
	name_label.text = display_name
	sub_label.text  = travel_label
	_apply_state("open")

func refresh(new_state: String, travel_label: String) -> void:
	sub_label.text = travel_label
	_apply_state(new_state)

# ── State Application ─────────────────────────────────────────────────────────
func _apply_state(new_state: String) -> void:
	_current_state = new_state

	var style: StyleBoxFlat
	var name_col: Color
	var sub_col:  Color

	match new_state:
		"current":
			style    = _style_current
			name_col = COL_CURR_TEXT
			sub_col  = COL_CURR_TEXT.darkened(0.2)
			sub_label.text = "Nandito ka"
			mouse_default_cursor_shape = Control.CURSOR_ARROW
		"danger":
			style    = _style_danger
			name_col = COL_DANG_TEXT
			sub_col  = COL_DANG_TEXT.lightened(0.1)
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		"closed":
			style    = _style_closed
			name_col = COL_CLOS_TEXT
			sub_col  = COL_CLOS_TEXT
			sub_label.text = "CLOSED"
			mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
		_:  # "open"
			style    = _style_open
			name_col = COL_OPEN_TEXT
			sub_col  = COL_OPEN_TEXT.lightened(0.2)
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	panel.add_theme_stylebox_override("panel", style)
	name_label.add_theme_color_override("font_color", name_col)
	sub_label.add_theme_color_override("font_color", sub_col)

	# Closed nodes are visible but not interactive
	mouse_filter = Control.MOUSE_FILTER_IGNORE if new_state == "closed" \
			else Control.MOUSE_FILTER_STOP

# ── Hover / Click ─────────────────────────────────────────────────────────────
func _on_hover_enter() -> void:
	if _current_state in ["closed", "current"]:
		return
	_is_hovered = true
	modulate = Color(1.0 - HOVER_DARKEN, 1.0 - HOVER_DARKEN, 1.0 - HOVER_DARKEN)

func _on_hover_exit() -> void:
	_is_hovered = false
	modulate = Color.WHITE

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		print("Button clicked: ", _location_id, " state: ", _current_state)
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if _current_state not in ["closed", "current"]:
				node_selected.emit(_location_id)

# ── Danger Pulse (visual feedback that this zone is risky) ────────────────────
var _pulse_time: float = 0.0

func _process(delta: float) -> void:
	if _current_state != "danger":
		return
	_pulse_time += delta
	# Gentle opacity pulse: oscillates between 0.85 and 1.0
	var pulse: float = 0.85 + 0.15 * (0.5 + 0.5 * sin(_pulse_time * 2.5))
	modulate.a = pulse if not _is_hovered else 1.0
