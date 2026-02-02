class_name Player
extends CharacterBody3D

# First-person player controller

# Movement constants
const WALK_SPEED : float = 5.0
const SPRINT_SPEED : float = 8.0
const JUMP_VELOCITY : float = 4.5

# lerp speed control
const GROUND_ACCELERATION : float = 7.0
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

# node references
@onready var _head : Node3D = $Head
@onready var _camera : Camera3D = $Head/Camera3D


func _ready() -> void:
	_capture_mouse()


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("escape"):
		_toggle_mouse_capture()
	
	if event is InputEventMouseMotion and _is_mouse_captured:
		_handle_mouse_look(event.relative)


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_jump()
	_handle_sprint()
	_handle_movement(delta)
	_update_camera_effects(delta)
	
	move_and_slide()


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
		# Decelerate when no input (only on ground for realistic physics)
		if is_on_floor():
			velocity.x = lerp(velocity.x, 0.0, delta * acceleration)
			velocity.z = lerp(velocity.z, 0.0, delta * acceleration)
	
func _handle_mouse_look(relative_motion: Vector2) -> void:
	_head.rotate_y(-relative_motion.x * mouse_sensitivity)
	_camera.rotate_x(-relative_motion.y * mouse_sensitivity)
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
