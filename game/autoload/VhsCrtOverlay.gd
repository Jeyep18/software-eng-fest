extends CanvasLayer

const VHS_CRT_SHADER: Shader = preload("res://game/shaders/vhs_crt_overlay.gdshader")

var _overlay: ColorRect
var _material: ShaderMaterial
var _recording_override: bool = false
var _recording_show_effect: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	_build_overlay()
	_apply_visibility()
	_apply_quality_profile()
	VisualSettings.vhs_crt_enabled_changed.connect(_on_vhs_crt_enabled_changed)
	VisualSettings.quality_preset_changed.connect(_on_quality_preset_changed)

func _build_overlay() -> void:
	_material = ShaderMaterial.new()
	_material.shader = VHS_CRT_SHADER
	_material.set_shader_parameter("overlay", true)

	_overlay = ColorRect.new()
	_overlay.name = "VhsCrtOverlay"
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.color = Color.WHITE
	_overlay.material = _material
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

func _apply_visibility() -> void:
	_overlay.visible = _recording_show_effect if _recording_override else VisualSettings.is_vhs_crt_enabled()

func set_recording_override(enabled: bool, show_effect: bool, capture_time: float) -> void:
	if enabled and (not DevMode.can_use() or not DevMode.camera_active or not is_finite(capture_time)):
		return
	_recording_override = enabled
	_recording_show_effect = show_effect
	if _material != null:
		_material.set_shader_parameter("use_capture_time", enabled)
		if enabled:
			_material.set_shader_parameter("capture_time", maxf(capture_time, 0.0))
	_apply_visibility()

func _apply_quality_profile() -> void:
	if _material == null:
		return
	var profile := VisualSettings.get_vhs_shader_profile()
	for key in profile.keys():
		_material.set_shader_parameter(String(key), profile[key])

func _on_vhs_crt_enabled_changed(_enabled: bool) -> void:
	_apply_visibility()

func _on_quality_preset_changed(_preset: StringName) -> void:
	_apply_quality_profile()
