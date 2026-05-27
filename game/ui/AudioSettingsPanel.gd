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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	UI_STYLE.apply_panel(self)
	_build()
	_sync_from_audio_manager()

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
	title.text = "Audio Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI_STYLE.apply_label(title, true, true)
	box.add_child(title)

	box.add_child(_make_language_row())

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

func _sync_from_audio_manager() -> void:
	for bus_name in _sliders.keys():
		var slider := _sliders[bus_name] as HSlider
		slider.set_value_no_signal(roundf(AudioManager.get_bus_volume_percent(bus_name) * 100.0))
		_update_percent_label(slider)

func _on_slider_changed(value: float, bus_name: StringName) -> void:
	AudioManager.set_bus_volume_percent(bus_name, value / 100.0)
	_update_percent_label(_sliders[bus_name])

func _on_reset_pressed() -> void:
	AudioManager.reset_audio_settings()
	_sync_from_audio_manager()

func _on_language_selected(index: int) -> void:
	LocalizationManager.set_language(LocalizationManager.get_language_from_index(index))

func _update_percent_label(slider: HSlider) -> void:
	var percent := slider.get_parent().get_node_or_null("Percent") as Label
	if percent != null:
		percent.text = "%d%%" % int(roundf(slider.value))
