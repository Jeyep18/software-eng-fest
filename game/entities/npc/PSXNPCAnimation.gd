class_name PSXNPCAnimation
extends Node

@export var npc_path: NodePath = NodePath("../Area3D")
@export var model_path: NodePath = NodePath("../visuals/mixamo_base")
@export var donation_reaction: bool = false

var _npc: NPC
var _animation_player: AnimationPlayer
var _canvas_layer: CanvasLayer
var _choice_prompt: Control
var _fidget_clips: Array[StringName] = []
var _clip: StringName = &""
var _talking: bool = false
var _modal_open: bool = false
var _fidget_wait: float = 0.0
var _pending_thanks: bool = false
var _donated: bool = false
var _storm_suspended: bool = false
var _skeleton: Skeleton3D
var _head_look: LookAtModifier3D
var _head_target: Node3D
var _look_player: Node3D
var _player_skeleton: Skeleton3D
var _player_head: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_npc = get_node_or_null(npc_path) as NPC
	var model := get_node_or_null(model_path)
	_canvas_layer = get_parent().get_node_or_null("CanvasLayer") as CanvasLayer
	if _npc == null or model == null:
		_disable("NPC or model path is invalid.")
		return
	var players := model.find_children("*", "AnimationPlayer", true, false)
	if players.size() != 1:
		for player in players:
			(player as AnimationPlayer).stop(true)
		_disable("The model must contain exactly one AnimationPlayer.")
		return
	_animation_player = players[0] as AnimationPlayer
	_animation_player.process_mode = Node.PROCESS_MODE_PAUSABLE
	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	if skeletons.size() != 1 or (skeletons[0] as Skeleton3D).find_bone("Head") < 0:
		_disable("The model must contain one skeleton with a Head bone.")
		return
	_skeleton = skeletons[0] as Skeleton3D
	_setup_head_tracking()
	var required_clips: Array[StringName] = [
		&"idle_loop", &"talk_enter", &"talk_loop", &"talk_exit",
	]
	if donation_reaction:
		required_clips.append_array([&"thank_you", &"relieved_loop"])
	for clip in required_clips:
		if not _animation_player.has_animation(clip):
			_disable("Missing required animation: %s." % clip)
			return
	for clip_name in _animation_player.get_animation_list():
		var clip := StringName(clip_name)
		var animation := _animation_player.get_animation(clip)
		var should_loop := clip in [&"idle_loop", &"talk_loop", &"relieved_loop"]
		var expected_mode := Animation.LOOP_LINEAR if should_loop else Animation.LOOP_NONE
		if animation.loop_mode != expected_mode:
			_disable("Invalid imported loop mode for animation: %s." % clip)
			return
		if clip_name.begins_with("fidget_"):
			_fidget_clips.append(clip)
	_fidget_clips.sort()
	_animation_player.animation_finished.connect(_on_animation_finished)
	_npc.prompt_visibility_changed.connect(_on_prompt_visibility_changed)
	_donated = donation_reaction and GameState.grocery_donation_given
	_begin_rest()
	_sync_state()


func _process(delta: float) -> void:
	_sync_state()
	_update_head_tracking(delta)
	if not is_instance_valid(_animation_player) or not is_instance_valid(_npc):
		return
	if _storm_suspended or _talking or _modal_open or _donated or _fidget_clips.is_empty():
		return
	if _clip != &"idle_loop":
		return
	_fidget_wait -= delta
	if _fidget_wait <= 0.0:
		var clip: StringName = _fidget_clips.pick_random()
		_play_clip(clip)


func _sync_state() -> void:
	if not is_inside_tree() or not is_instance_valid(_animation_player) or not is_instance_valid(_npc):
		return
	if _suspend_for_storm() or not can_process():
		return
	if not is_instance_valid(_choice_prompt) and is_instance_valid(_canvas_layer):
		_choice_prompt = _canvas_layer.get_node_or_null("ChoicePrompt") as Control
	var modal_open := is_instance_valid(_choice_prompt) and _choice_prompt.visible
	modal_open = modal_open or (is_instance_valid(ShopUi.shop_panel) and ShopUi.shop_panel.visible)
	if _modal_open and not modal_open:
		_fidget_wait = randf_range(4.0, 7.0)
	_modal_open = modal_open
	var donated := donation_reaction and GameState.grocery_donation_given
	var donation_changed := donated != _donated
	if donation_changed:
		_donated = donated
		_pending_thanks = donated
	var talking := _npc.is_showing
	if _storm_suspended:
		_storm_suspended = false
		_pending_thanks = false
		_talking = talking
		if _talking:
			_play_clip(&"talk_enter")
		else:
			_begin_rest()
		return
	if talking != _talking:
		_talking = talking
		_play_clip(&"talk_enter" if _talking else &"talk_exit")
		return
	if _talking:
		return
	if _modal_open and (_fidget_clips.has(_clip) or _clip == &"thank_you"):
		_begin_rest()
		return
	if donation_changed and _clip != &"talk_exit":
		_begin_rest()
		return
	if _donated and _pending_thanks and not _modal_open and _clip in [&"idle_loop", &"relieved_loop"]:
		_begin_rest()


func _on_prompt_visibility_changed(_should_show: bool) -> void:
	# Prompt signals repeat per line; only is_showing changes conversation state.
	_sync_state()


