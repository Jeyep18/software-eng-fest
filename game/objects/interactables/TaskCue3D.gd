class_name TaskCue3D
extends Node3D

@export var pulse_duration: float = 0.7
@export var min_light_energy: float = 0.05
@export var max_light_energy: float = 0.16
@export var min_particle_amount: int = 5
@export var max_particle_amount: int = 10

@onready var _light: OmniLight3D = $OmniLight3D
@onready var _particles: GPUParticles3D = $HintParticles

var _pulse_tween: Tween = null
var _is_active: bool = false

func _ready() -> void:
	set_active(false)

func set_active(active: bool) -> void:
	if _is_active == active and visible == active:
		return
	_is_active = active
	visible = active

	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
		_pulse_tween = null

	if is_instance_valid(_light):
		_light.light_energy = min_light_energy
	if is_instance_valid(_particles):
		_particles.emitting = active
		_particles.amount = min_particle_amount

	if active:
		_start_pulse()

func _start_pulse() -> void:
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.set_trans(Tween.TRANS_SINE)
	_pulse_tween.set_ease(Tween.EASE_IN_OUT)
	if is_instance_valid(_light):
		_pulse_tween.tween_property(_light, "light_energy", max_light_energy, pulse_duration)
	if is_instance_valid(_particles):
		_pulse_tween.parallel().tween_property(_particles, "amount", max_particle_amount, pulse_duration)
	if is_instance_valid(_light):
		_pulse_tween.tween_property(_light, "light_energy", min_light_energy, pulse_duration)
	if is_instance_valid(_particles):
		_pulse_tween.parallel().tween_property(_particles, "amount", min_particle_amount, pulse_duration)
