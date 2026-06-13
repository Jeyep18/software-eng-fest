extends Node

signal vhs_crt_enabled_changed(enabled: bool)
signal ui_scale_changed(scale: float)
signal quality_preset_changed(preset: StringName)

const SETTINGS_PATH: String = "user://visual_settings.cfg"
const DEFAULT_UI_SCALE_PERCENT: int = 140
const MIN_UI_SCALE_PERCENT: int = 100
const MAX_UI_SCALE_PERCENT: int = 175
const QUALITY_HIGH: StringName = &"high"
const QUALITY_BALANCED: StringName = &"balanced"
const QUALITY_PERFORMANCE: StringName = &"performance"
const DEFAULT_QUALITY_PRESET: StringName = QUALITY_HIGH

const QUALITY_LABELS: Dictionary = {
	QUALITY_HIGH: "High",
	QUALITY_BALANCED: "Balanced",
	QUALITY_PERFORMANCE: "Performance",
}

const _LIGHT_ENERGY_MULTIPLIERS: Dictionary = {
	QUALITY_HIGH: 1.0,
	QUALITY_BALANCED: 0.82,
	QUALITY_PERFORMANCE: 0.62,
}

const _LIGHT_RANGE_MULTIPLIERS: Dictionary = {
	QUALITY_HIGH: 1.0,
	QUALITY_BALANCED: 0.88,
	QUALITY_PERFORMANCE: 0.72,
}

var quality_preset: StringName = DEFAULT_QUALITY_PRESET:
	set(value):
		var normalized := _normalize_quality_preset(value)
		if quality_preset == normalized:
			return
		quality_preset = normalized
		_save_settings()
		quality_preset_changed.emit(quality_preset)
		_apply_quality_to_current_scene()

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
	if get_tree() != null:
		get_tree().node_added.connect(_on_node_added)
	call_deferred("_apply_quality_to_current_scene")

func set_vhs_crt_enabled(enabled: bool) -> void:
	vhs_crt_enabled = enabled

func is_vhs_crt_enabled() -> bool:
	return vhs_crt_enabled

func reset_visual_settings() -> void:
	quality_preset = DEFAULT_QUALITY_PRESET
	vhs_crt_enabled = true
	ui_scale_percent = DEFAULT_UI_SCALE_PERCENT

func set_quality_preset(preset: StringName) -> void:
	quality_preset = preset

func get_quality_preset() -> StringName:
	return quality_preset

func get_quality_label(preset: StringName = DEFAULT_QUALITY_PRESET) -> String:
	return str(QUALITY_LABELS.get(_normalize_quality_preset(preset), "High"))

func is_high_quality() -> bool:
	return quality_preset == QUALITY_HIGH

func is_balanced_quality() -> bool:
	return quality_preset == QUALITY_BALANCED

func is_performance_quality() -> bool:
	return quality_preset == QUALITY_PERFORMANCE

func get_vhs_shader_profile() -> Dictionary:
	match quality_preset:
		QUALITY_BALANCED:
			return {
				"roll": true,
				"pixelate": true,
				"noise_opacity": 0.018,
				"static_noise_intensity": 0.0025,
				"grille_opacity": 0.018,
				"scanlines_opacity": 0.04,
				"warp_amount": 0.045,
			}
		QUALITY_PERFORMANCE:
			return {
				"roll": false,
				"pixelate": true,
				"noise_opacity": 0.0,
				"static_noise_intensity": 0.0,
				"grille_opacity": 0.0,
				"scanlines_opacity": 0.025,
				"warp_amount": 0.0,
			}
		_:
			return {
				"roll": true,
				"pixelate": true,
				"noise_opacity": 0.035,
				"static_noise_intensity": 0.006,
				"grille_opacity": 0.035,
				"scanlines_opacity": 0.06,
				"warp_amount": 0.08,
			}

func should_use_camera_depth_of_field() -> bool:
	return quality_preset != QUALITY_PERFORMANCE

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

	quality_preset = _normalize_quality_preset(StringName(str(config.get_value("quality", "preset", quality_preset))))
	vhs_crt_enabled = bool(config.get_value("effects", "vhs_crt_enabled", vhs_crt_enabled))
	ui_scale_percent = int(config.get_value("ui", "scale_percent", ui_scale_percent))

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("quality", "preset", String(quality_preset))
	config.set_value("effects", "vhs_crt_enabled", vhs_crt_enabled)
	config.set_value("ui", "scale_percent", ui_scale_percent)
	config.save(SETTINGS_PATH)

func _normalize_quality_preset(value: StringName) -> StringName:
	if QUALITY_LABELS.has(value):
		return value
	return DEFAULT_QUALITY_PRESET

func _on_node_added(node: Node) -> void:
	if node is Light3D or node is WorldEnvironment:
		call_deferred("_apply_quality_to_node", node)

func _apply_quality_to_current_scene() -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	_apply_quality_to_node(tree.current_scene)

func _apply_quality_to_node(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node is Light3D:
		_apply_light_quality(node as Light3D)
	elif node is WorldEnvironment:
		_apply_environment_quality(node as WorldEnvironment)
	for child in node.get_children():
		_apply_quality_to_node(child)

func _apply_light_quality(light: Light3D) -> void:
	if not light.has_meta("visual_quality_base_energy"):
		light.set_meta("visual_quality_base_energy", light.light_energy)
	if not light.has_meta("visual_quality_base_range"):
		light.set_meta("visual_quality_base_range", light.get_param(Light3D.PARAM_RANGE))
	if not light.has_meta("visual_quality_base_shadow"):
		light.set_meta("visual_quality_base_shadow", light.shadow_enabled)

	var energy_multiplier := float(_LIGHT_ENERGY_MULTIPLIERS.get(quality_preset, 1.0))
	var range_multiplier := float(_LIGHT_RANGE_MULTIPLIERS.get(quality_preset, 1.0))
	light.light_energy = float(light.get_meta("visual_quality_base_energy")) * energy_multiplier
	light.set_param(Light3D.PARAM_RANGE, float(light.get_meta("visual_quality_base_range")) * range_multiplier)

	if quality_preset == QUALITY_PERFORMANCE and light.light_energy < 0.45:
		light.shadow_enabled = false
	else:
		light.shadow_enabled = bool(light.get_meta("visual_quality_base_shadow"))

func _apply_environment_quality(world_environment: WorldEnvironment) -> void:
	var environment := world_environment.environment
	if environment == null:
		return
	if not environment.has_meta("visual_quality_base_ssil"):
		environment.set_meta("visual_quality_base_ssil", environment.ssil_enabled)
		environment.set_meta("visual_quality_base_glow_intensity", environment.glow_intensity)
		environment.set_meta("visual_quality_base_glow_bloom", environment.glow_bloom)

	match quality_preset:
		QUALITY_BALANCED:
			environment.ssil_enabled = false
			environment.glow_intensity = float(environment.get_meta("visual_quality_base_glow_intensity")) * 0.7
			environment.glow_bloom = float(environment.get_meta("visual_quality_base_glow_bloom")) * 0.7
		QUALITY_PERFORMANCE:
			environment.ssil_enabled = false
			environment.glow_intensity = float(environment.get_meta("visual_quality_base_glow_intensity")) * 0.35
			environment.glow_bloom = float(environment.get_meta("visual_quality_base_glow_bloom")) * 0.35
		_:
			environment.ssil_enabled = bool(environment.get_meta("visual_quality_base_ssil"))
			environment.glow_intensity = float(environment.get_meta("visual_quality_base_glow_intensity"))
			environment.glow_bloom = float(environment.get_meta("visual_quality_base_glow_bloom"))
