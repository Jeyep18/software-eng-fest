# Autoload singleton — registered as "ShopUI"
# Builds its own UI in code. No .tscn needed.
extends CanvasLayer

# ── Node References (built in _ready, not @onready) ──────────────────────────
var shop_panel:      PanelContainer
var shop_name_label: Label
var subtitle_label:  Label
var cash_label:      Label
var item_list:       VBoxContainer
var feedback_label:  Label
var close_button:    Button
var _backdrop:       ColorRect       # ← ADD THIS
var _center_container:    CenterContainer

# ── Internal State ─────────────────────────────────────────────────────────────
var _current_shop: ShopData = null
var _feedback_timer: SceneTreeTimer = null
var _shop_cache: Dictionary = {}

# ── Lifecycle ──────────────────────────────────────────────────────────────────
func _ready() -> void:
	layer = 8
	_build_ui()
	_backdrop.hide()            
	_center_container.hide()
	shop_panel.hide()
	close_button.pressed.connect(close_shop)
	GameState.cash_changed.connect(_on_cash_changed)

func _build_ui() -> void:
	# ── Full-screen dimmed backdrop ───────────────────────────────────────────
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0, 0, 0, 0.55)
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_backdrop)
	
	# ── Centered wrapper ──────────────────────────────────────────────────────
	_center_container = CenterContainer.new()
	_center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_center_container)

	# ── Root panel ────────────────────────────────────────────────────────────
	shop_panel = PanelContainer.new()
	shop_panel.custom_minimum_size = Vector2(520, 460)
	_center_container.add_child(shop_panel)      # ← parented to CenterContainer

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	shop_panel.add_child(root_vbox)

	# ── Header ────────────────────────────────────────────────────────────────
	var header := VBoxContainer.new()
	root_vbox.add_child(header)

	shop_name_label = Label.new()
	shop_name_label.add_theme_font_size_override("font_size", 18)
	shop_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(shop_name_label)

	subtitle_label = Label.new()
	subtitle_label.add_theme_font_size_override("font_size", 11)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.modulate = Color(1, 1, 1, 0.6)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(subtitle_label)

	root_vbox.add_child(HSeparator.new())

	# ── Cash row ──────────────────────────────────────────────────────────────
	var cash_row := HBoxContainer.new()
	root_vbox.add_child(cash_row)

	var cash_icon := Label.new()
	cash_icon.text = "Cash:  ₱"
	cash_icon.add_theme_font_size_override("font_size", 13)
	cash_row.add_child(cash_icon)

	cash_label = Label.new()
	cash_label.add_theme_font_size_override("font_size", 13)
	cash_row.add_child(cash_label)

	root_vbox.add_child(HSeparator.new())

	# ── Scroll + item list ────────────────────────────────────────────────────
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 240)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(scroll)

	item_list = VBoxContainer.new()
	item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_list.add_theme_constant_override("separation", 6)
	scroll.add_child(item_list)

	root_vbox.add_child(HSeparator.new())

	# ── Feedback label ────────────────────────────────────────────────────────
	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 12)
	feedback_label.hide()
	root_vbox.add_child(feedback_label)

	# ── Close button ──────────────────────────────────────────────────────────
	close_button = Button.new()
	close_button.text = "Isara / Close  [E]"
	close_button.custom_minimum_size = Vector2(0, 36)
	root_vbox.add_child(close_button)

# ── Public API ─────────────────────────────────────────────────────────────────
func open_shop(shop_data: ShopData) -> void:
	if shop_data == null:
		push_error("ShopUI.open_shop(): called with null ShopData.")
		return
	
	var cache_key: String = shop_data.resource_path
	if cache_key == "":
		push_error("ShopUI: ShopData has no resource_path — stock persistence won't work. Save it as a .tres file.")
		_current_shop = shop_data  # use as-is, no caching
	else:
		if not _shop_cache.has(cache_key):
			_shop_cache[cache_key] = shop_data.duplicate(true)
		_current_shop = _shop_cache[cache_key]
	
	shop_name_label.text   = _current_shop.shop_name
	subtitle_label.text    = _current_shop.shop_subtitle
	subtitle_label.visible = _current_shop.shop_subtitle != ""
	_refresh_cash()
	_rebuild_item_list()
	_clear_feedback()
	_backdrop.show()
	_center_container.show()
	shop_panel.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close_shop() -> void:
	shop_panel.hide()
	_center_container.hide()   
	_backdrop.hide()
	_current_shop = null
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func is_open() -> bool:
	return shop_panel.visible

