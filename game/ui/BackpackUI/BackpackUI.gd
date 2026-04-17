# res://scripts/BackpackUI.gd
extends CanvasLayer

@onready var grid_container: GridContainer = $BackpackPanel/GridContainer
@onready var count_label: Label = $BackpackPanel/TitleBar/CountLabel
@onready var info_icon: TextureRect = $BackpackPanel/ItemInfoBar/InfoIcon
@onready var info_name: Label = $BackpackPanel/ItemInfoBar/InfoName
@onready var info_desc: Label = $BackpackPanel/ItemInfoBar/InfoDesc

var selected_slot_index: int = -1

func _ready() -> void:
	visible = false
	grid_container.columns = 4
	InventoryManager.inventory_changed.connect(_on_inventory_changed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_backpack"):
		_toggle()

func _toggle() -> void:
	visible = !visible
	if visible:
		_redraw_backpack()

func _on_inventory_changed() -> void:
	if visible:
		_redraw_backpack()

func _redraw_backpack() -> void:
	# Clear old slots
	for child in grid_container.get_children():
		child.queue_free()

	var items = InventoryManager.get_all_items()

	# Update count label
	count_label.text = str(items.size()) + " / " + str(InventoryManager.MAX_INVENTORY_SIZE)

	# Build all 8 slots
	for i in range(InventoryManager.MAX_INVENTORY_SIZE):
		var item: ItemData = null
		if i < items.size():
			item = items[i]
		var slot = _create_slot(item, i)
		grid_container.add_child(slot)

	# Update info bar for currently selected slot
	_refresh_info_bar()

func _create_slot(item: ItemData, index: int) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(80, 80)

	# Style
	var style = StyleBoxFlat.new()
	if item != null:
		style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
	else:
		style.bg_color = Color(0.1, 0.1, 0.1, 0.5)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(1, 1, 1, 0.12)
	panel.add_theme_stylebox_override("panel", style)

	if item != null:
		var icon = TextureRect.new()
		icon.texture = item.item_icon
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 6
		icon.offset_top = 6
		icon.offset_right = -6
		icon.offset_bottom = -18
		panel.add_child(icon)

		var label = Label.new()
		label.text = item.item_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.add_theme_font_size_override("font_size", 10)
		panel.add_child(label)

		# Make slot clickable to select it
		panel.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed:
				selected_slot_index = index
				_refresh_info_bar()
		)
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	return panel

func _refresh_info_bar() -> void:
	var items = InventoryManager.get_all_items()
	if selected_slot_index >= 0 and selected_slot_index < items.size():
		var item = items[selected_slot_index]
		info_icon.texture = item.item_icon
		info_name.text = item.item_name
		info_desc.text = item.item_description if item.item_description != "" else "No description."
	else:
		info_icon.texture = null
		info_name.text = ""
		info_desc.text = "Click an item to see details."
