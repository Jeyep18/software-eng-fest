extends Control

const OUTER_DANGER_MINUTE: int = 240
const OUTER_CLOSED_MINUTE: int = 360
const INNER_DANGER_MINUTE: int = 540
const STORM_ARRIVAL_MINUTE: int = 720

const STORM_FILL: Color = Color(0.76, 0.08, 0.07, 0.20)
const STORM_CORE: Color = Color(0.36, 0.02, 0.03, 0.28)
const STORM_EDGE: Color = Color(0.95, 0.18, 0.12, 0.55)
const DANGER_MARKER: Color = Color(0.95, 0.25, 0.16, 0.74)
const CLOSED_MARKER: Color = Color(0.42, 0.03, 0.04, 0.82)
const TEXT_COLOR: Color = Color(0.95, 0.22, 0.15, 0.90)
const STORM_TEXT_COLOR: Color = Color(1.0, 0.88, 0.78, 0.95)

var node_positions: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	LocalizationManager.language_changed.connect(func(_language_id: String) -> void: queue_redraw())

func _draw() -> void:
	if size == Vector2.ZERO:
		return

	var minute: int = GlobalTimer.current_minutes
	var travel_t: float = clamp(float(minute) / float(STORM_ARRIVAL_MINUTE), 0.0, 1.0)
	var storm_center: Vector2 = _storm_center_at(travel_t)
	var storm_radius: float = _storm_radius_at(travel_t, storm_center)

	_draw_storm_body(storm_center, storm_radius, travel_t)
	_draw_centered_text(LocalizationManager.translate("STORM"), storm_center + Vector2(0.0, 6.0), 18, STORM_TEXT_COLOR)
	_draw_active_location_markers(minute)

	if minute >= STORM_ARRIVAL_MINUTE:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.12, 0.02, 0.02, 0.52))
		_draw_centered_text(LocalizationManager.translate("STORM HAS ARRIVED"), Vector2(size.x * 0.5, size.y * 0.5), 18)

func _storm_center_at(t: float) -> Vector2:
	var grocery := _node_pos("grocery", Vector2(size.x * 0.84, size.y * 0.68))
	var hardware := _node_pos("hardware", Vector2(size.x * 0.73, size.y * 0.40))
	var pharmacy := _node_pos("pharmacy", Vector2(size.x * 0.63, size.y * 0.72))
	var home := _node_pos("home", Vector2(size.x * 0.48, size.y * 0.43))

	var start := Vector2(size.x * 1.08, size.y * 0.04)
	var control := Vector2(size.x * 1.05, size.y * 0.80)
	var inner_target := (hardware + pharmacy + home) / 3.0

	if t <= 0.5:
		return _quadratic_bezier(start, control, grocery, t / 0.5)

	return _quadratic_bezier(grocery, Vector2(size.x * 0.86, size.y * 0.88), inner_target, (t - 0.5) / 0.5)

func _storm_radius_at(t: float, center: Vector2) -> float:
	var grocery := _node_pos("grocery", Vector2(size.x * 0.84, size.y * 0.68))
	var hardware := _node_pos("hardware", Vector2(size.x * 0.73, size.y * 0.40))
	var pharmacy := _node_pos("pharmacy", Vector2(size.x * 0.63, size.y * 0.72))
	var grocery_danger_radius: float = center.distance_to(grocery) + 10.0
	var inner_danger_radius: float = maxf(center.distance_to(hardware), center.distance_to(pharmacy)) + 12.0

	if t <= 0.333:
		return lerpf(48.0, grocery_danger_radius, t / 0.333)
	if t <= 0.5:
		return lerpf(grocery_danger_radius, 160.0, (t - 0.333) / 0.167)
	if t <= 0.75:
		return lerpf(160.0, inner_danger_radius, (t - 0.5) / 0.25)
	return lerpf(inner_danger_radius, 300.0, (t - 0.75) / 0.25)

func _draw_storm_body(center: Vector2, radius: float, t: float) -> void:
	var drift := Vector2(22.0, -12.0).rotated(t * TAU)
	_draw_soft_circle(center, radius * 1.30, STORM_FILL)
	_draw_soft_circle(center + drift, radius * 0.78, STORM_CORE)
	_draw_ring(center, radius, STORM_EDGE)
	_draw_ring(center + drift * 0.5, radius * 0.62, Color(0.95, 0.38, 0.28, 0.32))

func _draw_active_location_markers(minute: int) -> void:
	if minute >= OUTER_DANGER_MINUTE:
		var grocery := _node_pos("grocery", Vector2(size.x * 0.84, size.y * 0.68))
		if minute >= OUTER_CLOSED_MINUTE:
			_draw_node_marker(grocery, LocalizationManager.translate("Closed"), CLOSED_MARKER)
		else:
			_draw_node_marker(grocery, LocalizationManager.translate("Danger"), DANGER_MARKER)

	if minute >= INNER_DANGER_MINUTE:
		_draw_node_marker(_node_pos("hardware", Vector2(size.x * 0.73, size.y * 0.40)), LocalizationManager.translate("Danger"), DANGER_MARKER)
		_draw_node_marker(_node_pos("pharmacy", Vector2(size.x * 0.63, size.y * 0.72)), LocalizationManager.translate("Danger"), DANGER_MARKER)

func _quadratic_bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var one_minus_t: float = 1.0 - clamp(t, 0.0, 1.0)
	var clamped_t: float = clamp(t, 0.0, 1.0)
	return (a * one_minus_t * one_minus_t) + (b * 2.0 * one_minus_t * clamped_t) + (c * clamped_t * clamped_t)

func _node_pos(location_id: String, fallback: Vector2) -> Vector2:
	return node_positions.get(location_id, fallback)

func _draw_soft_circle(center: Vector2, radius: float, color: Color) -> void:
	if radius <= 0.0:
		return
	for i in range(4):
		var layer_radius: float = radius * (1.0 - float(i) * 0.18)
		var layer_color := color
		layer_color.a *= 0.35 + float(i) * 0.16
		draw_circle(center, layer_radius, layer_color)

func _draw_ring(center: Vector2, radius: float, color: Color) -> void:
	if radius <= 0.0:
		return
	draw_arc(center, radius, 0.0, TAU, 96, color, 3.0)

func _draw_node_marker(center: Vector2, label: String, color: Color) -> void:
	var marker_rect := Rect2(center + Vector2(-36.0, -46.0), Vector2(72.0, 22.0))
	draw_rect(marker_rect, color, true, -1.0)
	draw_rect(marker_rect, Color(0.95, 0.85, 0.78, 0.55), false, 1.0)
	_draw_centered_text(label, marker_rect.position + Vector2(marker_rect.size.x * 0.5, 16.0), 11)

func _draw_centered_text(text: String, baseline_center: Vector2, font_size: int, color: Color = TEXT_COLOR) -> void:
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, baseline_center - Vector2(text_size.x * 0.5, 0.0), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
