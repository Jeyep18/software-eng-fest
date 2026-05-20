# FILE: res://scripts/BackpackUI.gd
extends CanvasLayer

@onready var grid_container: GridContainer = $BackpackPanel/GridContainer
@onready var count_label: Label            = $BackpackPanel/TitleBar/CountLabel
@onready var info_icon: TextureRect        = $BackpackPanel/InfoBar/InfoIcon
@onready var info_name: Label              = $BackpackPanel/InfoBar/InfoName
@onready var info_desc: Label              = $BackpackPanel/InfoBar/InfoDesc
@onready var combine_bar: HBoxContainer    = $BackpackPanel/CombineBar
@onready var combine_label: Label          = $BackpackPanel/CombineBar/CombineLabel
@onready var combine_button: Button        = $BackpackPanel/CombineBar/CombineButton
@onready var backpack_panel: Panel         = $BackpackPanel
@onready var discard_slot: Panel           = $BackpackPanel/DiscardSlot
@onready var discard_prompt: Label         = $BackpackPanel/DiscardPrompt

const ITEMS_PATH: String = "res://game/resources/items/"
const INVENTORY_DRAG_SLOT_SCRIPT = preload("res://game/ui/BackpackUI/InventoryDragSlot.gd")

var _selected_index: int = -1
var _combine_target_index: int = -1
var _slot_panels: Array[Panel] = []

func _ready() -> void:
	add_to_group("backpack_ui")
	layer = 10
	visible = false
	grid_container.columns = 4

	# --- FIX THE PANEL SIZE AND LAYOUT HERE IN CODE ---
	# WHY: Doing it in code means it always applies correctly regardless
	# of what the scene editor shows. No manual tweaking needed.
	_setup_panel_layout()

	InventoryManager.inventory_changed.connect(_on_inventory_changed)
	InventoryManager.discard_changed.connect(_on_discard_changed)
	if is_instance_valid(combine_button):
		combine_button.pressed.connect(_on_combine_pressed)
	_hide_combine_bar()

func _setup_panel_layout() -> void:
	# Size the main panel
	backpack_panel.custom_minimum_size = Vector2(460, 450)

	# Anchor the panel to the CENTER of the screen
	backpack_panel.set_anchor_and_offset(SIDE_LEFT,   0.5, -230)
	backpack_panel.set_anchor_and_offset(SIDE_TOP,    0.5, -210)
	backpack_panel.set_anchor_and_offset(SIDE_RIGHT,  0.5,  230)
	backpack_panel.set_anchor_and_offset(SIDE_BOTTOM, 0.5,  240)

	# Give the panel a dark background style
	var panel_style := _make_panel_style(Color(0.1, 0.1, 0.1, 0.95), Color(1, 1, 1, 0.15), 1, 12)
	backpack_panel.add_theme_stylebox_override("panel", panel_style)

	# TitleBar — sits at the top
	var title_bar = $BackpackPanel/TitleBar
	title_bar.set_anchor_and_offset(SIDE_LEFT,   0, 12)
	title_bar.set_anchor_and_offset(SIDE_TOP,    0, 12)
	title_bar.set_anchor_and_offset(SIDE_RIGHT,  1, -12)
	title_bar.set_anchor_and_offset(SIDE_BOTTOM, 0, 40)

	# GridContainer — sits below title bar
	grid_container.set_anchor_and_offset(SIDE_LEFT,   0, 12)
	grid_container.set_anchor_and_offset(SIDE_TOP,    0, 48)
	grid_container.set_anchor_and_offset(SIDE_RIGHT,  1, -12)
	grid_container.set_anchor_and_offset(SIDE_BOTTOM, 0, 230)
	grid_container.add_theme_constant_override("h_separation", 8)
	grid_container.add_theme_constant_override("v_separation", 8)

	# InfoBar — sits below the grid
	var info_bar = $BackpackPanel/InfoBar
	info_bar.set_anchor_and_offset(SIDE_LEFT,   0, 12)
	info_bar.set_anchor_and_offset(SIDE_TOP,    0, 238)
	info_bar.set_anchor_and_offset(SIDE_RIGHT,  1, -116)
	info_bar.set_anchor_and_offset(SIDE_BOTTOM, 0, 318)
	info_bar.add_theme_constant_override("separation", 8)
	info_bar.alignment = BoxContainer.ALIGNMENT_BEGIN

	# InfoIcon — fixed size inside InfoBar
	info_icon.custom_minimum_size = Vector2(52, 52)
	info_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	info_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Text container — needs a VBoxContainer to stack name above desc
	# WHY: HBoxContainer puts icon and text side by side, but the text
	# needs its OWN vertical stack. We build it in code here.
	var text_box = info_bar.get_node_or_null("TextBox")
	if text_box == null:
		text_box = VBoxContainer.new()
		text_box.name = "TextBox"
		text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_box.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
		info_bar.add_child(text_box)
		# Move info_name and info_desc into this VBox
		info_name.reparent(text_box)
		info_desc.reparent(text_box)

	info_name.autowrap_mode = TextServer.AUTOWRAP_OFF
	info_name.clip_text = true
	info_name.add_theme_font_size_override("font_size", 13)

	info_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	info_desc.add_theme_font_size_override("font_size", 11)
	info_desc.modulate = Color(1, 1, 1, 0.55)
	info_desc.custom_minimum_size = Vector2(0, 0)

	# CombineBar — sits at the very bottom
	combine_bar.set_anchor_and_offset(SIDE_LEFT,   0, 12)
	combine_bar.set_anchor_and_offset(SIDE_TOP,    0, 360)
	combine_bar.set_anchor_and_offset(SIDE_RIGHT,  1, -12)
	combine_bar.set_anchor_and_offset(SIDE_BOTTOM, 0, 430)
	combine_bar.add_theme_constant_override("separation", 10)

	if is_instance_valid(discard_slot):
		discard_slot.mouse_filter = Control.MOUSE_FILTER_STOP
		discard_slot.z_index = 10
		discard_slot.set_anchor_and_offset(SIDE_LEFT, 1, -108)
		discard_slot.set_anchor_and_offset(SIDE_TOP, 0, 238)
		discard_slot.set_anchor_and_offset(SIDE_RIGHT, 1, -12)
		discard_slot.set_anchor_and_offset(SIDE_BOTTOM, 0, 318)

	if is_instance_valid(discard_prompt):
		discard_prompt.set_anchor_and_offset(SIDE_LEFT, 0, 12)
		discard_prompt.set_anchor_and_offset(SIDE_TOP, 0, 322)
		discard_prompt.set_anchor_and_offset(SIDE_RIGHT, 1, -12)
		discard_prompt.set_anchor_and_offset(SIDE_BOTTOM, 0, 354)
		discard_prompt.add_theme_font_size_override("font_size", 12)
		discard_prompt.add_theme_color_override("font_color", Color(1, 1, 1, 0.68))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_backpack"):
		_toggle()

