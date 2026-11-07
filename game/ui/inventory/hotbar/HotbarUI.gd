# FILE: res://game/ui/inventory/hotbar/HotbarUI.gd
# ATTACH TO: Root CanvasLayer of HotbarUI.tscn
# PURPOSE: Inventory hotbar at the bottom of the screen.
# - Displays the full inventory; dialogue/task flows can temporarily hide it.
# - Uses InventoryManager's slot capacity.
# - Opens through the backpack's Tab action; this bar is a passive preview.
# - Sits at a LOW layer value so backpack/ESC menu render on top

extends CanvasLayer

@onready var slot_container: HBoxContainer = $HotbarRoot/SlotContainer
@onready var hotbar_bg: Panel = $HotbarRoot/HotbarBG
@onready var hotbar_root: Control = $HotbarRoot
const BASE_SLOT_SIZE: float = 62.0
const BASE_SLOT_GAP: float = 8.0
const BASE_VERTICAL_PADDING: float = 10.0
const BASE_BOTTOM_MARGIN: float = 18.0

var _slot_panels: Array[Panel] = []
var _slot_items: Array[ItemData] = []
var _slot_quantities: Array[int] = []
var _normal_style: StyleBoxFlat
var _ui_scale: float = 1.0

func _ready() -> void:
	add_to_group("hotbar_ui")
	# LOW layer number = renders BEHIND other CanvasLayers.
	# BackpackUI and ESC menu should use a higher layer (e.g. 10).
	layer = 1

	InventoryManager.inventory_changed.connect(_redraw_hotbar)
	LocalizationManager.language_changed.connect(_on_language_changed)
	VisualSettings.ui_scale_changed.connect(func(_scale: float) -> void: _apply_ui_scale())
	get_viewport().size_changed.connect(_apply_ui_scale)
	_apply_ui_scale()
	_on_language_changed(LocalizationManager.get_language())

func _on_language_changed(_language_id: String) -> void:
	_redraw_hotbar()

func _redraw_hotbar() -> void:
	var items = InventoryManager.get_all_items()
	_ensure_slot_nodes()

	for i in range(InventoryManager.MAX_INVENTORY_SIZE):
		var item: ItemData = null
		if i < items.size():
			item = items[i]
		var quantity := InventoryManager.get_item_quantity(i)
		if _slot_items[i] != item or _slot_quantities[i] != quantity:
			_update_slot(_slot_panels[i], item, quantity)
			_slot_items[i] = item
			_slot_quantities[i] = quantity

func _ensure_slot_nodes() -> void:
	while _slot_panels.size() < InventoryManager.MAX_INVENTORY_SIZE:
		var index := _slot_panels.size()
		var slot := _create_slot(index)
		slot_container.add_child(slot)
		_slot_panels.append(slot)
		_slot_items.append(null)
		_slot_quantities.append(-1)

func _create_slot(index: int) -> Panel:
	var panel = Panel.new()
	var ui_scale := _ui_scale
	panel.custom_minimum_size = Vector2(BASE_SLOT_SIZE, BASE_SLOT_SIZE) * ui_scale
	panel.add_theme_stylebox_override("panel", _normal_style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_meta("slot_index", index)
	return panel

func _update_slot(panel: Panel, item: ItemData, quantity: int) -> void:
	var ui_scale := _ui_scale
	for child in panel.get_children():
		child.queue_free()

	if item != null:
		var icon = TextureRect.new()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_label.text = item.get_item_name()
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment   = VERTICAL_ALIGNMENT_BOTTOM
		name_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		name_label.offset_bottom = -2 * ui_scale
		name_label.add_theme_font_size_override("font_size", int(roundi(8.0 * ui_scale)))
		name_label.modulate = Color(1, 1, 1, 0.85)
		panel.add_child(name_label)

		if quantity > 1:
			var quantity_badge = PanelContainer.new()
			quantity_badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
			quantity_badge.offset_left = -30 * ui_scale
			quantity_badge.offset_top = 2 * ui_scale
			quantity_badge.offset_right = -2 * ui_scale
			quantity_badge.offset_bottom = 24 * ui_scale
			quantity_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var badge_style := StyleBoxFlat.new()
			badge_style.bg_color = Color(0.03, 0.025, 0.015, 0.95)
			badge_style.border_color = Color(1.0, 0.86, 0.28, 1.0)
			badge_style.border_width_left = 1
			badge_style.border_width_right = 1
			badge_style.border_width_top = 1
			badge_style.border_width_bottom = 1
			badge_style.corner_radius_top_left = 5
			badge_style.corner_radius_top_right = 5
			badge_style.corner_radius_bottom_left = 5
			badge_style.corner_radius_bottom_right = 5
			quantity_badge.add_theme_stylebox_override("panel", badge_style)
			panel.add_child(quantity_badge)

			var quantity_label = Label.new()
			quantity_label.text = str(quantity)
			quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			quantity_label.add_theme_font_size_override("font_size", int(roundi(15.0 * ui_scale)))
			quantity_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.58))
			quantity_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
			quantity_label.add_theme_constant_override("shadow_offset_x", 1)
			quantity_label.add_theme_constant_override("shadow_offset_y", 1)
			quantity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			quantity_badge.add_child(quantity_label)

