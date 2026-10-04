class_name ScratchLottoSlot
extends Control

signal revealed

const MASK_WIDTH: int = 160
const MASK_HEIGHT: int = 150
const BRUSH_RADIUS: int = 16
const REVEAL_FRACTION: float = 0.5

var _fruit_rect: TextureRect
var _foil_rect: TextureRect
var _foil_image: Image
var _foil_texture: ImageTexture
var _erased: PackedByteArray
var _opaque_count: int = 0
var _erased_count: int = 0
var _dragging: bool = false
var _last_position: Vector2 = Vector2.ZERO
var _is_revealed: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_fruit_rect = TextureRect.new()
	_fruit_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fruit_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fruit_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_fruit_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fruit_rect)

	_foil_rect = TextureRect.new()
	_foil_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_foil_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_foil_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_foil_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_foil_rect)
	hide()


func show_fruit(atlas: Texture2D, region: Rect2, base_foil: Image) -> void:
	var crop := AtlasTexture.new()
	crop.atlas = atlas
	crop.region = region
	_fruit_rect.texture = crop
	_foil_image = base_foil.duplicate() as Image
	_foil_texture = ImageTexture.create_from_image(_foil_image)
	_foil_rect.texture = _foil_texture
	_foil_rect.show()
	_erased = PackedByteArray()
	_erased.resize(MASK_WIDTH * MASK_HEIGHT)
	_opaque_count = 0
	_erased_count = 0
	_dragging = false
	_is_revealed = false
	for y in MASK_HEIGHT:
		for x in MASK_WIDTH:
			if _foil_image.get_pixel(x, y).a > 0.2:
				_opaque_count += 1
	show()


func reveal() -> void:
	if _is_revealed:
		return
	_is_revealed = true
	_dragging = false
	_foil_rect.hide()
	revealed.emit()


func is_revealed() -> bool:
	return _is_revealed


func _gui_input(event: InputEvent) -> void:
	if _is_revealed or _foil_image == null:
		return
	if event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.button_index != MOUSE_BUTTON_LEFT:
			return
		_dragging = click.pressed
		if _dragging:
			_last_position = click.position
			_scratch_line(click.position, click.position)
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		var motion := event as InputEventMouseMotion
		if motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_scratch_line(_last_position, motion.position)
			_last_position = motion.position
		else:
			_dragging = false
		accept_event()


func _scratch_line(from_position: Vector2, to_position: Vector2) -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var from_pixel := Vector2(from_position.x * MASK_WIDTH / size.x, from_position.y * MASK_HEIGHT / size.y)
	var to_pixel := Vector2(to_position.x * MASK_WIDTH / size.x, to_position.y * MASK_HEIGHT / size.y)
	var steps := maxi(1, ceili(from_pixel.distance_to(to_pixel) / 8.0))
	var changed := false
	for step in steps + 1:
		changed = _erase_circle(from_pixel.lerp(to_pixel, float(step) / steps)) or changed
	if not changed:
		return
	_foil_texture.update(_foil_image)
	if _opaque_count > 0 and float(_erased_count) / _opaque_count >= REVEAL_FRACTION:
		reveal()


func _erase_circle(center: Vector2) -> bool:
	var left := clampi(floori(center.x) - BRUSH_RADIUS, 0, MASK_WIDTH - 1)
	var right := clampi(ceili(center.x) + BRUSH_RADIUS, 0, MASK_WIDTH - 1)
	var top := clampi(floori(center.y) - BRUSH_RADIUS, 0, MASK_HEIGHT - 1)
	var bottom := clampi(ceili(center.y) + BRUSH_RADIUS, 0, MASK_HEIGHT - 1)
	var changed := false
	for y in range(top, bottom + 1):
		for x in range(left, right + 1):
			if Vector2(x, y).distance_squared_to(center) > BRUSH_RADIUS * BRUSH_RADIUS:
				continue
			var pixel_index := y * MASK_WIDTH + x
			if _erased[pixel_index] != 0:
				continue
			_erased[pixel_index] = 1
			var color := _foil_image.get_pixel(x, y)
			if color.a > 0.2:
				_erased_count += 1
			color.a = 0.0
			_foil_image.set_pixel(x, y, color)
			changed = true
	return changed
