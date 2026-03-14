class_name Camera2D5Controller
extends Node3D

## Dynamic camera controller for 2.5D games with smooth follow and look-ahead
## CONFIGURED FOR MODELS FACING -Z AXIS

#region Camera Settings
@export_group("Follow Settings")
@export var follow_target: Node3D
@export var follow_smoothness: float = 1.0
@export var offset: Vector3 = Vector3(0, 2, 6)

@export_group("Look At Settings")
@export var look_at_height_offset: float = 1.0

@export_group("Look Ahead")
@export var look_ahead_enabled: bool = true
@export var look_ahead_distance: float = 0.5
@export var look_ahead_smoothness: float = 3.0

@export_group("Camera Shake")
@export var shake_enabled: bool = false
@export var landing_shake_amount: float = 0.2
@export var landing_shake_duration: float = 0.15

@export_group("Depth of Field Blur")
@export var blur_far_distance: float = 20.0
@export var blur_far_transition: float = 5.0
#endregion

#region Private State
var _velocity_smoothed: Vector3 = Vector3.ZERO
var _shake_offset: Vector3 = Vector3.ZERO
var _shake_timer: float = 0.0
var _shake_amount: float = 0.0
var _was_in_air: bool = false
#endregion

#region Node References
@onready var _camera: Camera3D = $Camera3D
#endregion


func _ready() -> void:
	if not follow_target:
		follow_target = get_parent() as Node3D
		if follow_target:
			push_warning("Camera auto-assigned to parent. Set follow_target explicitly.")
	
	# IMPORTANT: Make camera look at player initially
	if follow_target:
		var look_target: Vector3 = follow_target.global_position + Vector3(0, look_at_height_offset, 0)
		_camera.look_at(look_target, Vector3.UP)
	
	# Enable depth of field (optional cinematic effect)
	var camera_attributes := CameraAttributesPractical.new()
	camera_attributes.dof_blur_far_enabled = true
	camera_attributes.dof_blur_far_distance = blur_far_distance
	camera_attributes.dof_blur_far_transition = blur_far_transition
	
	_camera.attributes = camera_attributes


func _physics_process(delta: float) -> void:
	if not follow_target:
		return
	
	_update_camera_position(delta)
	_update_camera_shake(delta)
	_detect_landing()


#region Camera Follow Logic
func _update_camera_position(delta: float) -> void:
	var target_pos: Vector3 = follow_target.global_position + offset
	
	# Add look-ahead based on player velocity
	if look_ahead_enabled and follow_target is CharacterBody3D:
		var player_velocity: Vector3 = (follow_target as CharacterBody3D).velocity
		
		_velocity_smoothed = _velocity_smoothed.lerp(player_velocity, delta * look_ahead_smoothness)
		
		# Look ahead horizontally (X and Z)
		var look_ahead_offset: Vector3 = Vector3(
			_velocity_smoothed.x * look_ahead_distance,
			0.0,
			_velocity_smoothed.z * look_ahead_distance
		)
		
		target_pos -= look_ahead_offset
	
	# Smooth follow
	global_position = global_position.lerp(target_pos, delta * follow_smoothness)
	
	# Keep camera looking at player
	var look_target: Vector3 = follow_target.global_position + Vector3(0, look_at_height_offset, 0)
	_camera.look_at(look_target, Vector3.UP)
	
	# Apply shake offset (local to camera)
	_camera.position = _shake_offset
#endregion


#region Camera Shake
func _update_camera_shake(delta: float) -> void:
	if _shake_timer > 0.0:
		_shake_timer -= delta
		
		_shake_offset = Vector3(
			randf_range(-_shake_amount, _shake_amount),
			randf_range(-_shake_amount, _shake_amount),
			0.0
		)
		
		_shake_amount = lerp(_shake_amount, 0.0, delta * 5.0)
	else:
		_shake_offset = _shake_offset.lerp(Vector3.ZERO, delta * 10.0)


func trigger_shake(amount: float, duration: float) -> void:
	_shake_amount = amount
	_shake_timer = duration


func _detect_landing() -> void:
	if not shake_enabled or not follow_target:
		return
	
	if not follow_target is CharacterBody3D:
		return
	
	var player: CharacterBody3D = follow_target as CharacterBody3D
	var is_in_air: bool = not player.is_on_floor()
	
	if _was_in_air and not is_in_air:
		trigger_shake(landing_shake_amount, landing_shake_duration)
	
	_was_in_air = is_in_air
#endregion