# ── Input ──────────────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		close_shop()

# ── UI Build ───────────────────────────────────────────────────────────────────
func _rebuild_item_list() -> void:
	for child in item_list.get_children():
		child.queue_free()
	if _current_shop == null:
		return
	for shop_item in _current_shop.items:
		item_list.add_child(_build_item_row(shop_item))

func _build_item_row(shop_item: ShopItem) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 56)
	row.add_theme_constant_override("separation", 10)

	# Icon
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if shop_item.item_data and shop_item.item_data.item_icon:
		icon.texture = shop_item.item_data.item_icon
	row.add_child(icon)

	# Name + description
	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_lbl := Label.new()
	name_lbl.text = shop_item.item_data.item_name if shop_item.item_data else "???"
	name_lbl.add_theme_font_size_override("font_size", 13)
	text_col.add_child(name_lbl)
	if shop_item.item_data and shop_item.item_data.item_description != "":
		var desc := Label.new()
		desc.text = shop_item.item_data.item_description
		desc.add_theme_font_size_override("font_size", 10)
		desc.modulate = Color(1, 1, 1, 0.55)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_col.add_child(desc)
	row.add_child(text_col)

	# Stock label
	if shop_item.stock != -1:
		var stock_lbl := Label.new()
		stock_lbl.text = "x%d" % shop_item.stock
		stock_lbl.add_theme_font_size_override("font_size", 11)
		stock_lbl.modulate = Color(1, 1, 1, 0.55)
		stock_lbl.custom_minimum_size = Vector2(32, 0)
		stock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(stock_lbl)

	# Buy button
	var buy_btn := Button.new()
	var is_barter_only := (shop_item.price <= 0)
	var out_of_stock   := not shop_item.is_in_stock()

	if is_barter_only:
		buy_btn.text     = "Barter only"
		buy_btn.disabled = true
		buy_btn.modulate = Color(1, 1, 1, 0.45)
	elif out_of_stock:
		buy_btn.text     = "Out of stock"
		buy_btn.disabled = true
		buy_btn.modulate = Color(1, 1, 1, 0.45)
	else:
		buy_btn.text = "₱%d" % shop_item.price
		var can_afford := GameState.get_cash() >= shop_item.price
		buy_btn.disabled = not can_afford
		if not can_afford:
			buy_btn.modulate = Color(0.9, 0.4, 0.4)
		var captured := shop_item
		buy_btn.pressed.connect(func() -> void: _on_buy_pressed(captured))

	buy_btn.custom_minimum_size = Vector2(90, 36)
	row.add_child(buy_btn)
	return row

# ── Purchase ───────────────────────────────────────────────────────────────────
func _on_buy_pressed(shop_item: ShopItem) -> void:
	var original_price := shop_item.item_data.item_price
	shop_item.item_data.item_price = shop_item.price
	var success := EconomyManager.purchase(shop_item.item_data)
	shop_item.item_data.item_price = original_price

	if success:
		shop_item.consume_stock()
		_show_feedback("Nabili! " + shop_item.item_data.item_name + " — nasa bag mo na.", Color(0.5, 0.9, 0.5))
	else:
		if InventoryManager.is_full():
			_show_feedback("Puno na ang bag mo. Mag-iwan muna ng item.", Color(0.9, 0.5, 0.3))
		elif GameState.get_cash() < shop_item.price:
			_show_feedback("Hindi sapat ang pera. Kulang ng ₱%d." % (shop_item.price - GameState.get_cash()), Color(0.9, 0.4, 0.4))
		else:
			_show_feedback("Hindi nabili.", Color(0.9, 0.4, 0.4))
	_rebuild_item_list()

# ── Feedback ───────────────────────────────────────────────────────────────────
func _show_feedback(message: String, col: Color = Color.WHITE) -> void:
	feedback_label.text     = message
	feedback_label.modulate = col
	feedback_label.show()
	_feedback_timer = get_tree().create_timer(2.5)
	_feedback_timer.timeout.connect(func() -> void:
		if feedback_label: feedback_label.hide()
		_feedback_timer = null
	)

func _clear_feedback() -> void:
	feedback_label.text = ""
	feedback_label.hide()

func _refresh_cash() -> void:
	cash_label.text = "%d" % GameState.get_cash()

func _on_cash_changed(new_balance: int) -> void:
	if is_open():
		cash_label.text = "%d" % new_balance

func reset() -> void:
	_shop_cache.clear()
	_current_shop = null
	close_shop()
