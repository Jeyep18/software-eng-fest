# MapStormOverlay.gd
extends Control

const STORM_COLOR_OUTER: Color = Color(0.88, 0.29, 0.29, 0.12)
const STORM_COLOR_INNER: Color = Color(0.88, 0.29, 0.29, 0.22)
const STORM_COLOR_FULL:  Color = Color(0.40, 0.15, 0.15, 0.32)
const LABEL_COLOR:       Color = Color(0.75, 0.20, 0.20, 0.80)

func _ready() -> void:
	# CRITICAL: without anchors, size is (0,0) and nothing draws
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var progress: float = GlobalTimer.get_storm_progress()
	var map_size: Vector2 = size

	if map_size == Vector2.ZERO or progress < 0.33:
		return

	# Stage 1: Outer danger (4h–6h) — grocery side, right of map
	if progress >= 0.33:
		var t: float = clamp((progress - 0.33) / 0.17, 0.0, 1.0)
		var col: Color = Color(STORM_COLOR_OUTER.r, STORM_COLOR_OUTER.g,
				STORM_COLOR_OUTER.b, STORM_COLOR_OUTER.a * t)
		var center: Vector2 = Vector2(map_size.x * 0.88, map_size.y * 0.60)
		_draw_soft_ellipse(center, map_size.x * 0.28 * t, map_size.y * 0.40 * t, col)
		if t > 0.6:
			draw_string(ThemeDB.fallback_font,
				Vector2(map_size.x * 0.82, map_size.y * 0.25),
				"⚠ Storm approaching", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, LABEL_COLOR)

	# Stage 2: Outer closed (6h–9h) — spreads to cover pharmacy + grocery
	if progress >= 0.50:
		var t: float = clamp((progress - 0.50) / 0.25, 0.0, 1.0)
		var col: Color = Color(STORM_COLOR_INNER.r, STORM_COLOR_INNER.g,
				STORM_COLOR_INNER.b, STORM_COLOR_INNER.a * t * 0.8)
		var center: Vector2 = Vector2(map_size.x * 0.78, map_size.y * 0.58)
		_draw_soft_ellipse(center, map_size.x * 0.38 * t, map_size.y * 0.48 * t, col)

	# Stage 3: Inner danger (9h+) — hardware + pharmacy threatened
	if progress >= 0.75:
		var t: float = clamp((progress - 0.75) / 0.25, 0.0, 1.0)
		var col: Color = Color(STORM_COLOR_FULL.r, STORM_COLOR_FULL.g,
				STORM_COLOR_FULL.b, STORM_COLOR_FULL.a * t)
		var center: Vector2 = Vector2(map_size.x * 0.62, map_size.y * 0.52)
		_draw_soft_ellipse(center, map_size.x * 0.52 * t, map_size.y * 0.58 * t, col)

	# Stage 4: Storm arrived
	if progress >= 1.0:
		draw_rect(Rect2(Vector2.ZERO, map_size), Color(0.12, 0.06, 0.06, 0.55))
		draw_string(ThemeDB.fallback_font,
			Vector2(map_size.x * 0.5, map_size.y * 0.5),
			"STORM HAS ARRIVED", HORIZONTAL_ALIGNMENT_CENTER, -1, 16,
			Color(0.95, 0.30, 0.30, 0.95))

func _draw_soft_ellipse(center: Vector2, rx: float, ry: float, col: Color,
		steps: int = 40) -> void:
	if rx <= 0.0 or ry <= 0.0:
		return
	var points := PackedVector2Array()
	points.resize(steps)
	for i in range(steps):
		var angle: float = (float(i) / float(steps)) * TAU
		points[i] = center + Vector2(cos(angle) * rx, sin(angle) * ry)
	draw_colored_polygon(points, col)
