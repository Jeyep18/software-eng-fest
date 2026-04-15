# MapStormOverlay.gd
# Attach to a Control node "StormOverlay" inside the MapScreen panel.
# Sits in the scene tree ABOVE MapRoadLayer but BELOW MapNodeButton nodes.
# Call queue_redraw() after opening the map or on encroachment signal.

extends Control

# Color of the storm encroachment wash
const STORM_COLOR_OUTER: Color = Color(0.88, 0.29, 0.29, 0.10)
const STORM_COLOR_INNER: Color = Color(0.88, 0.29, 0.29, 0.18)
const STORM_COLOR_FULL:  Color = Color(0.40, 0.15, 0.15, 0.28)

# Storm label settings
const LABEL_COLOR: Color = Color(0.64, 0.17, 0.17, 0.75)

func _draw() -> void:
	var progress: float = GlobalTimer.get_storm_progress()

	# No overlay until outer danger threshold (4h = 33% of 12h)
	if progress < 0.33:
		return

	var map_size: Vector2 = size   # fills the parent control

	# ── Stage 1: Outer danger (0.33–0.50) — soft ellipse from top-right ──────
	if progress >= 0.33:
		var t: float   = clamp((progress - 0.33) / 0.17, 0.0, 1.0)
		var alpha: float = STORM_COLOR_OUTER.a * t
		var col: Color = Color(STORM_COLOR_OUTER.r, STORM_COLOR_OUTER.g,
				STORM_COLOR_OUTER.b, alpha)

		# Ellipse centered on the outer-right (grocery side)
		var center: Vector2 = Vector2(map_size.x * 0.85, map_size.y * 0.5)
		var rx: float = map_size.x * 0.30 * t
		var ry: float = map_size.y * 0.45 * t
		_draw_soft_ellipse(center, rx, ry, col)

		# Storm label
		if t > 0.5:
			draw_string(
				ThemeDB.fallback_font,
				center + Vector2(-20, -ry * 0.6),
				"Storm approaching",
				HORIZONTAL_ALIGNMENT_CENTER,
				-1, 11,
				LABEL_COLOR)

	# ── Stage 2: Outer closed + Barangay danger (0.50–0.75) ─────────────────
	if progress >= 0.50:
		var t: float   = clamp((progress - 0.50) / 0.25, 0.0, 1.0)
		var alpha: float = STORM_COLOR_INNER.a * t * 0.7
		var col: Color = Color(STORM_COLOR_INNER.r, STORM_COLOR_INNER.g,
				STORM_COLOR_INNER.b, alpha)

		# Expand from the right, creeping toward center
		var center: Vector2 = Vector2(map_size.x * 0.75, map_size.y * 0.55)
		var rx: float = map_size.x * 0.35 * t
		var ry: float = map_size.y * 0.50 * t
		_draw_soft_ellipse(center, rx, ry, col)

	# ── Stage 3: Inner danger (0.75–1.0) ─────────────────────────────────────
	if progress >= 0.75:
		var t: float   = clamp((progress - 0.75) / 0.25, 0.0, 1.0)
		var alpha: float = STORM_COLOR_FULL.a * t
		var col: Color = Color(STORM_COLOR_FULL.r, STORM_COLOR_FULL.g,
				STORM_COLOR_FULL.b, alpha)

		# Large overlay covering most of the map
		var center: Vector2 = Vector2(map_size.x * 0.6, map_size.y * 0.55)
		var rx: float = map_size.x * 0.55 * t
		var ry: float = map_size.y * 0.60 * t
		_draw_soft_ellipse(center, rx, ry, col)

	# ── Stage 4: Storm arrived (1.0) — full tint ─────────────────────────────
	if progress >= 1.0:
		draw_rect(Rect2(Vector2.ZERO, map_size),
				Color(0.15, 0.08, 0.08, 0.50))
		draw_string(
			ThemeDB.fallback_font,
			Vector2(map_size.x * 0.5, map_size.y * 0.5),
			"STORM HAS ARRIVED",
			HORIZONTAL_ALIGNMENT_CENTER,
			-1, 14,
			Color(0.90, 0.30, 0.30, 0.9))

# ── Helper: draws a filled ellipse using a polygon approximation ──────────────
func _draw_soft_ellipse(center: Vector2, rx: float, ry: float, col: Color,
		steps: int = 32) -> void:
	if rx <= 0 or ry <= 0:
		return
	var points: PackedVector2Array = PackedVector2Array()
	points.resize(steps)
	for i in range(steps):
		var angle: float = (float(i) / float(steps)) * TAU
		points[i] = center + Vector2(cos(angle) * rx, sin(angle) * ry)
	draw_colored_polygon(points, col)
