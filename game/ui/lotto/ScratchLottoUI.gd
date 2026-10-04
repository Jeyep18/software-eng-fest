class_name ScratchLottoUI
extends CanvasLayer

signal closed

const RULES = preload("res://game/ui/lotto/ScratchLottoRules.gd")
const SLOT_SCRIPT = preload("res://game/ui/lotto/ScratchLottoSlot.gd")
const UI_STYLE = preload("res://game/ui/GameUIStyle.gd")
const TICKET_FACE: Texture2D = preload("res://game/assets/scratch_lotto/scratch_ticket_face.png")
const FRUIT_ATLAS: Texture2D = preload("res://game/assets/scratch_lotto/scratch_fruit_atlas.png")
const FOIL_COVER: Texture2D = preload("res://game/assets/scratch_lotto/scratch_foil_cover.png")
const ATLAS_REGIONS := {
	"apple": Rect2(0, 0, 522, 403),
	"orange": Rect2(522, 0, 521, 403),
	"watermelon": Rect2(0, 403, 522, 362),
	"grapes": Rect2(522, 403, 521, 362),
	"cherries": Rect2(0, 765, 522, 351),
	"banana": Rect2(522, 765, 521, 351),
	"raspberry": Rect2(0, 1116, 522, 392),
	"peach": Rect2(522, 1116, 521, 392),
}
const SLOT_CENTERS := [
	Vector2(0.274, 0.374), Vector2(0.500, 0.374), Vector2(0.726, 0.374),
	Vector2(0.274, 0.634), Vector2(0.500, 0.634), Vector2(0.726, 0.634),
]

var _rng := RandomNumberGenerator.new()
var _ticket: Array[String] = []
var _ticket_count: int = 0
var _payout: int = 0
var _settled: bool = true
var _open: bool = false
var _base_foil: Image
var _slots: Array[ScratchLottoSlot] = []
var _prize_labels: Array[Label] = []
var _prize_icons: Array[TextureRect] = []

var _backdrop: ColorRect
var _center: CenterContainer
var _panel: PanelContainer
var _content: VBoxContainer
var _heading: Label
var _cash_label: Label
var _count_label: Label
var _rule_label: Label
var _ticket_area: Control
var _ticket_title: Label
var _result_label: Label
var _prizes_heading: Label
var _prize_grid: GridContainer
var _button_row: HBoxContainer
var _buy_button: Button
var _scratch_all_button: Button
var _close_button: Button


func _ready() -> void:
	layer = 12
	_rng.randomize()
	_base_foil = FOIL_COVER.get_image()
	if _base_foil.is_compressed():
		_base_foil.decompress()
	_base_foil.resize(ScratchLottoSlot.MASK_WIDTH, ScratchLottoSlot.MASK_HEIGHT, Image.INTERPOLATE_BILINEAR)
	_build_ui()
	_backdrop.hide()
	_center.hide()
	GameState.cash_changed.connect(_on_cash_changed)
	LocalizationManager.language_changed.connect(_on_language_changed)
	VisualSettings.ui_scale_changed.connect(_on_ui_scale_changed)
	GlobalTimer.storm_arrived.connect(_on_storm_arrived)
	get_viewport().size_changed.connect(_layout_ui)
	_layout_ui()
	_refresh_text()


func _build_ui() -> void:
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0.0, 0.0, 0.0, 0.72)
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_backdrop)

	_center = CenterContainer.new()
	_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_center)
	_panel = PanelContainer.new()
	UI_STYLE.apply_panel(_panel)
	_center.add_child(_panel)
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 14)
	_panel.add_child(margin)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 7)
	margin.add_child(_content)

	var header := HBoxContainer.new()
	_content.add_child(header)
	_heading = _make_label(true)
	_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_heading)
	_count_label = _make_label()
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_count_label)

	_cash_label = _make_label()
	_content.add_child(_cash_label)
	_rule_label = _make_label(true)
	_rule_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(_rule_label)

	_ticket_area = Control.new()
	_ticket_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ticket_area.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_ticket_area.resized.connect(_layout_ticket_slots)
	_content.add_child(_ticket_area)
	var ticket_face := TextureRect.new()
	ticket_face.texture = TICKET_FACE
	ticket_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ticket_face.stretch_mode = TextureRect.STRETCH_SCALE
	ticket_face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ticket_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ticket_area.add_child(ticket_face)

	_ticket_title = _make_label(true)
	_ticket_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ticket_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_ticket_label(_ticket_title, 0.18, 0.82, 0.14, 0.225)
	for _index in RULES.SLOT_COUNT:
		var slot := SLOT_SCRIPT.new() as ScratchLottoSlot
		_ticket_area.add_child(slot)
		_slots.append(slot)
		slot.revealed.connect(_on_slot_revealed)
	_result_label = _make_label()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place_ticket_label(_result_label, 0.18, 0.82, 0.78, 0.87)

	_prizes_heading = _make_label(true)
	_prizes_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(_prizes_heading)
	_prize_grid = GridContainer.new()
	_prize_grid.columns = 2
	_content.add_child(_prize_grid)
	for index in RULES.FRUIT_IDS.size():
		var prize_entry := HBoxContainer.new()
		prize_entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_prize_grid.add_child(prize_entry)
		var icon := TextureRect.new()
		icon.texture = _fruit_crop(RULES.FRUIT_IDS[index])
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		prize_entry.add_child(icon)
		_prize_icons.append(icon)
		var prize_label := _make_label()
		prize_entry.add_child(prize_label)
		_prize_labels.append(prize_label)

	_button_row = HBoxContainer.new()
	_button_row.add_theme_constant_override("separation", 8)
	_content.add_child(_button_row)
	_buy_button = _make_button()
	_buy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_buy_button.pressed.connect(_on_buy_pressed)
	_button_row.add_child(_buy_button)
	_scratch_all_button = _make_button()
	_scratch_all_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scratch_all_button.pressed.connect(reveal_all)
	_button_row.add_child(_scratch_all_button)
	_close_button = _make_button()
	_close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_close_button.pressed.connect(request_close)
	_button_row.add_child(_close_button)


