class_name AmbientAnimal
extends Node3D
## Decorative, scene-owned animal. Parent-space routes follow its saved start position.

enum Species { CAT, DOG }
enum State { IDLE, WALK, SIT_ENTER, SIT, SIT_EXIT, LIE_ENTER, LIE, LIE_EXIT, SNIFF }

@export var species: Species = Species.CAT
@export var material_variants: Array[Material] = []
@export var waypoints: PackedVector3Array = PackedVector3Array()
@export var allow_running: bool = false
@export var walk_speed: float = 0.43
@export var run_speed: float = 2.2
@export var player_pause_distance: float = 0.9

var _animation_player: AnimationPlayer
var _mesh_instances: Array[MeshInstance3D] = []
var _rng := RandomNumberGenerator.new()
var _state: State = State.IDLE
var _wait: float = 0.0
var _clip: StringName = &""
var _waypoint_index: int = 1
var _waypoint_step: int = 1
var _running: bool = false
var _player_blocked: bool = false
var _storm_suspended: bool = false
var _player: Node3D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_rng.randomize()
	var players := find_children("*", "AnimationPlayer", true, false)
	if players.size() != 1 or material_variants.is_empty():
		_disable("Expected one AnimationPlayer and at least one coat material.")
		return
	_animation_player = players[0] as AnimationPlayer
	_animation_player.process_mode = Node.PROCESS_MODE_INHERIT
	_animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	var required: Array[StringName] = [&"idle_loop", &"walk_loop", &"sit_enter", &"sit_loop", &"sit_exit"]
	if species == Species.DOG:
		required.append_array([&"wag_loop", &"run_loop", &"sniff", &"lie_enter", &"lie_loop", &"lie_exit"])
	for clip in required:
		if not _animation_player.has_animation(clip):
			_disable("Missing animation: %s." % clip)
			return
		var expected := Animation.LOOP_LINEAR if String(clip).ends_with("_loop") else Animation.LOOP_NONE
		if _animation_player.get_animation(clip).loop_mode != expected:
			_disable("Incorrect imported loop mode: %s." % clip)
			return
	var template := material_variants[_rng.randi_range(0, material_variants.size() - 1)]
	if template == null:
		_disable("Coat material is missing.")
		return
	var coat := template.duplicate() as Material
	for node in find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		mesh.material_override = coat
		_mesh_instances.append(mesh)
	_animation_player.animation_finished.connect(_on_animation_finished)
	GlobalTimer.storm_arrived.connect(_stop_for_storm)
	_player = get_tree().get_first_node_in_group("player") as Node3D
	if waypoints.size() >= 2:
		var offset := position - waypoints[0]
		waypoints = waypoints.duplicate()
		for index in waypoints.size():
			waypoints[index] += offset
		_begin_idle(_rng.randf_range(4.0, 8.0), true)
	else:
		_state = State.SIT
		_wait = _rng.randf_range(22.0, 38.0)
		_play_clip(&"sit_loop", true)
	if SceneManager.storm_transition_pending:
		_stop_for_storm()


func _physics_process(delta: float) -> void:
	if _storm_suspended:
		return
	if SceneManager.storm_transition_pending:
		_stop_for_storm()
		return
	if _state == State.WALK:
		_update_walk(delta)
		return
	if _state not in [State.IDLE, State.SIT, State.LIE]:
		return
	_wait -= delta
	if _wait > 0.0:
		return
	match _state:
		State.SIT:
			_state = State.SIT_EXIT
			_play_clip(&"sit_exit")
		State.LIE:
			_state = State.LIE_EXIT
			_play_clip(&"lie_exit")
		State.IDLE:
			if waypoints.size() >= 2:
				_begin_walk()
			else:
				_state = State.SIT_ENTER
				_play_clip(&"sit_enter")


