class_name DevModePanel
extends Control

signal teleport_requested(location_id: String)

const UI_STYLE = preload("res://game/ui/GameUIStyle.gd")

var _status: Label
var _feedback: Label
var _amount: SpinBox
var _cash_grid: GridContainer
var _clock_toggle: CheckBox
var _destination: OptionButton
var _panel: PanelContainer


func _ready() -> void:
	_build()
	GameState.cash_changed.connect(_refresh.unbind(1))
	GlobalTimer.time_updated.connect(_refresh.unbind(1))
	DevMode.clock_pause_changed.connect(_refresh.unbind(1))
	LocalizationManager.language_changed.connect(_on_language_changed.unbind(1))
	VisualSettings.ui_scale_changed.connect(_apply_ui_scale.unbind(1))
	_apply_ui_scale()
	_refresh()


func _build() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(600, 520)
	center.add_child(_panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	_panel.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(550, 470)
	margin.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	scroll.add_child(box)

	var title := Label.new()
	title.text = "DEV MODE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status)

	var amount_row := HBoxContainer.new()
	box.add_child(amount_row)
	var amount_label := Label.new()
	amount_label.text = "Amount"
	amount_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	amount_row.add_child(amount_label)
	_amount = SpinBox.new()
	_amount.min_value = 1
	_amount.max_value = DevMode.MAX_CASH_CHANGE
	_amount.step = 1
	_amount.value = 100
	_amount.rounded = true
	_amount.custom_minimum_size.x = 150
	amount_row.add_child(_amount)

	_cash_grid = GridContainer.new()
	_cash_grid.columns = 2
	_cash_grid.add_theme_constant_override("h_separation", 10)
	_cash_grid.add_theme_constant_override("v_separation", 8)
	box.add_child(_cash_grid)
	var add_button := Button.new()
	add_button.text = "Add money"
	add_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_button.pressed.connect(_change_money.bind(true))
	_cash_grid.add_child(add_button)
	var remove_button := Button.new()
	remove_button.text = "Remove money"
	remove_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	remove_button.pressed.connect(_change_money.bind(false))
	_cash_grid.add_child(remove_button)

	box.add_child(HSeparator.new())
	_clock_toggle = CheckBox.new()
	_clock_toggle.text = "Pause clock after resume"
	_clock_toggle.toggled.connect(_on_clock_toggled)
	box.add_child(_clock_toggle)
	var reset_button := Button.new()
	reset_button.text = "Reset to 6:00 AM"
	reset_button.pressed.connect(_on_reset_clock)
	box.add_child(reset_button)

	box.add_child(HSeparator.new())
	_destination = OptionButton.new()
	_destination.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for location_id in DevMode.TELEPORT_LOCATIONS:
		_destination.add_item(LocalizationManager.translate(DevMode.TELEPORT_LOCATIONS[location_id]))
		_destination.set_item_metadata(_destination.item_count - 1, location_id)
	box.add_child(_destination)
	var teleport_button := Button.new()
	teleport_button.text = "Teleport"
	teleport_button.pressed.connect(_on_teleport)
	box.add_child(teleport_button)

	_feedback = Label.new()
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_feedback)
	UI_STYLE.apply_tree(_panel)


func _apply_ui_scale() -> void:
	var scale := VisualSettings.get_ui_scale()
	_panel.custom_minimum_size.x = 600.0 + 100.0 * (scale - 1.0)
	_panel.custom_minimum_size.y = 520.0 + 220.0 * (scale - 1.0)
	_cash_grid.columns = 1 if scale >= 1.5 else 2
	_scale_text(_panel, roundi(20.0 * scale))

func get_card_rect() -> Rect2:
	return _panel.get_global_rect()


func _scale_text(node: Node, font_size: int) -> void:
	if node is Label or node is Button or node is LineEdit:
		(node as Control).add_theme_font_size_override("font_size", font_size)
	for child in node.get_children():
		_scale_text(child, font_size)


func _refresh() -> void:
	_status.text = LocalizationManager.trf("Cash: ₱%d   Time: %s", [GameState.get_cash(), GlobalTimer.get_time_string()])
	_clock_toggle.set_pressed_no_signal(DevMode.clock_paused)


func _change_money(add: bool) -> void:
	var amount := int(_amount.value)
	var succeeded := DevMode.add_money(amount) if add else DevMode.remove_money(amount)
	_feedback.text = "" if succeeded else LocalizationManager.translate("Dev action unavailable.")
	_refresh()


func _on_clock_toggled(value: bool) -> void:
	var succeeded := DevMode.set_clock_paused(value)
	_feedback.text = "" if succeeded else LocalizationManager.translate("Dev action unavailable.")
	_refresh()


func _on_reset_clock() -> void:
	var succeeded := DevMode.reset_clock()
	_feedback.text = "" if succeeded else LocalizationManager.translate("Dev action unavailable.")
	_refresh()


func _on_teleport() -> void:
	var location_id := str(_destination.get_item_metadata(_destination.selected))
	if not DevMode.can_use() or not DevMode.is_valid_destination(location_id):
		_feedback.text = LocalizationManager.translate("Dev action unavailable.")
		return
	teleport_requested.emit(location_id)


func _on_language_changed() -> void:
	for index in range(_destination.item_count):
		var location_id := str(_destination.get_item_metadata(index))
		_destination.set_item_text(index, LocalizationManager.translate(DevMode.TELEPORT_LOCATIONS[location_id]))
	_refresh()
