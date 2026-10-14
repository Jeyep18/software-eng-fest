class_name DevCameraEnvironment
extends RefCounted

const HDR_PATHS: Dictionary = {
	&"sunrise": "res://game/assets/sky_hdri/citrus_orchard_puresky_1k.hdr",
	&"sunset": "res://game/assets/sky_hdri/belfast_sunset_puresky_1k.hdr",
}
const SUN_BASE_META: StringName = &"visual_quality_base_energy"

var _active: bool = false
var _camera: Camera3D
var _original_camera_environment: Environment
var _source_environment: Environment
var _environment: Environment
var _sun: DirectionalLight3D
var _sun_snapshot: Dictionary = {}
var _rain_controllers: Array[StormRainController] = []
var _textures: Dictionary = {}
var _preset: StringName = &""
var _base_exposure: float = 1.0
var _base_fog_density: float = 0.0
var _base_volumetric_density: float = 0.0
var _base_fog_enabled: bool = false
var _base_volumetric_enabled: bool = false
var _base_sky_rotation: Vector3
var _base_sun_energy: float = 1.0
var _base_sun_rotation: Vector3
var _dry: bool = false


func begin(scene: Node, camera: Camera3D, settings: Dictionary, source_override: Environment = null) -> bool:
	if _active or not DevMode.can_use() or not DevMode.camera_active:
		return false
	if not is_instance_valid(scene) or not scene.is_inside_tree() or not is_instance_valid(camera):
		return false
	_source_environment = source_override if source_override != null else camera.environment
	if _source_environment == null:
		for node in scene.find_children("*", "WorldEnvironment", true, false):
			var world_environment := node as WorldEnvironment
			if world_environment.environment != null:
				_source_environment = world_environment.environment
				break
	if _source_environment == null:
		push_warning("Dev camera requires the location's authored environment.")
		return false
	_camera = camera
	_original_camera_environment = camera.environment
	_sun = find_sun(scene)
	if _sun != null:
		_sun_snapshot = {
			"transform": _sun.transform,
			"color": _sun.light_color,
			"energy": _sun.light_energy,
			"had_base": _sun.has_meta(SUN_BASE_META),
			"base_energy": _sun.get_meta(SUN_BASE_META, _sun.light_energy),
		}
	for node in scene.find_children("*", "GPUParticles3D", true, false):
		if node is StormRainController:
			_rain_controllers.append(node as StormRainController)
	_active = true
	VisualSettings.quality_preset_changed.connect(_on_quality_changed)
	apply(settings)
	if _environment == null:
		restore()
		return false
	return true


func apply(settings: Dictionary) -> void:
	if not _active or not DevMode.can_use() or not DevMode.camera_active or not is_instance_valid(_camera):
		return
	var requested: Variant = settings.get("environment_preset", &"storm")
	var preset := StringName(requested) if requested is String or requested is StringName else &"storm"
	if preset not in [&"storm", &"sunrise", &"sunny", &"sunset"]:
		preset = &"storm"
	if preset != _preset and not _build_environment(preset):
		return
	var fog_amount := _setting_float(settings, "fog_amount", 1.0, 0.0, 2.0)
	var sky_rotation := deg_to_rad(_setting_float(settings, "sky_rotation", 0.0, -180.0, 180.0))
	_environment.tonemap_exposure = _base_exposure * _setting_float(settings, "brightness", 1.0, 0.25, 2.0)
	_environment.fog_enabled = _base_fog_enabled and fog_amount > 0.0
	_environment.fog_density = _base_fog_density * fog_amount
	_environment.volumetric_fog_enabled = _base_volumetric_enabled and fog_amount > 0.0
	_environment.volumetric_fog_density = _base_volumetric_density * fog_amount
	_environment.sky_rotation = _base_sky_rotation + Vector3(0.0, sky_rotation, 0.0)
	if is_instance_valid(_sun):
		_sun.rotation = _base_sun_rotation + Vector3(0.0, sky_rotation, 0.0)
		# Quality refreshes must scale the temporary sunlight instead of restoring the authored energy.
		_sun.set_meta(SUN_BASE_META, _base_sun_energy * _setting_float(settings, "sun_strength", 1.0, 0.0, 2.0))
		VisualSettings.refresh_scene_quality()
	VisualSettings.apply_environment_quality(_environment)
	_camera.environment = _environment
	_set_dry(preset != &"storm")


func restore() -> void:
	if not _active:
		return
	_active = false
	if VisualSettings.quality_preset_changed.is_connected(_on_quality_changed):
		VisualSettings.quality_preset_changed.disconnect(_on_quality_changed)
	for rain in _rain_controllers:
		if is_instance_valid(rain):
			rain.set_recording_dry(false)
	StormAudioController.set_recording_dry(false)
	if is_instance_valid(_camera):
		_camera.environment = _original_camera_environment
	if is_instance_valid(_sun):
		_sun.transform = _sun_snapshot["transform"]
		_sun.light_color = _sun_snapshot["color"]
		_sun.light_energy = _sun_snapshot["energy"]
		if _sun_snapshot["had_base"]:
			_sun.set_meta(SUN_BASE_META, _sun_snapshot["base_energy"])
		else:
			_sun.remove_meta(SUN_BASE_META)
		VisualSettings.refresh_scene_quality()
	_rain_controllers.clear()
	_sun_snapshot.clear()
	_camera = null
	_sun = null
	_environment = null
	_source_environment = null
	_original_camera_environment = null
	_preset = &""
	_dry = false