func _toggle() -> void:
	if visible:
		close_backpack()
		return

	_close_map_if_open()
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_reset_selection()
	_redraw_backpack()

func close_backpack() -> void:
	if not visible:
		return
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_reset_selection()

func _close_map_if_open() -> void:
	var map_screen = get_tree().get_first_node_in_group("map_screen")
	if map_screen and map_screen.has_method("close_map"):
		map_screen.close_map()

func _on_inventory_changed() -> void:
	if not visible:
		return
	var item_count = InventoryManager.get_item_count()
	if _selected_index >= item_count:
		_selected_index = -1
	if _combine_target_index >= item_count:
		_combine_target_index = -1
	_redraw_backpack()

func _on_discard_changed() -> void:
	if not visible:
		return
	_refresh_info_bar()

func _redraw_backpack() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	_slot_panels.clear()

	var items = InventoryManager.get_all_items()
	count_label.text = str(items.size()) + " / " + str(InventoryManager.MAX_INVENTORY_SIZE)

	for i in range(InventoryManager.MAX_INVENTORY_SIZE):
		var item: ItemData = items[i] if i < items.size() else null
		var slot = _create_slot(item, i)
		grid_container.add_child(slot)
		_slot_panels.append(slot)

	_update_slot_highlights()
	_refresh_info_bar()
	_refresh_combine_bar()

func _create_slot(item: ItemData, index: int) -> Panel:
	var panel = Panel.new()
	panel.set_script(INVENTORY_DRAG_SLOT_SCRIPT)
	panel.call("setup", self, index, item)
	panel.custom_minimum_size = Vector2(88, 88)

	var slot_bg: Color = Color(0.14, 0.14, 0.14, 0.92) if item != null else Color(0.08, 0.08, 0.08, 0.6)
	var style := _make_panel_style(slot_bg, Color(1, 1, 1, 0.12), 1, 8)
	panel.add_theme_stylebox_override("panel", style)

	if item != null:
		var icon = TextureRect.new()
		icon.texture = item.item_icon
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_left   = 8
		icon.offset_top    = 8
		icon.offset_right  = -8
		icon.offset_bottom = -22
		icon.mouse_filter  = Control.MOUSE_FILTER_PASS
		panel.add_child(icon)

		var name_label = Label.new()
		name_label.text = item.item_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment   = VERTICAL_ALIGNMENT_BOTTOM
		name_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		name_label.offset_bottom = -3
		name_label.add_theme_font_size_override("font_size", 9)
		name_label.modulate = Color(1, 1, 1, 0.85)
		name_label.mouse_filter = Control.MOUSE_FILTER_PASS
		panel.add_child(name_label)

		var quantity: int = InventoryManager.get_item_quantity(index)
		if quantity > 1:
			var quantity_label = Label.new()
			quantity_label.text = "x%d" % quantity
			quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			quantity_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			quantity_label.offset_top = 4
			quantity_label.offset_right = -6
			quantity_label.add_theme_font_size_override("font_size", 12)
			quantity_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.62))
			quantity_label.mouse_filter = Control.MOUSE_FILTER_PASS
			panel.add_child(quantity_label)

		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		panel.gui_input.connect(_on_slot_gui_input.bind(index))
	else:
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	return panel

