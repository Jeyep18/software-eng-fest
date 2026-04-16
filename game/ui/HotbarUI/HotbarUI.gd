# res://scripts/HotbarUI.gd
extends CanvasLayer

@onready var slot_container: HBoxContainer = $HotbarRoot/SlotContainer

# Tracks which hotbar slot is selected (for future use)
var selected_slot: int = 0

func _ready() -> void:
	InventoryManager.inventory_changed.connect(_redraw_hotbar)
	_redraw_hotbar()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_hotbar"):
		visible = !visible

func _redraw_hotbar() -> void:
	# Clear old slots
	for child in slot_container.get_children():
		child.queue_free()

	var items = InventoryManager.get_all_items()

	# Build all 8 slots (filled or empty)
	for i in range(InventoryManager.MAX_INVENTORY_SIZE):
		var item: ItemData = null
		if i < items.size():
			item = items[i]
		var slot = _create_slot(item, i)
		slot_container.add_child(slot)

func _create_slot(item: ItemData, index: int) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(50, 50)

	# Style the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.8)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(1, 1, 1, 0.15)
	panel.add_theme_stylebox_override("panel", style)

	if item != null:
		# Icon
		var icon = TextureRect.new()
		icon.texture = item.item_icon
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 4
		icon.offset_top = 4
		icon.offset_right = -4
		icon.offset_bottom = -14  # leave room for label
		panel.add_child(icon)

		# Item name label
		var label = Label.new()
		label.text = item.item_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.add_theme_font_size_override("font_size", 9)
		panel.add_child(label)

	# Slot number (small, bottom-right corner)
	var num_label = Label.new()
	num_label.text = str(index + 1)
	num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	num_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	num_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	num_label.offset_right = -4
	num_label.offset_bottom = -2
	num_label.add_theme_font_size_override("font_size", 8)
	num_label.modulate = Color(1, 1, 1, 0.35)
	panel.add_child(num_label)

	return panel
