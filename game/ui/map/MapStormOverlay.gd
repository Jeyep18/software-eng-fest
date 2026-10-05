extends Control

const STORM_ARRIVAL_MINUTE := 720

const WASH: Texture2D = preload("res://game/assets/map_ui/storm_wash.png")
const WIND: Texture2D = preload("res://game/assets/map_ui/storm_wind.png")
const EYE: Texture2D = preload("res://game/assets/map_ui/storm_eye.png")
const TEXT_COLOR := Color(0.18, 0.15, 0.14, 0.95)

var node_positions: Dictionary = {}
var _ink_phase := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	LocalizationManager.language_changed.connect(func(_language_id: String) -> void: queue_redraw())


func _process(delta: float) -> void:
	_ink_phase += delta
	queue_redraw()


func _draw() -> void:
	if size == Vector2.ZERO:
		return
	var minute: int = GlobalTimer.current_minutes
	var travel_t := clampf(float(minute) / float(STORM_ARRIVAL_MINUTE), 0.0, 1.0)
	var storm_center := _storm_center_at(travel_t)
	var storm_radius := _storm_radius_at(travel_t, storm_center)
	_draw_storm_art(storm_center, storm_radius)
	_draw_centered_text(LocalizationManager.translate("STORM"), storm_center + Vector2(0.0, storm_radius * 0.92), 20, TEXT_COLOR, true)
	if minute >= STORM_ARRIVAL_MINUTE:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.12, 0.02, 0.02, 0.52))
		_draw_centered_text(LocalizationManager.translate("STORM HAS ARRIVED"), size * 0.5, 18, Color(1.0, 0.88, 0.78))


func _draw_storm_art(center: Vector2, radius: float) -> void:
	# Three independent ink layers replace the old concentric red circles.
	_draw_layer(WASH, center, radius * 1.35, 0.0, Color(1, 1, 1, 0.34))
	_draw_layer(WIND, center, radius * 1.12, sin(_ink_phase * 0.7) * 0.07, Color(1, 1, 1, 0.63))
	_draw_layer(EYE, center + Vector2(2.0, -2.0), radius * 0.42, sin(_ink_phase * 1.1) * 0.04, Color(1, 1, 1, 0.86))


func _draw_layer(texture: Texture2D, center: Vector2, half_size: float, rotation: float, tint: Color) -> void:
	draw_set_transform(center, rotation)
	draw_texture_rect(texture, Rect2(Vector2(-half_size, -half_size), Vector2.ONE * half_size * 2.0), false, tint)
	draw_set_transform(Vector2.ZERO)


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


func _quadratic_bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var one_minus_t := 1.0 - clampf(t, 0.0, 1.0)
	var clamped_t := clampf(t, 0.0, 1.0)
	return a * one_minus_t * one_minus_t + b * 2.0 * one_minus_t * clamped_t + c * clamped_t * clamped_t


func _node_pos(location_id: String, fallback: Vector2) -> Vector2:
	return node_positions.get(location_id, fallback)


func _draw_centered_text(value: String, baseline_center: Vector2, font_size: int, color: Color, outlined: bool = false) -> void:
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var position := baseline_center - Vector2(text_size.x * 0.5, 0.0)
	if outlined:
		draw_string_outline(font, position, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color(0.96, 0.92, 0.82, 0.95))
	draw_string(font, position, value,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