func _make_label(accent: bool = false) -> Label:
	var label := Label.new()
	UI_STYLE.apply_label(label, false, accent)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_button() -> Button:
	var button := Button.new()
	UI_STYLE.apply_button(button)
	return button


func _place_ticket_label(label: Label, left: float, right: float, top: float, bottom: float) -> void:
	_ticket_area.add_child(label)
	label.set_anchor_and_offset(SIDE_RIGHT, right, 0.0)
	label.set_anchor_and_offset(SIDE_LEFT, left, 0.0)
	label.set_anchor_and_offset(SIDE_BOTTOM, bottom, 0.0)
	label.set_anchor_and_offset(SIDE_TOP, top, 0.0)


func _fruit_crop(fruit_id: String) -> Texture2D:
	var crop := AtlasTexture.new()
	crop.atlas = FRUIT_ATLAS
	crop.region = ATLAS_REGIONS[fruit_id]
	return crop


func _layout_ui() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var fit := minf((viewport_size.x - 32.0) / 720.0, (viewport_size.y - 32.0) / 780.0)
	var scale := minf(VisualSettings.get_ui_scale(), maxf(fit, 0.55))
	_panel.custom_minimum_size = Vector2(700.0 * scale, 0.0)
	_ticket_area.custom_minimum_size = Vector2(600.0, 450.0) * scale
	_content.add_theme_constant_override("separation", roundi(7.0 * scale))
	_heading.add_theme_font_size_override("font_size", roundi(26.0 * scale))
	_count_label.add_theme_font_size_override("font_size", roundi(17.0 * scale))
	_cash_label.add_theme_font_size_override("font_size", roundi(19.0 * scale))
	_rule_label.add_theme_font_size_override("font_size", roundi(17.0 * scale))
	_ticket_title.add_theme_font_size_override("font_size", roundi(25.0 * scale))
	_result_label.add_theme_font_size_override("font_size", roundi(19.0 * scale))
	_prizes_heading.add_theme_font_size_override("font_size", roundi(17.0 * scale))
	_prize_grid.add_theme_constant_override("h_separation", roundi(16.0 * scale))
	_prize_grid.add_theme_constant_override("v_separation", roundi(2.0 * scale))
	for index in _prize_labels.size():
		_prize_labels[index].add_theme_font_size_override("font_size", roundi(15.0 * scale))
		_prize_icons[index].custom_minimum_size = Vector2(24.0, 24.0) * scale
	for button in [_buy_button, _scratch_all_button, _close_button]:
		button.add_theme_font_size_override("font_size", roundi(17.0 * scale))
		button.custom_minimum_size.y = 43.0 * scale
	_layout_ticket_slots.call_deferred()


func _layout_ticket_slots() -> void:
	if _ticket_area == null:
		return
	var ticket_size := _ticket_area.size
	if ticket_size.x <= 0.0 or ticket_size.y <= 0.0:
		ticket_size = _ticket_area.custom_minimum_size
	for index in _slots.size():
		var slot_size := Vector2(ticket_size.x * 0.17, ticket_size.y * 0.19)
		_slots[index].size = slot_size
		_slots[index].position = SLOT_CENTERS[index] * ticket_size - slot_size * 0.5


func open_ui() -> void:
	if _open or SceneManager.storm_transition_pending or GlobalTimer.current_minutes >= GlobalTimer.TOTAL_MINUTES:
		return
	_close_other_menus()
	_open = true
	add_to_group("lotto_ui")
	_backdrop.show()
	_center.show()
	get_tree().call_group("player", "set_movement_locked", true)
	CursorState.request_visible(self)
	_refresh_text()
	_buy_button.grab_focus()


func is_open() -> bool:
	return _open