func _update_walk(delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
	_player_blocked = false
	if is_instance_valid(_player):
		var separation := global_position - _player.global_position
		_player_blocked = Vector2(separation.x, separation.z).length_squared() < player_pause_distance * player_pause_distance
	var offset := waypoints[_waypoint_index] - position
	var yaw := atan2(-offset.x, -offset.z)
	if _player_blocked:
		_play_clip(&"idle_loop")
		return
	rotation.y = rotate_toward(rotation.y, yaw, 3.0 * delta)
	# Turn in place before a straight leg so translation stays within its route.
	if absf(angle_difference(rotation.y, yaw)) > 0.12:
		_play_clip(&"idle_loop")
		return
	_play_clip(&"run_loop" if _running else &"walk_loop")
	position = position.move_toward(waypoints[_waypoint_index], (run_speed if _running else walk_speed) * delta)
	if position == waypoints[_waypoint_index]:
		if _waypoint_index == waypoints.size() - 1:
			_waypoint_step = -1
		elif _waypoint_index == 0:
			_waypoint_step = 1
		_waypoint_index += _waypoint_step
		_choose_rest()


func _begin_walk() -> void:
	if waypoints.size() < 2 or _storm_suspended:
		return
	_state = State.WALK
	_running = species == Species.DOG and allow_running and _rng.randf() < 0.2
	_player_blocked = false


func _choose_rest() -> void:
	_running = false
	var choice := _rng.randf()
	if species == Species.CAT:
		if choice < 0.25:
			_state = State.SIT_ENTER
			_play_clip(&"sit_enter")
		else:
			_begin_idle(_rng.randf_range(4.0, 8.0))
	elif choice < 0.3:
		_state = State.SNIFF
		_play_clip(&"sniff")
	elif choice < 0.45:
		_state = State.SIT_ENTER
		_play_clip(&"sit_enter")
	elif choice < 0.55:
		_state = State.LIE_ENTER
		_play_clip(&"lie_enter")
	else:
		_begin_idle(_rng.randf_range(3.0, 7.0))


func _begin_idle(seconds: float, random_phase: bool = false) -> void:
	_state = State.IDLE
	_wait = seconds
	var wag := species == Species.DOG and _rng.randf() < 0.4
	_play_clip(&"wag_loop" if wag else &"idle_loop", random_phase)


func _play_clip(clip: StringName, random_phase: bool = false) -> void:
	if _storm_suspended or clip == _clip or not is_instance_valid(_animation_player):
		return
	_clip = clip
	_animation_player.play(clip, 0.15)
	if random_phase:
		_animation_player.seek(_rng.randf_range(0.0, _animation_player.get_animation(clip).length), true)


func _on_animation_finished(clip: StringName) -> void:
	if _storm_suspended or clip != _clip:
		return
	match _state:
		State.SIT_ENTER:
			_state = State.SIT
			_wait = _rng.randf_range(22.0, 38.0) if waypoints.size() < 2 else _rng.randf_range(10.0, 18.0)
			_play_clip(&"sit_loop")
		State.LIE_ENTER:
			_state = State.LIE
			_wait = _rng.randf_range(8.0, 14.0)
			_play_clip(&"lie_loop")
		State.SIT_EXIT, State.LIE_EXIT, State.SNIFF:
			_begin_idle(_rng.randf_range(4.0, 7.0) if waypoints.size() < 2 else _rng.randf_range(1.0, 2.5))


func _stop_for_storm() -> void:
	_storm_suspended = true
	set_physics_process(false)
	if is_instance_valid(_animation_player):
		_animation_player.pause()


func _disable(reason: String) -> void:
	push_warning("AmbientAnimal %s: %s" % [name, reason])
	set_physics_process(false)
	if is_instance_valid(_animation_player):
		_animation_player.stop()


func _exit_tree() -> void:
	if GlobalTimer.storm_arrived.is_connected(_stop_for_storm):
		GlobalTimer.storm_arrived.disconnect(_stop_for_storm)
	if is_instance_valid(_animation_player):
		_animation_player.stop(true)
