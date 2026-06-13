class_name PlayerV2
extends CharacterBody3D

const WALK_SPEED: float = 3.0
const SPRINT_SPEED: float = 5.0
const JUMP_VELOCITY: float = 4.5
const GROUND_ACCELERATION: float = 12.0
const AIR_ACCELERATION: float = 3.0
const ROTATION_SPEED: float = 10.0
const DEFAULT_STEP_HEIGHT: float = 0.32
const TUTORIAL_MODAL_SCENE: PackedScene = preload("res://game/ui/tutorial/TutorialModal.tscn")
const UI_STYLE = preload("res://game/ui/GameUIStyle.gd")
const SFX = preload("res://game/audio/Sfx.gd")

@export_range(0.0, 0.8, 0.01) var max_step_height: float = DEFAULT_STEP_HEIGHT

var _current_speed: float = WALK_SPEED
var _is_mouse_captured: bool = true
var _facing_direction: float = 1.0
var _is_input_locked: bool = false
var _is_movement_locked: bool = false
var _previous_target: Interactable = null
var _prompt_suppressed: bool = false
var _nearby_interactables: Array[Interactable] = []
var _current_target: Interactable = null
var _desired_step_direction: Vector3 = Vector3.ZERO

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
	add_to_group("player")
	_setup_interact_prompt_style()
	_capture_mouse()
	_animation_player.animation_finished.connect(_on_animation_finished)

	if not SceneManager.has_played_opening:
		_is_input_locked = true
		SFX.rooster_morning()
		_play(ANIM_STAND_UP)
		SceneManager.has_played_opening = true
	else:
		_is_input_locked = false
		_play(ANIM_IDLE)

func _setup_interact_prompt_style() -> void:
	var prompt_layer := get_node_or_null("CanvasLayer") as CanvasLayer
	var prompt_box := get_node_or_null("CanvasLayer/BoxContainer") as BoxContainer
	var prompt_label := get_node_or_null("CanvasLayer/BoxContainer/InteractText") as Label
	if prompt_layer == null or prompt_box == null or prompt_label == null:
		return

	var old_shadow := prompt_layer.get_node_or_null("InteractPromptShadow")
	if old_shadow != null:
		old_shadow.queue_free()

	var prompt_background := prompt_layer.get_node_or_null("InteractPromptBackground") as ColorRect
	if prompt_background == null:
		prompt_background = ColorRect.new()
		prompt_background.name = "InteractPromptBackground"
		prompt_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		prompt_background.set_anchors_preset(Control.PRESET_CENTER)
		prompt_background.color = Color(0, 0, 0, 0.68)
		prompt_background.hide()
		prompt_layer.add_child(prompt_background)
		prompt_layer.move_child(prompt_background, prompt_box.get_index())

	prompt_background.color = Color(0, 0, 0, 0.68)
	prompt_background.offset_left = -118.0
	prompt_background.offset_top = -18.0
	prompt_background.offset_right = 118.0
	prompt_background.offset_bottom = 18.0
	prompt_box.offset_left = prompt_background.offset_left
	prompt_box.offset_top = prompt_background.offset_top
	prompt_box.offset_right = prompt_background.offset_right
	prompt_box.offset_bottom = prompt_background.offset_bottom
	prompt_box.alignment = BoxContainer.ALIGNMENT_CENTER
	prompt_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	prompt_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	prompt_label.custom_minimum_size = Vector2(236.0, 36.0)
	prompt_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prompt_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_override("font", UI_STYLE.FONT_SEMIBOLD)
	prompt_label.add_theme_font_size_override("font_size", 19)
	prompt_label.add_theme_color_override("font_color", Color.WHITE)
	prompt_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	prompt_label.add_theme_constant_override("shadow_offset_x", 2)
	prompt_label.add_theme_constant_override("shadow_offset_y", 2)

# ── Safe play wrapper — avoids restarting an already-playing animation ────────
func _play(anim_name: String) -> void:
	if _animation_player.current_animation != anim_name:
		_animation_player.play(anim_name)


func _on_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		ANIM_STAND_UP:
			_play(ANIM_IDLE)
			_show_start_tutorial_if_needed()

func _show_start_tutorial_if_needed() -> void:
	if not TutorialModal.should_show_on_start():
		_is_input_locked = false
		return

	var tutorial := TUTORIAL_MODAL_SCENE.instantiate()
	add_child(tutorial)
	var unlock_input := func() -> void:
		_is_input_locked = false
		tutorial.queue_free()
	tutorial.open(true, true, unlock_input, true)


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("escape"):
		_toggle_mouse_capture()