# Keep the public parameter name; this sets visibility rather than querying it.
@warning_ignore("shadowed_variable_base_class")
func set_hotbar_visible(is_visible: bool) -> void:
	self.visible = is_visible

func _apply_ui_scale() -> void:
	var slot_count: int = InventoryManager.MAX_INVENTORY_SIZE
	var base_width := BASE_SLOT_SIZE * slot_count + BASE_SLOT_GAP * (slot_count - 1)
	_ui_scale = minf(VisualSettings.get_ui_scale(), (get_viewport().get_visible_rect().size.x - 32.0) / base_width)
	var ui_scale := _ui_scale
	_rebuild_style_cache()
	var gap: float = BASE_SLOT_GAP * ui_scale
	var slot_size: float = BASE_SLOT_SIZE * ui_scale
	var slot_width: float = (slot_size * float(slot_count)) + (gap * float(max(slot_count - 1, 0)))
	var width := base_width * ui_scale
	var height: float = slot_size + (BASE_VERTICAL_PADDING * 2.0 * ui_scale)

	hotbar_root.anchor_left = 0.5
	hotbar_root.anchor_right = 0.5
	hotbar_root.anchor_top = 1.0
	hotbar_root.anchor_bottom = 1.0
	hotbar_root.offset_left = -width * 0.5
	hotbar_root.offset_right = width * 0.5
	hotbar_root.offset_top = -(height + BASE_BOTTOM_MARGIN * ui_scale)
	hotbar_root.offset_bottom = -BASE_BOTTOM_MARGIN * ui_scale

	hotbar_bg.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	hotbar_bg.offset_left = 0.0
	hotbar_bg.offset_top = 0.0
	hotbar_bg.offset_right = slot_width
	hotbar_bg.offset_bottom = 0.0
	hotbar_bg.custom_minimum_size = Vector2(slot_width, height)

	slot_container.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	slot_container.offset_left = 0.0
	slot_container.offset_right = slot_width
	slot_container.offset_top = -slot_size * 0.5
	slot_container.offset_bottom = slot_size * 0.5
	slot_container.add_theme_constant_override("separation", int(roundi(gap)))
	for i in range(_slot_panels.size()):
		var panel := _slot_panels[i]
		panel.custom_minimum_size = Vector2(BASE_SLOT_SIZE, BASE_SLOT_SIZE) * ui_scale
		panel.add_theme_stylebox_override("panel", _normal_style)
		_slot_items[i] = null
		_slot_quantities[i] = -1
	_redraw_hotbar()

func _rebuild_style_cache() -> void:
	_normal_style = StyleBoxFlat.new()
	_normal_style.bg_color = Color(0.13, 0.13, 0.13, 0.85)
	_normal_style.corner_radius_top_left = 7
	_normal_style.corner_radius_top_right = 7
	_normal_style.corner_radius_bottom_left = 7
	_normal_style.corner_radius_bottom_right = 7
	_normal_style.border_width_left = 1
	_normal_style.border_width_right = 1
	_normal_style.border_width_top = 1
	_normal_style.border_width_bottom = 1
	_normal_style.border_color = Color(1, 1, 1, 0.12)
