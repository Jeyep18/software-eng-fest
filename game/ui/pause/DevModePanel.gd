class_name DevModePanel
extends Control

signal teleport_requested(location_id: String)
signal camera_requested

const UI_STYLE = preload("res://game/ui/theme/GameUIStyle.gd")

var _status: Label
var _feedback: Label
var _amount: SpinBox
var _cash_grid: GridContainer
var _clock_toggle: CheckBox
var _destination: OptionButton
var _panel: PanelContainer
var _scroll: ScrollContainer
var _camera_controls: Dictionary = {}
var _environment_choice: OptionButton
var _location_choice: OptionButton
var _house_state_choice: OptionButton


func _ready() -> void:
	_build()
	GameState.cash_changed.connect(_refresh.unbind(1))
	GlobalTimer.time_updated.connect(_refresh.unbind(1))
	DevMode.clock_pause_changed.connect(_refresh.unbind(1))
	DevMode.camera_settings_changed.connect(_refresh)
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
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(550, 470)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(_scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	_scroll.add_child(box)

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
	_build_camera_controls(box)
	UI_STYLE.apply_tree(_panel)


func _apply_ui_scale() -> void:
	var scale := VisualSettings.get_ui_scale()
	_panel.custom_minimum_size.x = 600.0 + 100.0 * (scale - 1.0)
	var height := minf(760.0 + 160.0 * (scale - 1.0), get_viewport_rect().size.y - 80.0)
	_panel.custom_minimum_size.y = height
	_scroll.custom_minimum_size.y = height - 50.0
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
	var settings := DevMode.camera_settings()
	for key in _camera_controls:
		var control: Control = _camera_controls[key]
		if control is CheckBox:
			control.set_pressed_no_signal(bool(settings[key]))
		elif control is SpinBox:
			control.set_value_no_signal(float(settings[key]))
	for index in range(_environment_choice.item_count):
		if _environment_choice.get_item_metadata(index) == settings[&"environment_preset"]:
			_environment_choice.select(index)
	for entry in [[_location_choice, &"recording_location"], [_house_state_choice, &"house_state"]]:
		var choice: OptionButton = entry[0]
		for index in choice.item_count:
			if choice.get_item_metadata(index) == settings[entry[1]]:
				choice.select(index)
	_house_state_choice.disabled = settings[&"recording_location"] != &"house_teaser"
	var sun_control := _camera_controls[&"sun_strength"] as SpinBox
	sun_control.editable = DevMode.camera_has_active_sun()
	sun_control.tooltip_text = "" if sun_control.editable else LocalizationManager.translate("Sunlight is inactive in this interior.")


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
	for index in range(_environment_choice.item_count):
		var preset: StringName = _environment_choice.get_item_metadata(index)
		_environment_choice.set_item_text(index, LocalizationManager.translate(DevMode.CAMERA_ENVIRONMENTS[preset]))
	for entry in [[_location_choice, DevMode.CAMERA_LOCATIONS], [_house_state_choice, DevMode.CAMERA_HOUSE_STATES]]:
		var choice: OptionButton = entry[0]
		for index in choice.item_count:
			choice.set_item_text(index, LocalizationManager.translate(entry[1][choice.get_item_metadata(index)]))
	_refresh()


func _build_camera_controls(box: VBoxContainer) -> void:
	box.add_child(HSeparator.new())
	var title := Label.new()
	title.text = "RECORDING CAMERA"
	box.add_child(title)
	_location_choice = _camera_choice(box, &"recording_location", "Recording location", DevMode.CAMERA_LOCATIONS)
	_house_state_choice = _camera_choice(box, &"house_state", "House state", DevMode.CAMERA_HOUSE_STATES)
	var start := Button.new()
	start.text = "Enter camera mode"
	start.pressed.connect(func() -> void: camera_requested.emit())
	box.add_child(start)
	box.add_child(_feedback)
	var instructions := Label.new()
	instructions.text = "WASD: fly · Mouse: look · E/Q: up/down · Shift: faster\nWheel: zoom · Alt+C: cinematic · P: play/pause time\nG: normal/wrecked house · Esc: return here. The preparation clock stays held."
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(instructions)
	_camera_number(box, &"speed", "Movement speed", 0.5)
	_camera_number(box, &"sensitivity", "Mouse sensitivity", 0.01)
	_camera_toggle(box, &"cinematic", "Cinematic movement")
	_camera_toggle(box, &"world_paused", "Pause time (freeze the world)")
	var reset_camera := Button.new()
	reset_camera.text = "Reset Camera"
	reset_camera.pressed.connect(func() -> void: _camera_action(DevMode.reset_camera_pose()))
	box.add_child(reset_camera)
	for entry in [
		[&"hide_player", "Hide player"], [&"hide_npcs", "Hide NPCs"],
		[&"hide_animals", "Hide animals"], [&"hide_items", "Hide pickable items"],
		[&"hide_indicators", "Hide world indicators"],
	]:
		_camera_toggle(box, entry[0], entry[1])
	box.add_child(HSeparator.new())
	var environment_label := Label.new()
	environment_label.text = "Recording environment"
	box.add_child(environment_label)
	_environment_choice = OptionButton.new()
	_environment_choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for preset in DevMode.CAMERA_ENVIRONMENTS:
		_environment_choice.add_item(LocalizationManager.translate(DevMode.CAMERA_ENVIRONMENTS[preset]))
		_environment_choice.set_item_metadata(_environment_choice.item_count - 1, preset)
	_environment_choice.item_selected.connect(func(index: int) -> void:
		_camera_action(DevMode.set_camera_setting(&"environment_preset", _environment_choice.get_item_metadata(index)))
	)
	box.add_child(_environment_choice)
	_camera_number(box, &"brightness", "Brightness", 0.05)
	_camera_number(box, &"sun_strength", "Sun strength", 0.05)
	_camera_number(box, &"fog_amount", "Fog amount", 0.05)
	_camera_number(box, &"sky_rotation", "Sky rotation (degrees)", 5.0)
	var reset_preset := Button.new()
	reset_preset.text = "Reset Preset"
	reset_preset.pressed.connect(func() -> void: _camera_action(DevMode.reset_environment_preset()))
	box.add_child(reset_preset)
	_camera_toggle(box, &"vhs_enabled", "VHS / CRT during recording")
	_camera_toggle(box, &"dof_enabled", "Depth of field during recording")
	var note := Label.new()
	note.text = "Environment and visibility apply only in camera mode. Dry presets mute weather; street and shop ambience remain."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(note)


func _camera_toggle(box: VBoxContainer, key: StringName, text: String) -> void:
	var control := CheckBox.new()
	control.text = text
	control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	control.toggled.connect(_on_camera_setting_changed.bind(key))
	_camera_controls[key] = control
	box.add_child(control)


func _camera_choice(box: VBoxContainer, key: StringName, text: String, choices: Dictionary) -> OptionButton:
	var label := Label.new()
	label.text = text
	box.add_child(label)
	var choice := OptionButton.new()
	for value in choices:
		choice.add_item(LocalizationManager.translate(choices[value]))
		choice.set_item_metadata(choice.item_count - 1, value)
	choice.item_selected.connect(func(index: int) -> void:
		_camera_action(DevMode.set_camera_setting(key, choice.get_item_metadata(index)))
	)
	box.add_child(choice)
	return choice


func _camera_number(box: VBoxContainer, key: StringName, text: String, step: float) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var control := SpinBox.new()
	var bounds: Vector2 = DevMode.CAMERA_SETTING_RANGES[key]
	control.min_value = bounds.x
	control.max_value = bounds.y
	control.step = step
	control.custom_minimum_size.x = 160
	control.value_changed.connect(_on_camera_setting_changed.bind(key))
	_camera_controls[key] = control
	row.add_child(control)
	box.add_child(row)


func _on_camera_setting_changed(value: Variant, key: StringName) -> void:
	_camera_action(DevMode.set_camera_setting(key, value))


func _camera_action(succeeded: bool) -> void:
	_feedback.text = "" if succeeded else LocalizationManager.translate("Dev action unavailable.")
	_refresh()


func show_camera_unavailable() -> void:
	_feedback.text = LocalizationManager.translate("Camera unavailable. Finish the current action or wait for the transition, then try again.")
