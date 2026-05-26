extends GPUParticles3D

@export var visibility_threshold: float = 0.12
@export var intensity_bias: float = 0.0
@export var min_amount: int = 18
@export var max_amount: int = 240
@export var min_lifetime: float = 0.35
@export var max_lifetime: float = 0.95
@export var min_speed_scale: float = 0.8
@export var max_speed_scale: float = 1.7

func _ready() -> void:
	if GlobalTimer != null:
		GlobalTimer.time_updated.connect(func(_minute: int) -> void: _apply_intensity())
		GlobalTimer.encroachment_threshold_reached.connect(func(_zone: String) -> void: _apply_intensity())
		GlobalTimer.storm_arrived.connect(_apply_intensity)
	if StormEnroachment != null:
		StormEnroachment.location_state_changed.connect(func(_loc: String, _state: String) -> void: _apply_intensity())
	_apply_intensity()

func _apply_intensity() -> void:
	var progress: float = GlobalTimer.get_storm_progress() if GlobalTimer != null else 0.0
	var location: String = SceneManager.current_location if SceneManager != null else ""
	var state_boost: float = 0.0
	if StormEnroachment != null:
		var state: String = StormEnroachment.get_state(location)
		state_boost = 0.20 if state == "danger" else (0.35 if state == "inaccessible" else 0.0)
	var intensity: float = clampf(progress + intensity_bias + state_boost, 0.0, 1.0)
	var shaped: float = smoothstep(visibility_threshold, 1.0, intensity)
	visible = intensity >= visibility_threshold
	emitting = visible
	amount = int(lerpf(float(min_amount), float(max_amount), shaped))
	lifetime = lerpf(min_lifetime, max_lifetime, shaped)
	speed_scale = lerpf(min_speed_scale, max_speed_scale, shaped)
