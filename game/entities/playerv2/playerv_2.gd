class_name PlayerV2
extends CharacterBody3D

const WALK_SPEED: float = 3.0
const SPRINT_SPEED: float = 5.0
const JUMP_VELOCITY: float = 4.5
const GROUND_ACCELERATION: float = 12.0
const AIR_ACCELERATION: float = 3.0
const ROTATION_SPEED: float = 10.0

var _current_speed: float = WALK_SPEED
var _is_mouse_captured: bool = true
var _facing_direction: float = 1.0
var _is_input_locked: bool = false
var _previous_target: Interactable = null
var _prompt_suppressed: bool = false
var _nearby_interactables: Array[Interactable] = []
var _current_target: Interactable = null

# Track previous movement state to trigger transition animations correctly.
var _was_moving: bool = false

@onready var _animation_player: AnimationPlayer = $"visuals/simple-character-psx/AnimationPlayer"
@onready var _visuals: Node3D = $visuals

# ── Animation name constants — change library names here if you named them differently ──
const ANIM_IDLE:       String = "Idle/mixamo_com"
const ANIM_WALK:       String = "Walking (1)/mixamo_com"
const ANIM_RUN:        String = "Running (1)/mixamo_com"
const ANIM_STAND_UP:   String = "Stand Up (1)/mixamo_com"

func _ready() -> void:
	_capture_mouse()
	_animation_player.animation_finished.connect(_on_animation_finished)

	if not SceneManager.has_played_opening:
		_is_input_locked = true
		_play(ANIM_STAND_UP)
		SceneManager.has_played_opening = true
	else:
		_is_input_locked = false
		_play(ANIM_IDLE)


# ── Safe play wrapper — avoids restarting an already-playing animation ────────
func _play(anim_name: String) -> void:
	if _animation_player.current_animation != anim_name:
		_animation_player.play(anim_name)


func _on_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		ANIM_STAND_UP:
			_is_input_locked = false
			_play(ANIM_IDLE)


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("escape"):
		_toggle_mouse_capture()


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_movement(delta)
	_update_facing_direction()
	_resolve_interaction_target()
	_handle_interact_input()
	move_and_slide()


#region Movement
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta


func _handle_movement(delta: float) -> void:
	if _is_input_locked:
		return

	var is_sprinting: bool = Input.is_action_pressed("sprint")
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var acceleration: float = GROUND_ACCELERATION if is_on_floor() else AIR_ACCELERATION

	_current_speed = SPRINT_SPEED if is_sprinting else WALK_SPEED

	if direction != Vector3.ZERO:
		velocity.x = lerp(velocity.x, direction.x * _current_speed, delta * acceleration)
		velocity.z = lerp(velocity.z, direction.z * _current_speed, delta * acceleration)
		_update_character_rotation_to_movement(direction, delta)

		if is_sprinting:
			_play(ANIM_RUN)
		else:
			_play(ANIM_WALK)

		_was_moving = true

	else:
		if is_on_floor():
			velocity.x = lerp(velocity.x, 0.0, delta * acceleration)
			velocity.z = lerp(velocity.z, 0.0, delta * acceleration)

			if _was_moving:
				_play(ANIM_IDLE)
				_was_moving = false
#endregion


#region Rotation
func _update_character_rotation_to_movement(move_direction: Vector3, delta: float) -> void:
	var target_angle: float = atan2(move_direction.x, move_direction.z) + PI
	_visuals.rotation.y = lerp_angle(_visuals.rotation.y, target_angle, delta * ROTATION_SPEED)


func _update_facing_direction() -> void:
	var input_x: float = Input.get_axis("move_left", "move_right")
	if input_x != 0.0:
		_facing_direction = sign(input_x)
#endregion


#region Mouse Capture
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


#region Interaction
func _resolve_interaction_target() -> void:
	_current_target = null
	%InteractText.hide()

	if _is_input_locked or _nearby_interactables.is_empty():
		_rewire_prompt_signal(null)
		return

	if _nearby_interactables.size() == 1:
		_current_target = _nearby_interactables[0]
		%InteractText.text = _current_target.prompt_label
		if not _prompt_suppressed:
			%InteractText.show()
		_rewire_prompt_signal(_current_target)
		return

	var best_target: Interactable = null
	var best_distance: float = INF

	for interactable: Interactable in _nearby_interactables:
		var to_target: Vector3 = interactable.global_position - global_position
		var dot: float = to_target.normalized().dot(Vector3(_facing_direction, 0.0, 0.0))

		if dot > 0.3:
			var dist: float = to_target.length()
			if dist < best_distance:
				best_distance = dist
				best_target = interactable

	if best_target != null:
		_current_target = best_target
		%InteractText.text = _current_target.prompt_label
		if not _prompt_suppressed:
			%InteractText.show()

	_rewire_prompt_signal(_current_target)


func _rewire_prompt_signal(new_target: Interactable) -> void:
	if _previous_target == new_target:
		return

	if is_instance_valid(_previous_target) and _previous_target.prompt_visibility_changed.is_connected(_on_prompt_visibility_changed):
		_previous_target.prompt_visibility_changed.disconnect(_on_prompt_visibility_changed)

	_prompt_suppressed = false

	if new_target != null:
		new_target.prompt_visibility_changed.connect(_on_prompt_visibility_changed)

	_previous_target = new_target


func _on_prompt_visibility_changed(should_show: bool) -> void:
	_prompt_suppressed = not should_show
	if should_show:
		%InteractText.show()
	else:
		%InteractText.hide()


func _handle_interact_input() -> void:
	if _current_target == null:
		return

	if Input.is_action_just_pressed("interact"):
		_current_target.interact()
		return

	if Input.is_action_just_pressed("dialogue_advance") and _current_target.is_showing:
		_current_target.interact()


func _on_interactable_entered(interactable: Interactable) -> void:
	if not _nearby_interactables.has(interactable):
		_nearby_interactables.append(interactable)


func _on_interactable_exited(interactable: Interactable) -> void:
	_nearby_interactables.erase(interactable)
#endregion
