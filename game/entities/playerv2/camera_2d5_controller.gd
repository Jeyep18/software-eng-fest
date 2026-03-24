class_name Camera2D5Controller
extends Node3D

## Dynamic camera controller for 2.5D games with smooth follow and look-ahead.
## Configured for models facing -Z axis.

#region Exports
@export_group("Follow Settings")
@export var follow_target: Node3D
@export var follow_smoothness: float = 3.0

@export_group("Default Offset (no volume)")
@export var default_z_distance: float = 5.0
@export var default_height_offset: float = 2.0

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
var _active_z_distance: float = 6.0
var _active_height_offset: float = 2.0
var _active_x_min: float = -999.0
var _active_x_max: float = 999.0
var _active_lock_y: bool = false
var _active_locked_y: float = 0.0
var _active_z_wall: float = 999.0
var _active_z_buffer: float = 1.5
var _active_z_dynamic: bool = false

var _is_transitioning: bool = false
var _transition_tween: Tween

var _velocity_smoothed: Vector3 = Vector3.ZERO

var _shake_offset: Vector3 = Vector3.ZERO
var _shake_timer: float = 0.0
var _shake_amount: float = 0.0
var _was_in_air: bool = false

var _current_volume: CameraVolume = null
#endregion


@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
	if not follow_target:
		follow_target = get_parent() as Node3D
		if follow_target:
			push_warning("Camera: follow_target auto-assigned to parent. Set explicitly.")
	
	_active_z_distance = default_z_distance
	_active_height_offset = default_height_offset
	
	if follow_target:
		global_position = _calculate_target_position()
		_camera.look_at(follow_target.global_position + Vector3(0, _active_height_offset, 0), Vector3.UP)
		
	_setup_depth_of_field()
	_connect_to_volumes()


func _physics_process(delta: float) -> void:
	if not follow_target:
		return
	_update_camera_position(delta)
	_update_camera_shake(delta)
	_detect_landing()


#region Volume Management
func _connect_to_volumes() -> void:
	var volumes: Array[Node] = get_tree().get_nodes_in_group("camera volume")
	for volume: Node in volumes:
		if volume is CameraVolume:
			var cv: CameraVolume = volume as CameraVolume
			cv.player_entered_volume.connect(_on_volume_entered)
			cv.player_exited_volume.connect(_on_volume_exited)


func _on_volume_entered(volume: CameraVolume) -> void:
	if volume == _current_volume:
		return
	_current_volume = volume
	_transition_to_volume(volume)


func _on_volume_exited(volume: CameraVolume) -> void:
	if volume != _current_volume:
		return
	_current_volume = null
	_transition_to_defaults()


func _transition_to_volume(volume: CameraVolume) -> void:
	if _transition_tween and _transition_tween.is_valid():
		_transition_tween.kill()
	
	_is_transitioning = true
	_transition_tween = create_tween()
	_transition_tween.set_ease(volume.transition_ease)
	_transition_tween.set_trans(Tween.TRANS_CUBIC)
	_transition_tween.set_parallel(true)
	
	_transition_tween.tween_property(self, "_active_z_distance", volume.z_distance, volume.transition_duration)
	_transition_tween.tween_property(self, "_active_height_offset", volume.height_offset, volume.transition_duration)
	_transition_tween.tween_property(self, "_active_x_min", volume.x_min, volume.transition_duration)
	_transition_tween.tween_property(self, "_active_x_max", volume.x_max, volume.transition_duration)
	_transition_tween.tween_property(self, "_active_locked_y", volume.locked_y_position, volume.transition_duration)
	_transition_tween.tween_property(self, "_active_z_wall", volume.z_wall_position, volume.transition_duration)
	_transition_tween.tween_property(self, "_active_z_buffer", volume.z_camera_buffer, volume.transition_duration)
	
	# Boolean flags switch immediately — no tween needed.
	_active_lock_y = volume.lock_y
	_active_z_dynamic = volume.z_dynamic_enabled
	
	_transition_tween.finished.connect(func() -> void: _is_transitioning = false)


func _transition_to_defaults() -> void:
	if _transition_tween and _transition_tween.is_valid():
		_transition_tween.kill()
	
	_transition_tween = create_tween()
	_transition_tween.set_parallel(true)
	_transition_tween.tween_property(self, "_active_z_distance", default_z_distance, 0.6)
	_transition_tween.tween_property(self, "_active_height_offset", default_height_offset, 0.6)
	_transition_tween.tween_property(self, "_active_x_min", -999.0, 0.6)
	_transition_tween.tween_property(self, "_active_x_max", 999.0, 0.6)
	_transition_tween.tween_property(self, "_active_z_wall", 999.0, 0.6)
	_active_lock_y = false
	_active_z_dynamic = false
#endregion


#region Camera Follow
func _calculate_target_position() -> Vector3:
	if not follow_target:
		return global_position
		
	var player_pos: Vector3 = follow_target.global_position
	var target_x: float = clampf(player_pos.x, _active_x_min, _active_x_max)
	
	var target_y: float
	if _active_lock_y:
		target_y = _active_locked_y + _active_height_offset
	else:
		target_y = player_pos.y + _active_height_offset
	
	var effective_z_distance: float = _active_z_distance
	if _active_z_dynamic:
		var z_camera_max: float = _active_z_wall - _active_z_buffer
		var desired_camera_z: float = player_pos.z + _active_z_distance
		if desired_camera_z > z_camera_max:
			# Compress distance so camera stops at wall boundary rather than hard-cutting.
			effective_z_distance = maxf(z_camera_max - player_pos.z, 0.5)
	
	return Vector3(target_x, target_y, player_pos.z + effective_z_distance)


func _update_camera_position(delta: float) -> void:
	var target_pos: Vector3 = _calculate_target_position()
	
	if look_ahead_enabled and follow_target is CharacterBody3D:
		var player_vel: Vector3 = (follow_target as CharacterBody3D).velocity
		_velocity_smoothed = _velocity_smoothed.lerp(player_vel, delta * look_ahead_smoothness)
		target_pos.x -= _velocity_smoothed.x * look_ahead_distance
		target_pos.x = clampf(target_pos.x, _active_x_min, _active_x_max)
	
	var effective_smoothness: float = follow_smoothness * (2.0 if _is_transitioning else 1.0)
	global_position = global_position.lerp(target_pos, delta * effective_smoothness)
	
	_camera.look_at(follow_target.global_position + Vector3(0, look_at_height_offset(), 0), Vector3.UP)
	_camera.position = _shake_offset


func look_at_height_offset() -> float:
	return _active_height_offset * 0.5
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
	if not shake_enabled or not (follow_target is CharacterBody3D):
		return
	
	var player: CharacterBody3D = follow_target as CharacterBody3D
	var is_in_air: bool = not player.is_on_floor()
	
	if _was_in_air and not is_in_air:
		trigger_shake(landing_shake_amount, landing_shake_duration)
	
	_was_in_air = is_in_air
#endregion


#region Setup
func _setup_depth_of_field() -> void:
	var attributes := CameraAttributesPractical.new()
	attributes.dof_blur_far_enabled = true
	attributes.dof_blur_far_distance = blur_far_distance
	attributes.dof_blur_far_transition = blur_far_transition
	_camera.attributes = attributes
#endregion