static func find_sun(scene: Node) -> DirectionalLight3D:
	if not is_instance_valid(scene):
		return null
	var sun := scene.get_node_or_null("Environment/DirectionalLight3D") as DirectionalLight3D
	if sun != null:
		return sun
	var lights := scene.find_children("*", "DirectionalLight3D", true, false)
	return lights[0] as DirectionalLight3D if not lights.is_empty() else null


func _build_environment(preset: StringName) -> bool:
	var texture: Texture2D
	if HDR_PATHS.has(preset):
		texture = _get_texture(preset)
		if texture == null:
			return false
	_preset = preset
	_environment = _source_environment.duplicate() as Environment
	if _source_environment.sky != null:
		_environment.sky = _source_environment.sky.duplicate() as Sky
		if _source_environment.sky.sky_material != null:
			_environment.sky.sky_material = _source_environment.sky.sky_material.duplicate() as Material
	_base_exposure = _source_environment.tonemap_exposure
	_base_sky_rotation = _source_environment.sky_rotation
	if is_instance_valid(_sun):
		_sun.transform = _sun_snapshot["transform"]
		_sun.light_color = _sun_snapshot["color"]
		_base_sun_energy = float(_sun_snapshot["base_energy"])
		_base_sun_rotation = _sun.rotation
	if preset != &"storm":
		_environment.background_mode = Environment.BG_SKY
		_environment.sky = Sky.new()
		_environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		_environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
		_environment.adjustment_enabled = false
		_environment.adjustment_color_correction = null
		_environment.fog_enabled = true
		_environment.fog_sky_affect = 0.0
		_environment.volumetric_fog_enabled = true
		_environment.volumetric_fog_sky_affect = 0.0
		if preset == &"sunny":
			var clear_sky := ProceduralSkyMaterial.new()
			clear_sky.sky_top_color = Color(0.17, 0.42, 0.78)
			clear_sky.sky_horizon_color = Color(0.69, 0.83, 0.96)
			clear_sky.ground_horizon_color = Color(0.69, 0.77, 0.83)
			clear_sky.ground_bottom_color = Color(0.24, 0.25, 0.25)
			_environment.sky.sky_material = clear_sky
			_base_exposure *= 1.65
			_environment.ambient_light_energy = 0.9
			_environment.ambient_light_sky_contribution = 0.9
			_environment.fog_density = 0.0008
			_environment.volumetric_fog_density = 0.0006
			_environment.fog_light_color = Color(0.77, 0.85, 0.95)
			_environment.volumetric_fog_albedo = Color(0.77, 0.85, 0.95)
			_configure_sun(Color(1.0, 0.98, 0.92), 1.2, Vector3(-45.0, -20.0, 0.0))
		else:
			var panorama := PanoramaSkyMaterial.new()
			panorama.panorama = texture
			panorama.energy_multiplier = 0.6 if preset == &"sunrise" else 0.5
			_environment.sky.sky_material = panorama
			_base_exposure *= 1.3 if preset == &"sunrise" else 1.15
			_environment.ambient_light_energy = 0.8 if preset == &"sunrise" else 0.65
			_environment.ambient_light_sky_contribution = 0.75
			_environment.fog_density = 0.003
			_environment.volumetric_fog_density = 0.0015
			_environment.fog_light_color = Color(0.91, 0.82, 0.71) if preset == &"sunrise" else Color(0.89, 0.72, 0.65)
			_environment.volumetric_fog_albedo = _environment.fog_light_color
			if preset == &"sunrise":
				_configure_sun(Color(1.0, 0.86, 0.66), 0.85, Vector3(-7.6, -74.4, 0.0))
			else:
				_configure_sun(Color(1.0, 0.68, 0.42), 0.65, Vector3(-1.9, -37.6, 0.0))
	_base_fog_enabled = _environment.fog_enabled
	_base_volumetric_enabled = _environment.volumetric_fog_enabled
	_base_fog_density = _environment.fog_density
	_base_volumetric_density = _environment.volumetric_fog_density
	return true


func _configure_sun(color: Color, energy_multiplier: float, rotation_degrees: Vector3) -> void:
	if not is_instance_valid(_sun):
		return
	_sun.light_color = color
	_base_sun_energy *= energy_multiplier
	_base_sun_rotation = Vector3(deg_to_rad(rotation_degrees.x), deg_to_rad(rotation_degrees.y), deg_to_rad(rotation_degrees.z))


func _get_texture(preset: StringName) -> Texture2D:
	if not _textures.has(preset):
		_textures[preset] = load(HDR_PATHS[preset]) as Texture2D
		if _textures[preset] == null:
			push_warning("Dev camera could not load its %s sky panorama." % preset)
	return _textures[preset] as Texture2D


func _set_dry(enabled: bool) -> void:
	if _dry == enabled:
		return
	_dry = enabled
	for rain in _rain_controllers:
		if is_instance_valid(rain):
			rain.set_recording_dry(enabled)
	StormAudioController.set_recording_dry(enabled)


func _on_quality_changed(_quality: StringName) -> void:
	if _active:
		VisualSettings.apply_environment_quality(_environment)


static func _setting_float(settings: Dictionary, key: String, fallback: float, minimum: float, maximum: float) -> float:
	var value: Variant = settings.get(key, fallback)
	if not (value is float or value is int) or not is_finite(float(value)):
		return fallback
	return clampf(float(value), minimum, maximum)
