# MapRoadLayer.gd
extends Control

@export var node_positions: Dictionary = {}
@export var connections:    Array      = []

const COLOR_PRIMARY:   Color = Color(0.60, 0.52, 0.38, 0.85)
const COLOR_SECONDARY: Color = Color(0.60, 0.52, 0.38, 0.45)
const WIDTH_PRIMARY:   float = 3.0
const WIDTH_SECONDARY: float = 1.8

# Beta scope — only these roads exist
const PRIMARY_CONNECTIONS: Array = [
	["home",     "ate_linda"],
	["home",     "hardware"],
	["ate_linda", "pharmacy"],
	["hardware", "pharmacy"],
	["hardware", "grocery"],
]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	if node_positions.is_empty():
		return
	for conn in connections:
		var a: String = conn[0]
		var b: String = conn[1]
		if not node_positions.has(a) or not node_positions.has(b):
			continue
		var pos_a: Vector2 = node_positions[a]
		var pos_b: Vector2 = node_positions[b]
		var is_primary: bool = PRIMARY_CONNECTIONS.has(conn) \
				or PRIMARY_CONNECTIONS.has([b, a])
		if is_primary:
			draw_line(pos_a, pos_b, COLOR_PRIMARY, WIDTH_PRIMARY, true)
		else:
			_draw_dashed_line(pos_a, pos_b, COLOR_SECONDARY, WIDTH_SECONDARY)

func _draw_dashed_line(from: Vector2, to: Vector2, col: Color, width: float,
		dash_len: float = 7.0, gap_len: float = 5.0) -> void:
	var total_len: float  = from.distance_to(to)
	var dir:       Vector2 = (to - from).normalized()
	var traveled:  float  = 0.0
	var drawing:   bool   = true
	while traveled < total_len:
		var seg_len: float = dash_len if drawing else gap_len
		var seg_end: float = min(traveled + seg_len, total_len)
		if drawing:
			draw_line(from + dir * traveled, from + dir * seg_end, col, width, true)
		traveled += seg_len
		drawing   = not drawing
