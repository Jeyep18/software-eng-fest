# FILE: res://scripts/HotbarUI.gd
# ATTACH TO: Root CanvasLayer of HotbarUI.tscn
# PURPOSE: Always-visible hotbar at the bottom of the screen.
# - Never hides (no tab toggle)
# - Shows 8 slots (the full inventory)
# - Highlights the currently selected slot
# - Sits at a LOW layer value so backpack/ESC menu render on top

extends CanvasLayer

@onready var slot_container: HBoxContainer = $HotbarRoot/SlotContainer

# The currently "held" / selected slot index (0-7)
var selected_slot: int = 0

# Track slot Panel nodes so we can update selection highlight without full rebuild
var _slot_panels: Array[Panel] = []

func _ready() -> void:
	# LOW layer number = renders BEHIND other CanvasLayers.
	# BackpackUI and ESC menu should use a higher layer (e.g. 10).
	layer = 1

	InventoryManager.inventory_changed.connect(_redraw_hotbar)
	_redraw_hotbar()

func _unhandled_input(event: InputEvent) -> void:
	# Number keys 1-8 select a slot
	for i in range(8):
		if event.is_action_pressed("hotbar_slot_" + str(i + 1)):
			_select_slot(i)
			return

	# Mouse scroll to cycle through slots
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_select_slot((selected_slot - 1 + 8) % 8)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_select_slot((selected_slot + 1) % 8)

func _select_slot(index: int) -> void:
	selected_slot = clamp(index, 0, InventoryManager.MAX_INVENTORY_SIZE - 1)
	_update_selection_highlight()

func _update_selection_highlight() -> void:
	for i in range(_slot_panels.size()):
		var panel = _slot_panels[i]
		if not is_instance_valid(panel):
			continue
		var style = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if i == selected_slot:
			style.border_color = Color(1.0, 0.85, 0.3, 1.0)  # warm yellow highlight
			style.border_width_left   = 2
			style.border_width_right  = 2
			style.border_width_top    = 2
			style.border_width_bottom = 2
			style.bg_color = Color(0.25, 0.22, 0.08, 0.9)
		else:
			style.border_color = Color(1, 1, 1, 0.12)
			style.border_width_left   = 1
			style.border_width_right  = 1
			style.border_width_top    = 1
			style.border_width_bottom = 1
			style.bg_color = Color(0.13, 0.13, 0.13, 0.85)
		panel.add_theme_stylebox_override("panel", style)

func _redraw_hotbar() -> void:
	for child in slot_container.get_children():
		child.queue_free()
	_slot_panels.clear()

	var items = InventoryManager.get_all_items()

	for i in range(InventoryManager.MAX_INVENTORY_SIZE):
		var item: ItemData = null
		if i < items.size():
			item = items[i]
		var slot = _create_slot(item, i)
		slot_container.add_child(slot)
		_slot_panels.append(slot)

	_update_selection_highlight()

func _create_slot(item: ItemData, index: int) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(54, 54)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.13, 0.13, 0.85)
	style.corner_radius_top_left    = 7
	style.corner_radius_top_right   = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right= 7
	style.border_width_left   = 1
	style.border_width_right  = 1
	style.border_width_top    = 1
	style.border_width_bottom = 1
	style.border_color = Color(1, 1, 1, 0.12)
	panel.add_theme_stylebox_override("panel", style)

	if item != null:
		var icon = TextureRect.new()
		icon.texture = item.item_icon
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_left   = 5
		icon.offset_top    = 5
		icon.offset_right  = -5
		icon.offset_bottom = -16
		panel.add_child(icon)

		var name_label = Label.new()
		name_label.text = item.item_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment   = VERTICAL_ALIGNMENT_BOTTOM
		name_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		name_label.offset_bottom = -2
		name_label.add_theme_font_size_override("font_size", 8)
		name_label.modulate = Color(1, 1, 1, 0.85)
		panel.add_child(name_label)

	# Slot number badge (bottom-right corner)
	var num_label = Label.new()
	num_label.text = str(index + 1)
	num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	num_label.vertical_alignment   = VERTICAL_ALIGNMENT_BOTTOM
	num_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	num_label.offset_right  = -4
	num_label.offset_bottom = -2
	num_label.add_theme_font_size_override("font_size", 8)
	num_label.modulate = Color(1, 1, 1, 0.28)
	panel.add_child(num_label)

	return panel

# Returns the ItemData in the currently selected slot, or null if empty
func get_selected_item() -> ItemData:
	var items = InventoryManager.get_all_items()
	if selected_slot < items.size():
		return items[selected_slot]
	return null
