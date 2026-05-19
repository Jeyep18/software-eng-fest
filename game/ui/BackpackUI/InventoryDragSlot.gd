extends Panel

var backpack_ui: CanvasLayer = null
var item_index: int = -1
var item_data: ItemData = null

func setup(ui: CanvasLayer, index: int, item: ItemData) -> void:
	backpack_ui = ui
	item_index = index
	item_data = item

func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_data == null or item_index < 0:
		return null

	var preview = TextureRect.new()
	preview.texture = item_data.item_icon
	preview.custom_minimum_size = Vector2(48, 48)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)

	return {
		"type": "inventory_item",
		"index": item_index,
		"item": item_data,
	}
