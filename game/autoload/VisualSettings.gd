extends Node

signal vhs_crt_enabled_changed(enabled: bool)
signal ui_scale_changed(scale: float)

const SETTINGS_PATH: String = "user://visual_settings.cfg"
const DEFAULT_UI_SCALE_PERCENT: int = 140
const MIN_UI_SCALE_PERCENT: int = 100
const MAX_UI_SCALE_PERCENT: int = 175

var vhs_crt_enabled: bool = true:
	set(value):
		if vhs_crt_enabled == value:
			return
		vhs_crt_enabled = value
		_save_settings()
		vhs_crt_enabled_changed.emit(vhs_crt_enabled)

var ui_scale_percent: int = DEFAULT_UI_SCALE_PERCENT:
	set(value):
		var clamped := clampi(value, MIN_UI_SCALE_PERCENT, MAX_UI_SCALE_PERCENT)
		if ui_scale_percent == clamped:
			return
		ui_scale_percent = clamped
		_save_settings()
		ui_scale_changed.emit(get_ui_scale())

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_settings()

func set_vhs_crt_enabled(enabled: bool) -> void:
	vhs_crt_enabled = enabled

func is_vhs_crt_enabled() -> bool:
	return vhs_crt_enabled

func reset_visual_settings() -> void:
	vhs_crt_enabled = true
	ui_scale_percent = DEFAULT_UI_SCALE_PERCENT

func set_ui_scale_percent(percent: int) -> void:
	ui_scale_percent = percent

func get_ui_scale_percent() -> int:
	return ui_scale_percent

func get_ui_scale() -> float:
	return float(ui_scale_percent) / 100.0

func scaled(value: float) -> float:
	return value * get_ui_scale()

func scaled_vector(value: Vector2) -> Vector2:
	return value * get_ui_scale()

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return

	vhs_crt_enabled = bool(config.get_value("effects", "vhs_crt_enabled", vhs_crt_enabled))
	ui_scale_percent = int(config.get_value("ui", "scale_percent", ui_scale_percent))

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("effects", "vhs_crt_enabled", vhs_crt_enabled)
	config.set_value("ui", "scale_percent", ui_scale_percent)
	config.save(SETTINGS_PATH)
