class_name PlayerV2
extends CharacterBody3D

# Movement constants
const WALK_SPEED: float = 3.0 
const SPRINT_SPEED: float = 5.0
const JUMP_VELOCITY: float = 4.5

# Lerp speed control
const GROUND_ACCELERATION: float = 8.0
const AIR_ACCELERATION: float = 3.0

# Character rotation
const ROTATION_SPEED: float = 10.0

# Private vars
var _current_speed: float = WALK_SPEED
var _is_mouse_captured: bool = true
var _facing_direction: float = 1.0 

# Node references
@onready var _animation_player: AnimationPlayer = $visuals/player_model/AnimationPlayer
@onready var _visuals: Node3D = $visuals

# Interaction variables
var _nearby_interactables: Array[Interactable] = []
var _current_target: Interactable = null

func _ready() -> void:
	_capture_mouse()

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("escape"):
		_toggle_mouse_capture()

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_jump()
	_handle_sprint()
	_handle_movement(delta)
	_update_facing_direction()
	_resolve_interaction_target()
	_handle_interact_input()
	
	move_and_slide()


#region Movement Methods
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta


func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY


func _handle_sprint() -> void:
	if Input.is_action_pressed("sprint"):
		if _animation_player.current_animation != "running":
			_animation_player.play("running")
		_current_speed = SPRINT_SPEED 
	else:
		_current_speed = WALK_SPEED


func _handle_movement(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	
	var acceleration: float = GROUND_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	
	
	if direction != Vector3.ZERO:
		var is_sprinting: bool = Input.is_action_pressed("sprint")
		
		if not is_sprinting:
			if _animation_player.current_animation != "walking":
				_animation_player.play("walking")
		
		velocity.x = lerp(velocity.x, direction.x * _current_speed, delta * acceleration)
		velocity.z = lerp(velocity.z, direction.z * _current_speed, delta * acceleration)
		
		_update_character_rotation_to_movement(direction, delta)
	else:
		if is_on_floor():
			if _animation_player.current_animation != "idle":
				_animation_player.play("idle")
			velocity.x = lerp(velocity.x, 0.0, delta * acceleration)
			velocity.z = lerp(velocity.z, 0.0, delta * acceleration)
#endregion


#region Character Rotation
func _update_character_rotation_to_movement(move_direction: Vector3, delta: float) -> void:
	# Calculate target rotation based on movement direction
	# atan2 gives us the angle in radians for any X,Z combination
	# This supports 8-directional (and smooth 360°) rotation
	
	# IMPORTANT: Your model faces -Z, so we need to add PI to the angle
	var target_angle: float = atan2(move_direction.x, move_direction.z) + PI
	
	# Smooth interpolation for rotation
	_visuals.rotation.y = lerp_angle(_visuals.rotation.y, target_angle, delta * ROTATION_SPEED)

func _update_facing_direction() -> void:
	var input_x: float = Input.get_axis("move_left", "move_right")
	if input_x != 0.0:
		_facing_direction = sign(input_x)
#endregion


#region Input Utility Methods
func _capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_is_mouse_captured = true


func _toggle_mouse_capture() -> void:
	if _is_mouse_captured:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_is_mouse_captured = false
	else:
		_capture_mouse()
#endregion

#region Interaction Methods
func _resolve_interaction_target() -> void:
	_current_target = null
	%InteractText.hide()
	
	if _nearby_interactables.is_empty():
		return
	
	 # Only one nearby — skip the dot product check, just use it.
	if _nearby_interactables.size() == 1:
		_current_target = _nearby_interactables[0]
		%InteractText.show()
		return
	
	# Multiple nearby — pick the closest one the player is facing.
	var best_target: Interactable = null
	var best_distance: float = INF
	
	for interactable: Interactable in _nearby_interactables:
		var to_target: Vector3 = interactable.global_position - global_position
		# Dot product: positive means the object is in the facing direction.
		var dot: float = to_target.normalized().dot(Vector3(_facing_direction, 0.0, 0.0))
		
		if dot > 0.3:  # 0.3 = ~72° cone of acceptance. Widen or narrow to taste.
			var dist: float = to_target.length()
			if dist < best_distance:
				best_distance = dist
				best_target = interactable
	
	if best_target != null:
		_current_target = best_target
		%InteractText.show()

func _handle_interact_input() -> void:
	if _current_target == null:
		return
	if Input.is_action_just_pressed("interact"):
		_current_target.interact()

# These are connected via the Interactable's signals — see note below.
func _on_interactable_entered(interactable: Interactable) -> void:
	if not _nearby_interactables.has(interactable):
		_nearby_interactables.append(interactable)

func _on_interactable_exited(interactable: Interactable) -> void:
	_nearby_interactables.erase(interactable)
#endregion

#nig
