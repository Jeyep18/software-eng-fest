# MapRoadLayer.gd
# Attach to a Control node "RoadLayer" that sits BELOW the MapNodeButton nodes
# in the scene tree (so roads draw behind node buttons).
# The parent MapScreen must call queue_redraw() on this node when the map opens.

extends Control

# Road data is read directly from MapScreen's constants.
# We pass it via export so this node stays decoupled.
@export var node_positions: Dictionary = {}   # loc_id → Vector2
@export var connections: Array           = []   # Array of [loc_id, loc_id]

const COLOR_ROAD_PRIMARY:   Color = Color(0.55, 0.50, 0.40, 0.75)
const COLOR_ROAD_SECONDARY: Color = Color(0.55, 0.50, 0.40, 0.40)
const WIDTH_PRIMARY:        float = 2.5
const WIDTH_SECONDARY:      float = 1.5

# Primary roads (direct paths from home):
const PRIMARY_CONNECTIONS: Array = [
	["home", "mang_romy"],
	["home", "ate_linda"],
	["home", "hardware"],
	["hardware", "pharmacy"],
	["hardware", "barangay_hall"],
	["pharmacy", "grocery"],
]

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

		var is_primary: bool = PRIMARY_CONNECTIONS.has(conn) or \
				PRIMARY_CONNECTIONS.has([b, a])

		var col:   Color = COLOR_ROAD_PRIMARY   if is_primary else COLOR_ROAD_SECONDARY
		var width: float = WIDTH_PRIMARY        if is_primary else WIDTH_SECONDARY

		if is_primary:
			draw_line(pos_a, pos_b, col, width, true)
		else:
			# Dashed line for secondary connections
			_draw_dashed_line(pos_a, pos_b, col, width)

func _draw_dashed_line(
		from: Vector2, to: Vector2, col: Color, width: float,
		dash_len: float = 6.0, gap_len: float = 4.0) -> void:
	var total_len: float = from.distance_to(to)
	var direction: Vector2 = (to - from).normalized()
	var traveled: float = 0.0
	var drawing: bool = true

	while traveled < total_len:
		var seg_len: float = dash_len if drawing else gap_len
		var seg_end: float = min(traveled + seg_len, total_len)

		if drawing:
			draw_line(
				from + direction * traveled,
				from + direction * seg_end,
				col, width, true)

		traveled += seg_len
		drawing = not drawing


# ══════════════════════════════════════════════════════════════════════════════
# MapStormOverlay.gd
# Attach to a Control node "StormOverlay" that sits ABOVE RoadLayer but BELOW
# the MapNodeButton nodes (so storm tint is behind buttons but above roads).
# Call queue_redraw() on this node whenever storm progress changes.
# ══════════════════════════════════════════════════════════════════════════════

# NOTE: Because GDScript files are one-class-per-file, the MapStormOverlay
# code is provided below as a separate file. Copy it into MapStormOverlay.gd.


# ── MapStormOverlay.gd (separate file) ────────────────────────────────────────
# extends Control
#
# The storm overlay is rendered as a semi-transparent red gradient ellipse
# that grows from the outer-right corner of the map inward, mirroring the
# encroachment logic in SceneManager / GlobalTimer.
#
# Growth stages map to SceneManager's zone thresholds:
#   0.0 – 0.33  → no overlay visible
#   0.33 – 0.50 → outer danger (grocery area, right side)
#   0.50 – 0.75 → outer closed + barangay hall danger
#   0.75 – 1.0  → inner danger (hardware, pharmacy)
#   1.0         → full storm (whole map tinted)
#
# This is purely decorative — the actual locked/danger state is managed
# by SceneManager. The overlay just communicates visual urgency.
