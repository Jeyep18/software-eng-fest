class_name AudioSettingsPanel
extends PanelContainer

signal close_requested

const SFX = preload("res://game/audio/Sfx.gd")
const UI_STYLE = preload("res://game/ui/GameUIStyle.gd")

const BUSES: Array[Dictionary] = [
	{ "name": &"Master", "label": "Master" },
	{ "name": &"Music", "label": "Music" },
	{ "name": &"Ambience", "label": "Ambience" },
	{ "name": &"SFX", "label": "SFX" },
	{ "name": &"Voice", "label": "Voice" },
]

var show_close_button: bool = true
var _sliders: Dictionary = {}
var _language_selector: OptionButton
var _quality_selector: OptionButton
var _vhs_crt_toggle: CheckBox
var _ui_scale_selector: OptionButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	UI_STYLE.apply_panel(self)
	_build()
	_sync_from_audio_manager()
	VisualSettings.ui_scale_changed.connect(_on_ui_scale_changed)
	VisualSettings.quality_preset_changed.connect(_on_quality_preset_changed)
	_apply_ui_scale()

func _build() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI_STYLE.apply_label(title, true, true)
	box.add_child(title)

	box.add_child(_make_language_row())
	box.add_child(_make_quality_row())
	box.add_child(_make_vhs_crt_row())
	box.add_child(_make_ui_scale_row())

	for bus_data in BUSES:
		box.add_child(_make_volume_row(bus_data["name"], bus_data["label"]))

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 10)
	box.add_child(buttons)

	var reset_button := Button.new()
	reset_button.text = "Reset"
	reset_button.custom_minimum_size = Vector2(120, 42)
	reset_button.pressed.connect(_on_reset_pressed)
	UI_STYLE.apply_button(reset_button)
	SFX.wire_button(reset_button)
	buttons.add_child(reset_button)

	if show_close_button:
		var close_button := Button.new()
		close_button.text = "Close"
		close_button.custom_minimum_size = Vector2(120, 42)
		close_button.pressed.connect(func() -> void: close_requested.emit())
		UI_STYLE.apply_button(close_button)
		SFX.wire_button(close_button, true)
		buttons.add_child(close_button)

