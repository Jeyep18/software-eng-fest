# FILE: res://scripts/HotbarUI.gd
# ATTACH TO: Root CanvasLayer of HotbarUI.tscn
# PURPOSE: Always-visible hotbar at the bottom of the screen.
# - Never hides (no tab toggle)
# - Shows 8 slots (the full inventory)
# - Highlights the currently selected slot
# - Sits at a LOW layer value so backpack/ESC menu render on top

extends CanvasLayer

@onready var slot_container: HBoxContainer = $HotbarRoot/SlotContainer
@onready var hotbar_bg: Panel = $HotbarRoot/HotbarBG
@onready var hotbar_root: Control = $HotbarRoot

const BASE_SLOT_SIZE: float = 62.0
const BASE_SLOT_GAP: float = 8.0
const BASE_VERTICAL_PADDING: float = 10.0
const BASE_BOTTOM_MARGIN: float = 18.0

# The currently "held" / selected slot index (0-7)
var selected_slot: int = 0

# Track slot Panel nodes so we can update selection highlight without full rebuild
var _slot_panels: Array[Panel] = []

func _ready() -> void:
	add_to_group("hotbar_ui")
	# LOW layer number = renders BEHIND other CanvasLayers.
	# BackpackUI and ESC menu should use a higher layer (e.g. 10).
	layer = 1

	InventoryManager.inventory_changed.connect(_redraw_hotbar)
	LocalizationManager.language_changed.connect(func(_language_id: String) -> void: _redraw_hotbar())
	VisualSettings.ui_scale_changed.connect(func(_scale: float) -> void:
		_apply_ui_scale()
		_redraw_hotbar()
	)
	_apply_ui_scale()
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
	var ui_scale := VisualSettings.get_ui_scale()
	panel.custom_minimum_size = Vector2(BASE_SLOT_SIZE, BASE_SLOT_SIZE) * ui_scale

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
		icon.offset_left   = 5 * ui_scale
		icon.offset_top    = 5 * ui_scale
		icon.offset_right  = -5 * ui_scale
		icon.offset_bottom = -16 * ui_scale
		panel.add_child(icon)

		var name_label = Label.new()
		name_label.text = item.get_item_name()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment   = VERTICAL_ALIGNMENT_BOTTOM
		name_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		name_label.offset_bottom = -2 * ui_scale
		name_label.add_theme_font_size_override("font_size", int(roundi(8.0 * ui_scale)))
		name_label.modulate = Color(1, 1, 1, 0.85)
		panel.add_child(name_label)

		var quantity: int = InventoryManager.get_item_quantity(index)
		if quantity > 1:
			var quantity_label = Label.new()
			quantity_label.text = "x%d" % quantity
			quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			quantity_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			quantity_label.offset_top = 2 * ui_scale
			quantity_label.offset_right = -4 * ui_scale
			quantity_label.add_theme_font_size_override("font_size", int(roundi(10.0 * ui_scale)))
			quantity_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.62))
			panel.add_child(quantity_label)

	# Slot number badge (bottom-right corner)
	var num_label = Label.new()
	num_label.text = str(index + 1)
	num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	num_label.vertical_alignment   = VERTICAL_ALIGNMENT_BOTTOM
	num_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	num_label.offset_right  = -4 * ui_scale
	num_label.offset_bottom = -2 * ui_scale
	num_label.add_theme_font_size_override("font_size", int(roundi(8.0 * ui_scale)))
	num_label.modulate = Color(1, 1, 1, 0.28)
	panel.add_child(num_label)

	return panel

# Returns the ItemData in the currently selected slot, or null if empty
func get_selected_item() -> ItemData:
	var items = InventoryManager.get_all_items()
	if selected_slot < items.size():
		return items[selected_slot]
	return null

func set_hotbar_visible(is_visible: bool) -> void:
	self.visible = is_visible

func _apply_ui_scale() -> void:
	var scale: float = VisualSettings.get_ui_scale()
	var slot_count: int = InventoryManager.MAX_INVENTORY_SIZE
	var gap: float = BASE_SLOT_GAP * scale
	var slot_size: float = BASE_SLOT_SIZE * scale
	var width: float = (slot_size * float(slot_count)) + (gap * float(max(slot_count - 1, 0)))
	var height: float = slot_size + (BASE_VERTICAL_PADDING * 2.0 * scale)

	hotbar_root.anchor_left = 0.5
	hotbar_root.anchor_right = 0.5
	hotbar_root.anchor_top = 1.0
	hotbar_root.anchor_bottom = 1.0
	hotbar_root.offset_left = -width * 0.5
	hotbar_root.offset_right = width * 0.5
	hotbar_root.offset_top = -(height + BASE_BOTTOM_MARGIN * scale)
	hotbar_root.offset_bottom = -BASE_BOTTOM_MARGIN * scale

	hotbar_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	hotbar_bg.offset_left = 0.0
	hotbar_bg.offset_top = 0.0
	hotbar_bg.offset_right = 0.0
	hotbar_bg.offset_bottom = 0.0
	hotbar_bg.custom_minimum_size = Vector2(width, height)

	slot_container.set_anchors_preset(Control.PRESET_CENTER)
	slot_container.offset_left = -width * 0.5
	slot_container.offset_right = width * 0.5
	slot_container.offset_top = -slot_size * 0.5
	slot_container.offset_bottom = slot_size * 0.5
	slot_container.add_theme_constant_override("separation", int(roundi(gap)))
