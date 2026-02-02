class_name Player
extends CharacterBody3D

# First-person player controller

# Movement constants
const WALK_SPEED : float = 3.0 
const SPRINT_SPEED : float = 5.0
const JUMP_VELOCITY : float = 4.5

# lerp speed control
const GROUND_ACCELERATION : float = 8.0
const AIR_ACCELERATION : float = 3.0

# camera effects
const BASE_FOV : float = 75.0
const FOV_CHANGE_MULTIPLIER : float = 1.5

const HEAD_BOB_FREQUENCY : float = 2.0
const HEAD_BOB_AMPLITUDE : float = 0.08

# mouse sesitivity
@export_range(0.001, 0.01, 0.001) var mouse_sensitivity: float = 0.003

# private var
var _current_speed : float = WALK_SPEED
var _head_bob_time : float = 0.0
var _is_mouse_captured : bool = true

# flashlight variables
const FLASHLIGHT_ROTATION_SMOOTHNESS : float = 10.0
const FLASHLIGHT_POSITION_SMOOTHNESS : float = 8.0

# flashlight tuning (REFERENCE)
# FLASHLIGHT_ROTATION_SMOOTHNESS:
# ---> heavy lantern, drunk holding = 5.0
# ---> handheld flashlight, default = 15.0
# ---> helmet mounted light = 30.0
# ---> laser pointer = 100.0
# FLASHLIGHT_POSITION_SMOOTHNESS:
# ---> floating on rope = 5.0
# ---> handheld flashlight, default = 15.0
# ---> wrist mounted = 25.0
# ---> head mounted = 50

# node references
@onready var _head : Node3D = $Head
@onready var _camera : Camera3D = $Head/Camera3D
@onready var _flashlight : SpotLight3D = $Flashlight


func _ready() -> void:
	_capture_mouse()
	_initialize_flashlight()


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("escape"):
		_toggle_mouse_capture()
	
	# Toggle flashlight with input
	if Input.is_action_just_pressed("toggle_flashlight"):
		_toggle_flashlight()
	
	if event is InputEventMouseMotion and _is_mouse_captured:
		_handle_mouse_look(event.relative)


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_jump()
	_handle_sprint()
	_handle_movement(delta)
	_update_camera_effects(delta)
	_update_flashlight(delta)
	
	move_and_slide()

# ============================METHODS==============================================================
# movement methods
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

func _handle_sprint() -> void:
	_current_speed = SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED

func _handle_movement(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector3 = (_head.transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	
	# Choose acceleration based on grounded state
	var acceleration: float = GROUND_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	
	# strafing controls
	if direction != Vector3.ZERO:
		velocity.x = lerp(velocity.x, direction.x * _current_speed, delta * acceleration)
		velocity.z = lerp(velocity.z, direction.z * _current_speed, delta * acceleration)
	else:
		# Decelerate when no input
		if is_on_floor():
			velocity.x = lerp(velocity.x, 0.0, delta * acceleration)
			velocity.z = lerp(velocity.z, 0.0, delta * acceleration)
	
func _handle_mouse_look(relative_motion: Vector2) -> void:
	_head.rotate_y(-relative_motion.x * mouse_sensitivity)
	_camera.rotate_x(-relative_motion.y * mouse_sensitivity)
	# up down look, adjust (-40, 60) 
	_camera.rotation.x = clamp(_camera.rotation.x, deg_to_rad(-40.0), deg_to_rad(60.0))

func _update_camera_effects(delta: float) -> void:
	_apply_head_bob(delta)
	_apply_fov_effect(delta)

func _apply_head_bob(delta: float) -> void:
	_head_bob_time += delta * velocity.length() * float(is_on_floor())
	_camera.transform.origin = _calculate_head_bob_offset(_head_bob_time)

func _calculate_head_bob_offset(time: float) -> Vector3:
	var offset: Vector3 = Vector3.ZERO
	offset.y = sin(time * HEAD_BOB_FREQUENCY) * HEAD_BOB_AMPLITUDE
	offset.x = cos(time * HEAD_BOB_FREQUENCY * 0.5) * HEAD_BOB_AMPLITUDE
	return offset

func _apply_fov_effect(delta: float) -> void:
	# Speed-based FOV
	var speed_clamped: float = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2.0)
	var target_fov: float = BASE_FOV + (FOV_CHANGE_MULTIPLIER * speed_clamped)
	
	# Lerp for smooth FOV transitions
	_camera.fov = lerp(_camera.fov, target_fov, delta * 8.0)

# flashlight methods
func _initialize_flashlight() -> void:
	_flashlight.global_transform = _camera.global_transform
	_flashlight.visible = false

func _toggle_flashlight() -> void:
	_flashlight.visible = not _flashlight.visible

func _update_flashlight(delta: float) -> void:
	# ROTATION: Use Quaternion slerp to avoid gimbal lock
	var current_rotation: Quaternion = Quaternion(_flashlight.global_transform.basis)
	var target_rotation: Quaternion = Quaternion(_camera.global_transform.basis)
	var smoothed_rotation: Quaternion = current_rotation.slerp(
		target_rotation, 
		delta * FLASHLIGHT_ROTATION_SMOOTHNESS
	)
	
	# POSITION: Linear interpolation for positional lag
	var current_position: Vector3 = _flashlight.global_position
	var target_position: Vector3 = _camera.global_position
	var smoothed_position: Vector3 = current_position.lerp(
		target_position,
		delta * FLASHLIGHT_POSITION_SMOOTHNESS
	)
	
	# Apply smoothed transform
	# Note: We modify global_transform directly to work in world space
	_flashlight.global_transform = Transform3D(
		Basis(smoothed_rotation),
		smoothed_position
	)

# Input util methods
func _capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_is_mouse_captured = true

func _toggle_mouse_capture() -> void:
	if _is_mouse_captured:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_is_mouse_captured = false
	else:
		_capture_mouse()