func _make_panel_style(bg_color: Color, border_color: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	_set_uniform_border_width(style, border_width)
	_set_uniform_corner_radius(style, radius)
	return style

func _set_uniform_border_width(style: StyleBoxFlat, width: int) -> void:
	style.border_width_left = width
	style.border_width_right = width
	style.border_width_top = width
	style.border_width_bottom = width

func _set_uniform_corner_radius(style: StyleBoxFlat, radius: int) -> void:
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius

func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		_on_slot_clicked(index)

func _on_slot_clicked(index: int) -> void:
	if _selected_index == -1:
		_selected_index = index
		_combine_target_index = -1
	elif index == _selected_index:
		_reset_selection()
		return
	else:
		_combine_target_index = index

	_update_slot_highlights()
	_refresh_info_bar()
	_refresh_combine_bar()

func _reset_selection() -> void:
	_selected_index = -1
	_combine_target_index = -1
	_update_slot_highlights()
	_refresh_info_bar()
	_hide_combine_bar()

func _update_slot_highlights() -> void:
	var items = InventoryManager.get_all_items()
	for i in range(_slot_panels.size()):
		var panel = _slot_panels[i]
		if not is_instance_valid(panel):
			continue
		var style = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if i == _selected_index:
			style.border_color = Color(1.0, 1.0, 1.0, 0.9)
			_set_uniform_border_width(style, 2)
			style.bg_color = Color(0.22, 0.22, 0.22, 0.95)
		elif i == _combine_target_index:
			style.border_color = Color(0.3, 0.9, 0.6, 0.95)
			_set_uniform_border_width(style, 2)
			style.bg_color = Color(0.1, 0.22, 0.16, 0.95)
		else:
			style.border_color = Color(1, 1, 1, 0.1)
			_set_uniform_border_width(style, 1)
			style.bg_color = Color(0.14, 0.14, 0.14, 0.92) if i < items.size() else Color(0.08, 0.08, 0.08, 0.6)
		panel.add_theme_stylebox_override("panel", style)

func _refresh_info_bar() -> void:
	var items = InventoryManager.get_all_items()
	var display_index = _combine_target_index if _combine_target_index != -1 else _selected_index

	if display_index >= 0 and display_index < items.size():
		var item = items[display_index]
		if is_instance_valid(info_icon): info_icon.texture = item.item_icon
		if is_instance_valid(info_name): info_name.text = item.item_name
		if is_instance_valid(info_desc): info_desc.text = item.item_description if item.item_description != "" else "No description."
	else:
		if is_instance_valid(info_icon): info_icon.texture = null
		if is_instance_valid(info_name): info_name.text = ""
		if is_instance_valid(info_desc): info_desc.text = "Click an item to inspect.\nClick a second item to combine."

func _refresh_combine_bar() -> void:
	if _selected_index == -1 or _combine_target_index == -1:
		_hide_combine_bar()
		return

	var result_id = InventoryManager.get_combine_result(_selected_index, _combine_target_index)

	if result_id == "":
		combine_bar.visible = true
		combine_label.text = "These items can't be combined."
		if is_instance_valid(combine_button):
			combine_button.visible = false
	else:
		combine_bar.visible = true
		var result_item = _load_item_by_id(result_id)
		var result_name = result_item.item_name if result_item else result_id
		combine_label.text = "Combine -> " + result_name
		if is_instance_valid(combine_button):
			combine_button.text = "Combine"
			combine_button.visible = true

func _hide_combine_bar() -> void:
	if is_instance_valid(combine_bar):
		combine_bar.visible = false

func _on_combine_pressed() -> void:
	if _selected_index == -1 or _combine_target_index == -1:
		return

	var result_id = InventoryManager.get_combine_result(_selected_index, _combine_target_index)
	if result_id == "":
		return

	var result_item = _load_item_by_id(result_id)
	if result_item == null:
		push_error("BackpackUI: Could not load result item: " + result_id)
		return

	# Store indices before reset, then reset before combine
	# WHY: inventory_changed fires during combine, which triggers _on_inventory_changed,
	# which calls _redraw_backpack. If selection isn't cleared first, it tries to
	# highlight slots that no longer exist and crashes.
	var a = _selected_index
	var b = _combine_target_index
	_reset_selection()
	InventoryManager.combine_items(a, b, result_item)

func _load_item_by_id(item_id: String) -> ItemData:
	# Try the primary path first
	var path = ITEMS_PATH + item_id + ".tres"
	if ResourceLoader.exists(path):
		return load(path) as ItemData

	# WHY this fallback: if your .tres files are in a subfolder or have
	# a different structure, this will print the attempted path so you
	# can see exactly what path the code is looking for.
	push_error("BackpackUI: .tres not found at: " + path + 
			   "\nMake sure your file is named exactly '" + item_id + ".tres'" +
			   "\nand lives in " + ITEMS_PATH)
	return null