func buy_ticket() -> bool:
	if not _open or not _settled or SceneManager.storm_transition_pending or GlobalTimer.current_minutes >= GlobalTimer.TOTAL_MINUTES:
		return false
	if not GameState.spend_cash(RULES.TICKET_PRICE):
		_result_label.text = LocalizationManager.translate_key("lotto.not_enough_cash", "Not enough cash for a ticket.")
		_refresh_buttons()
		return false
	_ticket = RULES.roll_ticket(_rng)
	_ticket_count += 1
	_payout = 0
	_settled = false
	for index in _slots.size():
		_slots[index].show_fruit(FRUIT_ATLAS, ATLAS_REGIONS[_ticket[index]], _base_foil)
	_refresh_text()
	return true


func reveal_all() -> void:
	if _settled:
		return
	for slot in _slots:
		slot.reveal()
	_settle_ticket()


func request_close() -> void:
	if not _open:
		return
	if not _settled:
		reveal_all()
		return
	_close_ui()


func force_close() -> void:
	if not _settled:
		reveal_all()
	_close_ui()


func _close_ui() -> void:
	if not _open:
		return
	_open = false
	remove_from_group("lotto_ui")
	_backdrop.hide()
	_center.hide()
	CursorState.release_visible(self)
	get_tree().call_group("player", "set_movement_locked", false)
	closed.emit()


func _close_other_menus() -> void:
	var map_screen := get_tree().get_first_node_in_group("map_screen")
	if map_screen != null and map_screen.has_method("close_map"):
		map_screen.close_map()
	var backpack := get_tree().get_first_node_in_group("backpack_ui")
	if backpack != null and backpack.has_method("close_backpack"):
		backpack.close_backpack()


func _settle_ticket() -> void:
	if _ticket.is_empty() or _settled:
		return
	_settled = true
	_payout = RULES.calculate_payout(_ticket)
	if _payout > 0:
		GameState.add_cash(_payout)
	_refresh_result()
	_refresh_buttons()


func _on_slot_revealed() -> void:
	if _settled:
		return
	for slot in _slots:
		if not slot.is_revealed():
			return
	_settle_ticket()


func _on_buy_pressed() -> void:
	buy_ticket()


func _on_cash_changed(_new_balance: int) -> void:
	_refresh_cash()
	_refresh_buttons()


func _on_language_changed(_language_id: String) -> void:
	_refresh_text()


func _on_ui_scale_changed(_scale: float) -> void:
	_layout_ui()


func _on_storm_arrived() -> void:
	force_close()


func _refresh_text() -> void:
	_heading.text = LocalizationManager.translate_key("lotto.title", "LOTTOHAN")
	_rule_label.text = LocalizationManager.translate_key("lotto.rule", "Match three fruit in either row. Each matching row pays.")
	_ticket_title.text = LocalizationManager.translate_key("lotto.ticket_title", "SUERTE SCRATCH")
	_prizes_heading.text = LocalizationManager.translate_key("lotto.prizes", "PRIZES PER ROW")
	for index in RULES.FRUIT_IDS.size():
		var fruit_id: String = RULES.FRUIT_IDS[index]
		var name := LocalizationManager.translate_key("lotto.fruit." + fruit_id, fruit_id.capitalize())
		_prize_labels[index].text = "%s  —  ₱%d" % [name, RULES.PRIZES[index]]
	_refresh_cash()
	_count_label.text = LocalizationManager.trfk("lotto.ticket_count", [_ticket_count], "Tickets bought: %d")
	_refresh_result()
	_refresh_buttons()


func _refresh_cash() -> void:
	_cash_label.text = LocalizationManager.trfk("lotto.cash", [GameState.get_cash()], "Cash: ₱%d")


func _refresh_result() -> void:
	if _ticket.is_empty():
		_result_label.text = LocalizationManager.translate_key("lotto.ready", "Buy a ticket to try your luck.")
	elif not _settled:
		_result_label.text = LocalizationManager.translate_key("lotto.scratch", "Scratch all six fruit to reveal your result.")
	elif _payout > 0:
		_result_label.text = LocalizationManager.trfk("lotto.win", [_payout], "You won ₱%d!")
	else:
		_result_label.text = LocalizationManager.translate_key("lotto.lose", "No matching row. Try again?")


func _refresh_buttons() -> void:
	var can_buy := _open and _settled and GameState.get_cash() >= RULES.TICKET_PRICE and not SceneManager.storm_transition_pending
	_buy_button.disabled = not can_buy
	_buy_button.text = LocalizationManager.translate_key("lotto.buy_again", "Buy Again — ₱50") if _ticket_count > 0 else LocalizationManager.translate_key("lotto.buy", "Buy Ticket — ₱50")
	_scratch_all_button.disabled = _settled
	_scratch_all_button.text = LocalizationManager.translate_key("lotto.scratch_all", "Scratch All")
	_close_button.text = LocalizationManager.translate_key("lotto.reveal_result", "Reveal Result") if not _settled else LocalizationManager.translate_key("lotto.close", "Close")


func _exit_tree() -> void:
	# A scene replacement must never discard a paid ticket or award it twice.
	_settle_ticket()
	if _open:
		CursorState.release_visible(self)
