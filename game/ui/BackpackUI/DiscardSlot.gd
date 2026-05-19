extends Panel

@onready var label: Label = $Label
@onready var icon: TextureRect = $TextureRect

var _base_modulate: Color

func _ready() -> void:
	_base_modulate = self_modulate
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	if not InventoryManager.discard_changed.is_connected(_refresh):
		InventoryManager.discard_changed.connect(_refresh)
	_refresh()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		InventoryManager.restore_discard_item()

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		self_modulate = _base_modulate
		return false
	if data.get("type", "") != "inventory_item":
		self_modulate = _base_modulate
		return false
	var index = int(data.get("index", -1))
	var can_drop = index >= 0 and index < InventoryManager.get_item_count()
	self_modulate = Color(1, 0.08, 0.18, 1) if can_drop else _base_modulate
	return can_drop

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	self_modulate = _base_modulate
	InventoryManager.move_item_to_discard(int(data["index"]))

func _refresh() -> void:
	var item = InventoryManager.discard_held_item
	if item == null:
		icon.texture = null
		label.text = "Discard"
		label.visible = true
		return

	icon.texture = item.item_icon
	label.text = item.item_name
	label.visible = item.item_icon == null