func _on_animation_finished(clip: StringName) -> void:
	if not is_inside_tree() or not is_instance_valid(_animation_player):
		return
	if _suspend_for_storm() or not can_process():
		return
	var was_suspended := _storm_suspended
	_sync_state()
	if was_suspended or _storm_suspended or clip != _clip:
		return
	if clip == &"talk_enter" and _talking:
		_play_clip(&"talk_loop")
	elif clip == &"talk_exit" and not _talking:
		_begin_rest()
	elif clip == &"thank_you":
		_begin_rest()
	elif _fidget_clips.has(clip):
		_begin_rest()


func _begin_rest() -> void:
	if not is_inside_tree() or not is_instance_valid(_animation_player):
		return
	if _suspend_for_storm() or not can_process():
		return
	_fidget_wait = randf_range(4.0, 7.0)
	if _donated and _pending_thanks and not _modal_open and not _talking:
		_play_clip(&"thank_you")
	else:
		_play_clip(&"relieved_loop" if _donated else &"idle_loop")


func _play_clip(clip: StringName) -> void:
	if not is_inside_tree() or not is_instance_valid(_animation_player):
		return
	if _suspend_for_storm() or not can_process():
		return
	if clip == &"thank_you":
		_pending_thanks = false
	_clip = clip
	_animation_player.play(clip, 0.0)
	_animation_player.advance(0.0)


func _suspend_for_storm() -> bool:
	if not SceneManager.storm_transition_pending:
		return false
	if not _storm_suspended:
		_animation_player.stop(true)
		if is_instance_valid(_head_look):
			_head_look.influence = 0.0
			_head_look.active = false
		_pending_thanks = false
		_storm_suspended = true
	return true


func _setup_head_tracking() -> void:
	_head_target = Node3D.new()
	_head_target.name = "DialogueLookTarget"
	add_child(_head_target)
	_head_look = LookAtModifier3D.new()
	_head_look.name = "DialogueHeadLook"
	_head_look.active = false
	_head_look.influence = 0.0
	_head_look.relative = false
	_head_look.forward_axis = SkeletonModifier3D.BONE_AXIS_PLUS_Z
	_head_look.primary_rotation_axis = Vector3.AXIS_Y
	_head_look.use_angle_limitation = true
	_head_look.symmetry_limitation = true
	# Symmetric native limits specify the total range, not the angle on each side.
	_head_look.primary_limit_angle = deg_to_rad(110.0)
	_head_look.secondary_limit_angle = deg_to_rad(40.0)
	_head_look.primary_damp_threshold = 1.0
	_head_look.secondary_damp_threshold = 1.0
	_skeleton.add_child(_head_look)
	_head_look.bone_name = "Head"
	_head_look.target_node = _head_look.get_path_to(_head_target)


func _update_head_tracking(delta: float) -> void:
	if not is_instance_valid(_head_look) or not can_process() or _storm_suspended:
		return
	var track := _talking and not _modal_open
	if track and not is_instance_valid(_look_player):
		_look_player = get_tree().get_first_node_in_group("player") as Node3D
		_player_skeleton = null
		_player_head = -1
		if is_instance_valid(_look_player):
			var skeletons := _look_player.find_children("*", "Skeleton3D", true, false)
			if not skeletons.is_empty():
				_player_skeleton = skeletons[0] as Skeleton3D
				# PlayerV2's head joint is named spine.005 in the existing game rig.
				_player_head = _player_skeleton.find_bone("spine.005")
	track = track and is_instance_valid(_look_player) and _look_player.is_inside_tree()
	if track:
		var face := _look_player.global_position + Vector3.UP * 1.85
		if is_instance_valid(_player_skeleton) and _player_head >= 0:
			face = (_player_skeleton.global_transform * _player_skeleton.get_bone_global_pose(_player_head)).origin + Vector3.UP * 0.1
		var head := _skeleton.global_transform * _skeleton.get_bone_global_pose(_head_look.bone)
		var forward := (_skeleton.global_basis * _skeleton.get_bone_global_rest(_head_look.bone).basis.z).normalized()
		var direction := face - head.origin
		track = direction.length_squared() > 0.01 and direction.dot(forward) > 0.0
		if track:
			_head_target.global_position = face
	_head_look.influence = move_toward(_head_look.influence, 1.0 if track else 0.0, delta * 4.0)
	_head_look.active = _head_look.influence > 0.0
	if not _talking and not _head_look.active:
		_look_player = null
		_player_skeleton = null


func _disable(reason: String) -> void:
	push_error("PSXNPCAnimation: %s (%s)" % [reason, get_path()])
	set_process(false)
	if is_instance_valid(_animation_player):
		_animation_player.stop(true)


func _exit_tree() -> void:
	set_process(false)
	if is_instance_valid(_head_look):
		_head_look.active = false
		_head_look.queue_free()
	if is_instance_valid(_animation_player):
		if _animation_player.animation_finished.is_connected(_on_animation_finished):
			_animation_player.animation_finished.disconnect(_on_animation_finished)
		_animation_player.stop(true)
	if is_instance_valid(_npc) and _npc.prompt_visibility_changed.is_connected(_on_prompt_visibility_changed):
		_npc.prompt_visibility_changed.disconnect(_on_prompt_visibility_changed)