func _physics_process(delta: float) -> void:
	var was_on_floor: bool = is_on_floor()
	var previous_position: Vector3 = global_position
	_apply_gravity(delta)
	_handle_movement(delta)
	_update_facing_direction()
	_resolve_interaction_target()
	_handle_interact_input()
	move_and_slide()
	_try_step_up(delta, was_on_floor, previous_position)


#region Movement
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta


func _handle_movement(delta: float) -> void:
	_desired_step_direction = Vector3.ZERO

	if _is_input_locked or _is_movement_locked:
		_stop_horizontal_movement(delta)
		return

	var is_sprinting: bool = Input.is_action_pressed("sprint")
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var acceleration: float = GROUND_ACCELERATION if is_on_floor() else AIR_ACCELERATION

	_current_speed = SPRINT_SPEED if is_sprinting else WALK_SPEED

	if direction != Vector3.ZERO:
		_desired_step_direction = direction
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

func _try_step_up(delta: float, was_on_floor: bool, previous_position: Vector3) -> void:
	if max_step_height <= 0.0 or not was_on_floor or _desired_step_direction == Vector3.ZERO:
		return

	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	var expected_motion := horizontal_velocity * delta
	if expected_motion.length_squared() < 0.0001:
		expected_motion = _desired_step_direction * _current_speed * delta

	var actual_motion := global_position - previous_position
	actual_motion.y = 0.0
	if actual_motion.length_squared() >= expected_motion.length_squared() * 0.45:
		return

	var up_motion := Vector3.UP * max_step_height
	if test_move(global_transform, up_motion):
		return

	var raised_transform := global_transform
	raised_transform.origin += up_motion
	if test_move(raised_transform, expected_motion):
		return

	var landing_collision := KinematicCollision3D.new()
	var down_motion := Vector3.DOWN * (max_step_height + floor_snap_length + 0.05)
	var landing_transform := raised_transform
	landing_transform.origin += expected_motion
	if not test_move(landing_transform, down_motion, landing_collision):
		return

	if landing_collision.get_normal().dot(Vector3.UP) < cos(floor_max_angle):
		return

	var landing_position := landing_transform.origin + landing_collision.get_travel()
	var step_height := landing_position.y - previous_position.y
	if step_height <= 0.0 or step_height > max_step_height:
		return

	global_position = landing_position
	velocity.y = 0.0

func set_movement_locked(is_locked: bool) -> void:
	_is_movement_locked = is_locked
	if is_locked:
		velocity.x = 0.0
		velocity.z = 0.0
		if _animation_player != null:
			_play(ANIM_IDLE)
		_was_moving = false

func _stop_horizontal_movement(delta: float) -> void:
	var acceleration: float = GROUND_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = lerp(velocity.x, 0.0, delta * acceleration)
	velocity.z = lerp(velocity.z, 0.0, delta * acceleration)
	if _was_moving:
		_play(ANIM_IDLE)
		_was_moving = false


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
	_set_interact_prompt_visible(false)

	if _is_input_locked or _nearby_interactables.is_empty():
		_rewire_prompt_signal(null)
		return

	_nearby_interactables = _nearby_interactables.filter(func(interactable: Interactable) -> bool:
		return is_instance_valid(interactable)
	)
	if _nearby_interactables.is_empty():
		_rewire_prompt_signal(null)
		return

	if _nearby_interactables.size() == 1:
		if not _nearby_interactables[0].is_interaction_available():
			_rewire_prompt_signal(null)
			return
		_current_target = _nearby_interactables[0]
		%InteractText.text = _current_target.prompt_label
		if not _prompt_suppressed:
			_set_interact_prompt_visible(true)
		_rewire_prompt_signal(_current_target)
		return

	var best_target: Interactable = null
	var best_distance: float = INF

	for interactable: Interactable in _nearby_interactables:
		if not interactable.is_interaction_available():
			continue

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
			_set_interact_prompt_visible(true)

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
	_set_interact_prompt_visible(should_show)

func _set_interact_prompt_visible(should_show: bool) -> void:
	%InteractText.visible = should_show
	var prompt_background := get_node_or_null("CanvasLayer/InteractPromptBackground") as ColorRect
	if prompt_background != null:
		prompt_background.visible = should_show


func _handle_interact_input() -> void:
	if _is_interaction_blocked_by_ui():
		return
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

func _is_interaction_blocked_by_ui() -> bool:
	return get_node_or_null("/root/ShopUi") != null and ShopUi.is_open()