func _make_volume_row(bus_name: StringName, label_text: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(100, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UI_STYLE.apply_label(label)
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_slider_changed.bind(bus_name))
	row.add_child(slider)
	_sliders[bus_name] = slider

	var percent := Label.new()
	percent.name = "Percent"
	percent.custom_minimum_size = Vector2(44, 0)
	percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	percent.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UI_STYLE.apply_label(percent)
	row.add_child(percent)

	return row

func _make_language_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var label := Label.new()
	label.text = "Language"
	label.custom_minimum_size = Vector2(100, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UI_STYLE.apply_label(label)
	row.add_child(label)

	_language_selector = OptionButton.new()
	_language_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_language_selector.add_item(str(LocalizationManager.LANGUAGE_LABELS[LocalizationManager.LANGUAGE_ENGLISH]), 0)
	_language_selector.add_item(str(LocalizationManager.LANGUAGE_LABELS[LocalizationManager.LANGUAGE_TAGALOG]), 1)
	_language_selector.select(LocalizationManager.get_language_index())
	_language_selector.item_selected.connect(_on_language_selected)
	UI_STYLE.apply_button(_language_selector)
	row.add_child(_language_selector)

	return row

func _make_quality_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var label := Label.new()
	label.text = "Visual Quality"
	label.custom_minimum_size = Vector2(100, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UI_STYLE.apply_label(label)
	row.add_child(label)

	_quality_selector = OptionButton.new()
	_quality_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var presets: Array[StringName] = [
		VisualSettings.QUALITY_HIGH,
		VisualSettings.QUALITY_BALANCED,
		VisualSettings.QUALITY_PERFORMANCE,
	]
	for preset in presets:
		_quality_selector.add_item(VisualSettings.get_quality_label(preset))
		_quality_selector.set_item_metadata(_quality_selector.item_count - 1, preset)
		if preset == VisualSettings.get_quality_preset():
			_quality_selector.select(_quality_selector.item_count - 1)
	_quality_selector.item_selected.connect(_on_quality_selected)
	UI_STYLE.apply_button(_quality_selector)
	SFX.wire_button(_quality_selector)
	row.add_child(_quality_selector)

	return row

func _make_vhs_crt_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var label := Label.new()
	label.text = "VHS / CRT"
	label.custom_minimum_size = Vector2(100, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UI_STYLE.apply_label(label)
	row.add_child(label)

	_vhs_crt_toggle = CheckBox.new()
	_vhs_crt_toggle.text = "Enabled"
	_vhs_crt_toggle.button_pressed = VisualSettings.is_vhs_crt_enabled()
	_vhs_crt_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vhs_crt_toggle.toggled.connect(_on_vhs_crt_toggled)
	UI_STYLE.apply_button(_vhs_crt_toggle)
	SFX.wire_button(_vhs_crt_toggle)
	row.add_child(_vhs_crt_toggle)

	return row

func _make_ui_scale_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var label := Label.new()
	label.text = "UI Scale"
	label.custom_minimum_size = Vector2(100, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UI_STYLE.apply_label(label)
	row.add_child(label)

	_ui_scale_selector = OptionButton.new()
	_ui_scale_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for percent in [100, 125, 140, 150, 175]:
		_ui_scale_selector.add_item("%d%%" % percent, percent)
		if percent == VisualSettings.get_ui_scale_percent():
			_ui_scale_selector.select(_ui_scale_selector.item_count - 1)
	_ui_scale_selector.item_selected.connect(_on_ui_scale_selected)
	UI_STYLE.apply_button(_ui_scale_selector)
	row.add_child(_ui_scale_selector)

	return row

func _sync_from_audio_manager() -> void:
	for bus_name in _sliders.keys():
		var slider := _sliders[bus_name] as HSlider
		slider.set_value_no_signal(roundf(AudioManager.get_bus_volume_percent(bus_name) * 100.0))
		_update_percent_label(slider)
	if _vhs_crt_toggle != null:
		_vhs_crt_toggle.set_pressed_no_signal(VisualSettings.is_vhs_crt_enabled())
	if _quality_selector != null:
		_select_quality_without_signal(VisualSettings.get_quality_preset())
	if _ui_scale_selector != null:
		for i in range(_ui_scale_selector.item_count):
			if _ui_scale_selector.get_item_id(i) == VisualSettings.get_ui_scale_percent():
				_ui_scale_selector.select(i)
				break

func _on_slider_changed(value: float, bus_name: StringName) -> void:
	AudioManager.set_bus_volume_percent(bus_name, value / 100.0)
	_update_percent_label(_sliders[bus_name])

func _on_reset_pressed() -> void:
	AudioManager.reset_audio_settings()
	VisualSettings.reset_visual_settings()
	_sync_from_audio_manager()

func _on_language_selected(index: int) -> void:
	LocalizationManager.set_language(LocalizationManager.get_language_from_index(index))

func _on_quality_selected(index: int) -> void:
	VisualSettings.set_quality_preset(_quality_selector.get_item_metadata(index))

func _on_quality_preset_changed(preset: StringName) -> void:
	_select_quality_without_signal(preset)

func _select_quality_without_signal(preset: StringName) -> void:
	if _quality_selector == null:
		return
	for i in range(_quality_selector.item_count):
		if _quality_selector.get_item_metadata(i) == preset:
			_quality_selector.select(i)
			return

func _on_vhs_crt_toggled(enabled: bool) -> void:
	VisualSettings.set_vhs_crt_enabled(enabled)

func _on_ui_scale_selected(index: int) -> void:
	VisualSettings.set_ui_scale_percent(_ui_scale_selector.get_item_id(index))

func _update_percent_label(slider: HSlider) -> void:
	var percent := slider.get_parent().get_node_or_null("Percent") as Label
	if percent != null:
		percent.text = "%d%%" % int(roundf(slider.value))

func _on_ui_scale_changed(_scale: float) -> void:
	_apply_ui_scale()

func _apply_ui_scale() -> void:
	var scale := VisualSettings.get_ui_scale()
	_apply_font_scale_recursive(self, scale)

func _apply_font_scale_recursive(node: Node, scale: float) -> void:
	if node is Label:
		var label := node as Label
		var base_size := 18.0
		if label.text == "Settings":
			base_size = 24.0
		label.add_theme_font_size_override("font_size", int(roundi(base_size * scale)))
	elif node is Button:
		(node as Button).add_theme_font_size_override("font_size", int(roundi(18.0 * scale)))
	for child in node.get_children():
		_apply_font_scale_recursive(child, scale)
