extends CanvasLayer

const VHS_CRT_SHADER: Shader = preload("res://game/shaders/vhs_crt_overlay.gdshader")

var _overlay: ColorRect
var _material: ShaderMaterial

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	_build_overlay()
	_apply_visibility()
	VisualSettings.vhs_crt_enabled_changed.connect(_on_vhs_crt_enabled_changed)

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
	_overlay.visible = VisualSettings.is_vhs_crt_enabled()

func _on_vhs_crt_enabled_changed(_enabled: bool) -> void:
	_apply_visibility()
