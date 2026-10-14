extends Node
## Run only in a disposable imported project with isolated userdata.

const TARGETS := {
	"MangNestor": "npcs/quests/mang_nestor",
	"MoneyBeggar": "npcs/quests/money_beggar",
	"SmokeBreakNPC": "npcs/quests/smoke_break_npc",
	"TapeNeighbor": "npcs/story/tape_neighbor",
	"TatayJun": "npcs/story/tatay_jun",
	"KapsWorker": "npcs/story/kaps_worker",
	"AteMaribel": "npcs/story/ate_maribel",
	"PalengkeQueueMan": "npcs/story/palengke_queue_man",
	"PanicBuyer": "npcs/story/panic_buyer",
	"WetParent": "npcs/story/wet_parent",
	"PharmaDude": "npcs/shops/pharmacist/pharma_dude",
}
const LOCATIONS := {
	"tindahan": ["MangNestor", "TapeNeighbor", "SmokeBreakNPC"],
	"hardware": ["TatayJun", "KapsWorker"],
	"grocery": ["PalengkeQueueMan", "PanicBuyer", "WetParent", "MoneyBeggar"],
	"pharmacy": ["PharmaDude", "AteMaribel"],
}
const HEIGHTS := {
	"MangNestor": 2.001256, "MoneyBeggar": 1.091945, "SmokeBreakNPC": 2.042097,
	"TapeNeighbor": 2.021677, "TatayJun": 2.021677, "KapsWorker": 2.042098,
	"AteMaribel": 1.878730, "PalengkeQueueMan": 2.021677, "PanicBuyer": 1.919572,
	"WetParent": 1.899151, "PharmaDude": 2.042098,
}
const FIDGETS := {
	"MangNestor": ["search_street", "rub_neck"],
	"MoneyBeggar": ["request_money", "look_around"],
	"SmokeBreakNPC": ["smoke", "look_around", "check_phone"],
	"TapeNeighbor": ["search_street", "inspect_tape"],
	"TatayJun": ["check_packet", "check_bag"],
	"KapsWorker": ["read_receipt", "check_street"],
	"AteMaribel": ["adjust_bag", "wipe_brow"],
	"PalengkeQueueMan": ["scan_queue", "shift_weight"],
	"PanicBuyer": ["look_around", "regrip_bags"],
	"WetParent": ["check_clothes", "pat_clothes"],
	"PharmaDude": ["read_carton", "check_slip"],
}
var checks := 0
var failures := 0

class PlayerFixture extends CharacterBody3D:
	var detected: Interactable
	var prompt := ""
	var locked := false
	func _on_interactable_entered(area: Interactable) -> void:
		detected = area
		prompt = area.prompt_label
	func _on_interactable_exited(area: Interactable) -> void:
		if detected == area:
			detected = null
			prompt = ""
	func set_movement_locked(value: bool) -> void:
		locked = value

func _ready() -> void:
	_run.call_deferred()

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
	print("STATIC_NPC ", "PASS " if condition else "FAIL ", description)

func _run() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.get_environment("BAGYONG_ISOLATED_SMOKE") != OS.get_user_data_dir():
		push_error("Static NPC regression requires explicit isolated userdata.")
		get_tree().quit(1)
		return
	get_tree().current_scene = null
	GlobalTimer.start_fresh()
	GlobalTimer.pause_timer(self)
	if OS.get_cmdline_user_args().has("--visual-only"):
		TutorialModal.mark_do_not_show_again()
		await _capture_locations()
	else:
		for target in TARGETS:
			await _test_npc(target)
	print("Static NPC regression: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)

func _nodes(node: Node) -> Array[Node]:
	var result: Array[Node] = [node]
	for child in node.get_children():
		result.append_array(_nodes(child))
	return result

func _snapshot(visuals: Node) -> Dictionary:
	var result := {}
	for node in _nodes(visuals):
		if node is Node3D:
			result[String(visuals.get_path_to(node))] = node.transform
	return result

func _finish_dialogue(npc: NPC) -> void:
	var player := _animation_player(npc.get_parent().get_node("visuals"))
	npc.interact()
	_check(npc._is_showing, "%s opens dialogue" % npc.get_parent().name)
	_check(player.current_animation == "talk_enter", "%s immediately enters conversation" % npc.get_parent().name)
	_complete_clip(player)
	_check(player.current_animation == "talk_loop", "%s enters conversation loop" % npc.get_parent().name)
	player.advance(0.125)
	var position := player.current_animation_position
	npc.interact()
	_check(player.current_animation == "talk_loop" and is_equal_approx(player.current_animation_position, position), "%s typing skip does not restart animation" % npc.get_parent().name)
	for step in range(64):
		if not npc._is_showing:
			break
		position = player.current_animation_position
		npc.interact()
		if npc._is_showing:
			_check(player.current_animation == "talk_loop" and is_equal_approx(player.current_animation_position, position), "%s next dialogue line does not restart animation" % npc.get_parent().name)
	_check(not npc._is_showing, "%s dialogue completes" % npc.get_parent().name)
	_check(player.current_animation == "talk_exit", "%s dialogue plays exit" % npc.get_parent().name)
	_complete_clip(player)
	await get_tree().process_frame
	_check(player.current_animation == ("relieved_loop" if npc.get_parent().name == "MoneyBeggar" and GameState.grocery_donation_given else "idle_loop"), "%s returns to rest after dialogue" % npc.get_parent().name)
	_check_modal_rest(npc, npc.get_parent().get_node("NPCAnimation"), player)

func _animation_player(visuals: Node) -> AnimationPlayer:
	for node in _nodes(visuals):
		if node is AnimationPlayer:
			return node
	return null

func _complete_clip(player: AnimationPlayer) -> void:
	# Finite advancement exercises animation_finished without waiting for real clip durations.
	player.advance(player.current_animation_length - player.current_animation_position + 0.001)

func _fixed_bones(skeleton: Skeleton3D) -> Dictionary:
	var result := {}
	for index in skeleton.get_bone_count():
		var bone := String(skeleton.get_bone_name(index)).to_lower()
		if bone == "root" or bone.begins_with("foot.") or bone.ends_with("foot"):
			result[index] = skeleton.get_bone_global_pose(index)
	return result

func _sample_clips(target: String, visuals: Node3D, player: AnimationPlayer) -> void:
	var skeleton: Skeleton3D
	var ground := {}
	for node in _nodes(visuals):
		if node is Skeleton3D:
			skeleton = node
		elif node is MeshInstance3D and node.skin == null:
			ground[node] = node.global_transform
	_check(skeleton != null, target + " skeleton imported")
	if skeleton == null:
		return
	var transforms := _snapshot(visuals)
	player.play("idle_loop")
	player.advance(0.0)
	skeleton.force_update_all_bone_transforms()
	var fixed := _fixed_bones(skeleton)
	_check(fixed.size() >= 3, target + " root and two feet found")
	for clip in player.get_animation_list():
		if clip == "RESET":
			continue
		var animation := player.get_animation(clip)
		var looped: bool = clip in ["idle_loop", "talk_loop", "relieved_loop"]
		_check(animation.loop_mode == (Animation.LOOP_LINEAR if looped else Animation.LOOP_NONE), target + " loop mode " + clip)
		var stepped := true
		for track in animation.get_track_count():
			stepped = stepped and animation.track_get_interpolation_type(track) == Animation.INTERPOLATION_NEAREST
		_check(stepped, target + " authored stepped interpolation " + clip)
		player.play(clip)
		var stationary := true
		var finite := true
		var animated := false
		var first := {}
		for frame in range(int(ceil(animation.length * 24.0)) + 1):
			player.seek(minf(frame / 24.0, animation.length), true)
			skeleton.force_update_all_bone_transforms()
			stationary = stationary and transforms == _snapshot(visuals)
			for index in fixed:
				stationary = stationary and skeleton.get_bone_global_pose(index).is_equal_approx(fixed[index])
			for mesh in ground:
				stationary = stationary and mesh.global_transform.is_equal_approx(ground[mesh])
			for index in skeleton.get_bone_count():
				var pose := skeleton.get_bone_global_pose(index)
				finite = finite and pose.origin.is_finite() and pose.basis.get_scale().is_finite() and absf(pose.basis.determinant()) > 0.00001
				if frame == 0:
					first[index] = pose
				else:
					animated = animated or not pose.is_equal_approx(first[index])
		_check(stationary, target + " fixed root feet and ground props throughout " + clip)
		_check(finite and animated, target + " valid moving bone poses throughout " + clip)
	player.play("idle_loop")
	player.advance(0.0)

func _test_animation_lifecycle(target: String, scene: Node3D, npc: NPC, controller: Node, player: AnimationPlayer) -> void:
	var choices: Array = controller.get("_fidget_clips")
	var authored := choices.duplicate()
	for suffix in FIDGETS[target]:
		choices.clear()
		choices.append(StringName("fidget_" + suffix))
		controller.set("_fidget_wait", 0.0)
		controller._process(0.001)
		_check(player.current_animation == "fidget_" + suffix, target + " scheduler starts fidget " + suffix)
		_complete_clip(player)
		_check(player.current_animation == "idle_loop", target + " one-shot fidget returns to idle " + suffix)
		var wait: float = controller.get("_fidget_wait")
		_check(wait >= 4.0 and wait <= 7.0, target + " fidget delay stays within 4–7 seconds")
	choices.clear()
	choices.append_array(authored)
	controller.set("_fidget_wait", 0.0)
	controller._process(0.001)
	_check(String(player.current_animation).begins_with("fidget_"), target + " fidget active before interruption")
	npc.interact()
	_check(player.current_animation == "talk_enter", target + " conversation interrupts fidget immediately")
	_complete_clip(player)
	player.advance(0.125)
	var position := player.current_animation_position
	npc.prompt_visibility_changed.emit(false)
	_check(player.current_animation == "talk_loop" and is_equal_approx(position, player.current_animation_position), target + " repeated dialogue signal preserves playback")
	npc._hide_dialogue()
	_check(player.current_animation == "talk_exit", target + " closing conversation enters exit")
	player.advance(0.125)
	npc.interact()
	_check(player.current_animation == "talk_enter", target + " rapid reopening interrupts exit")
	npc._hide_dialogue()
	_complete_clip(player)
	_check(player.current_animation == "idle_loop", target + " interrupted entry returns through exit to idle")
	position = player.current_animation_position
	get_tree().paused = true
	for frame in range(4):
		await get_tree().process_frame
	_check(is_equal_approx(position, player.current_animation_position), target + " actual SceneTree pause freezes animation")
	get_tree().paused = false
	await get_tree().process_frame
	await get_tree().process_frame
	_check(player.current_animation_position > position, target + " unpause resumes playback")
	SceneManager.storm_transition_pending = true
	controller._process(0.001)
	_check(not player.is_playing(), target + " storm transition cancels playback")
	npc.interact()
	_check(not npc.is_showing and not player.is_playing(), target + " storm rejects new conversation")
	SceneManager.storm_transition_pending = false
	controller._process(0.001)
	_check(player.current_animation == "idle_loop", target + " clearing canceled storm restores rest")
	_check(scene.process_mode == Node.PROCESS_MODE_PAUSABLE, target + " scene fixture uses gameplay pause semantics")

func _check_modal_rest(npc: NPC, controller: Node, player: AnimationPlayer) -> void:
	if npc is QuestNPC and npc._choice_modal != null and npc._choice_modal.visible:
		controller._process(15.0)
		_check(player.current_animation == "idle_loop", "%s choice modal suppresses fidgets" % npc.get_parent().name)
		_check(is_zero_approx(controller.get("_head_look").influence), "%s choice modal releases player head tracking" % npc.get_parent().name)
	elif npc is ShopPeople and ShopUi.shop_panel != null and ShopUi.shop_panel.visible:
		controller._process(15.0)
		_check(player.current_animation == "idle_loop", "%s shopping suppresses fidgets" % npc.get_parent().name)
		_check(is_zero_approx(controller.get("_head_look").influence), "%s shopping releases player head tracking" % npc.get_parent().name)

func _test_donation(scene: Node3D, npc: NPC, controller: Node, player: AnimationPlayer) -> void:
	await _finish_dialogue(npc)
	_check_modal_rest(npc, controller, player)
	npc._decline_choice()
	controller._process(0.001)
	_check(not GameState.grocery_donation_given and player.current_animation == "idle_loop", "Beggar declined donation does not thank")
	var initial_cash := GameState.get_cash()
	GameState.cash_balance = 0
	await _finish_dialogue(npc)
	npc._accept_choice()
	controller._process(0.001)
	_check(not GameState.grocery_donation_given and player.current_animation == "idle_loop", "Beggar unaffordable donation does not thank")
	GameState.cash_balance = maxi(initial_cash, 100)
	var cash := GameState.get_cash()
	await _finish_dialogue(npc)
	npc._accept_choice()
	controller._process(0.001)
	_check(GameState.grocery_donation_given and GameState.get_cash() == cash - npc.donation_amount, "Beggar successful donation changes cash and flag")
	_check(player.current_animation == "thank_you", "Beggar successful donation starts authored thanks")
	_complete_clip(player)
	_check(player.current_animation == "relieved_loop", "Beggar thanks finishes into relieved idle")
	npc._on_choice_accepted()
	controller._process(0.001)
	_check(GameState.get_cash() == cash - npc.donation_amount and player.current_animation == "relieved_loop", "Beggar reward and thanks cannot repeat")
	controller.set("_fidget_wait", 0.0)
	controller._process(15.0)
	_check(player.current_animation == "relieved_loop", "Beggar relieved idle suppresses requesting fidgets")
	var reentry: Node3D = load("res://game/entities/%s.tscn" % TARGETS.MoneyBeggar).instantiate()
	reentry.position = Vector3(40, 0, 0)
	add_child(reentry)
	var returned := _animation_player(reentry.get_node("visuals"))
	_check(returned.current_animation == "relieved_loop", "Beggar location reentry restores relieved pose without replaying thanks")
	reentry.queue_free()
	await get_tree().process_frame
	# A fresh fixture checks donation becoming successful while conversation is still active.
	GameState.grocery_donation_given = false
	var pending: Node3D = load("res://game/entities/%s.tscn" % TARGETS.MoneyBeggar).instantiate()
	pending.position = Vector3(60, 0, 0)
	add_child(pending)
	var pending_npc: NPC = pending.get_node("Area3D")
	var pending_controller := pending.get_node("NPCAnimation")
	var pending_player := _animation_player(pending.get_node("visuals"))
	pending_npc.interact()
	pending_npc._on_choice_accepted()
	pending_controller._process(0.001)
	_check(pending_player.current_animation == "talk_enter", "Beggar conversation takes priority over pending donation reaction")
	_complete_clip(pending_player)
	pending_npc._hide_dialogue()
	_complete_clip(pending_player)
	_check(pending_player.current_animation == "thank_you", "Beggar pending thanks starts after conversation exit")
	pending_npc.interact()
	_check(pending_player.current_animation == "talk_enter", "Beggar conversation immediately interrupts reaction")
	pending_npc._hide_dialogue()
	_complete_clip(pending_player)
	_check(pending_player.current_animation == "relieved_loop", "Beggar interrupted thanks is consumed once and returns to relieved idle")
	pending.queue_free()
	await get_tree().process_frame
	controller._process(0.001)
	_check(scene.get_node("visuals").get_child(0).position.y > 0.05, "Beggar seated grounding correction retained")

func _physics_frames() -> void:
	for step in range(5):
		await get_tree().physics_frame

func _bone_poses(skeleton: Skeleton3D) -> Dictionary:
	var poses := {}
	for index in skeleton.get_bone_count():
		poses[index] = skeleton.get_bone_global_pose(index)
	return poses

func _settle_head(controller: Node) -> void:
	# Advance the controller deterministically; inspect modifiers only after Skeleton3D runs.
	for step in range(8):
		controller._process(0.05)
	await get_tree().process_frame
	await get_tree().process_frame

func _test_head_tracking(target: String, scene: Node3D, npc: NPC, controller: Node, player: AnimationPlayer, fixture: PlayerFixture) -> void:
	var look := controller.get("_head_look") as LookAtModifier3D
	var skeleton := controller.get("_skeleton") as Skeleton3D
	_check(look != null and skeleton != null, target + " native head modifier initialized")
	if look == null or skeleton == null:
		return
	_check(look.get_parent() == skeleton and look.bone_name == "Head", target + " tracking modifies Head only")
	_check(not look.relative and look.use_angle_limitation and look.symmetry_limitation, target + " head limits use absolute symmetric rest angles")
	_check(is_equal_approx(look.primary_limit_angle, deg_to_rad(110.0)) and is_equal_approx(look.secondary_limit_angle, deg_to_rad(40.0)), target + " native symmetric ranges enforce yaw±55 pitch±20")
	var old_position := fixture.global_position
	var old_layer := fixture.collision_layer
	var old_mode := player.callback_mode_process
	# Keep angular probes independent of Area3D exit; physical dialogue exit is tested below.
	npc.player_exited.disconnect(npc._on_player_left)
	fixture.collision_layer = 0
	await _physics_frames()
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	npc.interact()
	_complete_clip(player)
	player.advance(0.25)
	skeleton.force_update_all_bone_transforms()
	var authored := _bone_poses(skeleton)
	var final_poses := {}
	var recorder := func() -> void:
		final_poses.clear()
		final_poses.merge(_bone_poses(skeleton))
	look.modification_processed.connect(recorder)
	var axes := [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.BACK, Vector3.FORWARD]
	var forward: Vector3 = axes[look.forward_axis]
	var up: Vector3 = [Vector3.RIGHT, Vector3.UP, Vector3.BACK][look.primary_rotation_axis]
	var right := up.cross(forward).normalized()
	var rest := skeleton.get_bone_global_rest(look.bone)
	var head_origin := skeleton.global_transform * (authored[look.bone] as Transform3D).origin
	var rest_world := skeleton.global_basis.orthonormalized() * rest.basis.orthonormalized()
	var target_directions := {
		"left": Vector3(-4.0, 0.0, 1.0),
		"right": Vector3(4.0, 0.0, 1.0),
		"high": Vector3(0.0, 4.0, 1.0),
		"low": Vector3(0.0, -4.0, 1.0),
	}
	for direction in target_directions:
		var offset: Vector3 = target_directions[direction]
		var desired := head_origin + rest_world * (right * offset.x + up * offset.y + forward * offset.z)
		fixture.global_position = desired - Vector3.UP * 1.85
		await _settle_head(controller)
		_check(look.influence >= 0.999, target + " dialogue head tracking reaches full influence " + direction)
		_check(not final_poses.is_empty(), target + " final rendered head pose sampled " + direction)
		if final_poses.is_empty():
			continue
		var pose: Transform3D = final_poses[look.bone]
		var parent_pose: Transform3D = final_poses[skeleton.get_bone_parent(look.bone)]
		var reference := parent_pose.basis.orthonormalized() * skeleton.get_bone_rest(look.bone).basis.orthonormalized()
		var facing := reference.inverse() * pose.basis.orthonormalized() * forward
		var yaw := atan2(facing.dot(right), facing.dot(forward))
		var pitch := asin(clampf(facing.dot(up), -1.0, 1.0))
		_check(absf(yaw) <= deg_to_rad(55.01) and absf(pitch) <= deg_to_rad(20.01), target + " actual rendered head obeys yaw/pitch clamp " + direction)
		var turned := signf(yaw) == signf(offset.x) and absf(yaw) > deg_to_rad(35.0) if offset.x != 0.0 else signf(pitch) == signf(offset.y) and absf(pitch) > deg_to_rad(10.0)
		_check(turned, target + " visible head turns toward player " + direction)
		var unchanged := true
		for index in authored:
			if index != look.bone:
				unchanged = unchanged and (final_poses[index] as Transform3D).is_equal_approx(authored[index])
		_check(unchanged, target + " arms props torso feet unaffected by tracking " + direction)
	# Pause must preserve both the imported animation and the final head modifier result.
	var paused_influence := look.influence
	var paused_poses := final_poses.duplicate()
	get_tree().paused = true
	fixture.global_position = head_origin + rest_world * (forward - right * 4.0) - Vector3.UP * 1.85
	for frame in range(4):
		await get_tree().process_frame
	_check(is_equal_approx(look.influence, paused_influence) and final_poses == paused_poses, target + " SceneTree pause freezes head tracking")
	get_tree().paused = false
	# A target behind the NPC must release the modifier, not turn through the back.
	fixture.global_position = head_origin - rest_world * forward * 2.0 - Vector3.UP * 1.85
	controller._process(0.05)
	_check(look.influence > 0.0 and look.influence < 1.0, target + " rear target eases back toward authored head")
	await _settle_head(controller)
	_check(is_zero_approx(look.influence), target + " rear target disables backward head tracking")
	fixture.global_position = head_origin + rest_world * (forward + right) - Vector3.UP * 1.85
	controller._process(0.05)
	_check(look.influence > 0.0 and look.influence < 1.0, target + " tracking reenters with eased influence")
	await _settle_head(controller)
	npc._hide_dialogue()
	controller._process(0.05)
	_check(look.influence > 0.0 and look.influence < 1.0, target + " ending dialogue eases authored head restoration")
	var exiting_influence := look.influence
	npc.interact()
	controller._process(0.025)
	_check(look.influence > exiting_influence and player.current_animation == "talk_enter", target + " rapid reopening interrupts head return promptly")
	npc._hide_dialogue()
	await _settle_head(controller)
	_check(is_zero_approx(look.influence), target + " ending dialogue restores authored head motion")
	_complete_clip(player)
	npc.interact()
	await _settle_head(controller)
	SceneManager.storm_transition_pending = true
	controller._process(0.001)
	_check(is_zero_approx(look.influence) and not player.is_playing(), target + " storm cancels head tracking and animation")
	npc._hide_dialogue()
	SceneManager.storm_transition_pending = false
	controller._process(0.001)
	look.modification_processed.disconnect(recorder)
	player.callback_mode_process = old_mode
	fixture.global_position = old_position
	fixture.collision_layer = old_layer
	await _physics_frames()
	npc.player_exited.connect(npc._on_player_left)

func _test_npc(target: String) -> void:
	if target == "MoneyBeggar":
		GameState.grocery_donation_given = false
	var scene: Node3D = load("res://game/entities/%s.tscn" % TARGETS[target]).instantiate()
	scene.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(scene)
	var npc = scene.get_node("Area3D")
	_check(npc != null and npc.get_node("%CanvasLayer") != null, target + " gameplay and unique UI remain")
	var visuals := scene.get_node_or_null("visuals")
	_check(visuals != null, target + " visual wrapper exists")
	if visuals == null:
		scene.queue_free()
		await get_tree().process_frame
		return
	var meshes := 0
	var skinned := 0
	for node in _nodes(visuals):
		_check(not node is AnimationTree, target + " direct animation playback " + node.name)
		if node is MeshInstance3D:
			meshes += 1
			_check(node.mesh != null, target + " mesh " + node.name)
			if node.skin != null:
				skinned += 1
				var valid_binds: bool = node.skin.get_bind_count() > 0
				for bind in node.skin.get_bind_count():
					var bind_pose: Transform3D = node.skin.get_bind_pose(bind)
					valid_binds = valid_binds and bind_pose.origin.is_finite() and bind_pose.basis.get_scale().is_finite() and absf(bind_pose.basis.determinant()) > 0.00001
				_check(valid_binds, target + " exportable finite skin binds " + node.name)
			for surface in range(node.mesh.get_surface_count()):
				if node.skin != null:
					var arrays: Array = node.mesh.surface_get_arrays(surface)
					var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
					var vertex_count: int = arrays[Mesh.ARRAY_VERTEX].size()
					var normalized := weights.size() > 0 and vertex_count > 0
					var stride: int = weights.size() / maxi(vertex_count, 1)
					for vertex in vertex_count:
						var total := 0.0
						for influence in stride:
							var weight := weights[vertex * stride + influence]
							normalized = normalized and is_finite(weight) and weight >= 0.0
							total += weight
						normalized = normalized and absf(total - 1.0) < 0.0001
					_check(normalized, target + " normalized skin weights " + node.name)
				var material := node.get_active_material(surface) as BaseMaterial3D
				if material != null and material.albedo_texture != null:
					_check(material.texture_filter in [BaseMaterial3D.TEXTURE_FILTER_NEAREST, BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS], target + " nearest texture sampling")
	_check(meshes > 0, target + " visible geometry present")
	_check(skinned > 0, target + " skinned body present")
	var player := _animation_player(visuals)
	var controller := scene.get_node_or_null("NPCAnimation")
	_check(player != null and controller != null, target + " animation player and scene-owned controller present")
	if player == null or controller == null:
		scene.queue_free()
		await get_tree().process_frame
		return
	var expected := ["idle_loop", "talk_enter", "talk_loop", "talk_exit"]
	for fidget in FIDGETS[target]:
		expected.append("fidget_" + fidget)
	if target == "MoneyBeggar":
		expected.append_array(["thank_you", "relieved_loop"])
	for clip in expected:
		_check(player.has_animation(clip), target + " authored clip " + clip)
	_check(player.current_animation == "idle_loop", target + " idle initialized before first rendered frame")
	var position := player.current_animation_position
	player.advance(0.125)
	_check(player.current_animation_position > position, target + " idle playback advances")
	_sample_clips(target, visuals, player)
	await _test_animation_lifecycle(target, scene, npc, controller, player)
	var fixture := PlayerFixture.new()
	fixture.add_to_group("player")
	var collider := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.1
	collider.shape = shape
	fixture.add_child(collider)
	fixture.position = Vector3(20, 20, 20)
	add_child(fixture)
	await _physics_frames()
	fixture.global_position = npc.get_node("CollisionShape3D").global_position
	await _physics_frames()
	_check(fixture.detected == npc and not fixture.prompt.is_empty(), target + " physics entry detects NPC and prompt")
	await _test_head_tracking(target, scene, npc, controller, player, fixture)
	if target == "MangNestor":
		InventoryManager.reset()
		SideQuestLog.reset()
		var initial_cash := GameState.get_cash()
		await _finish_dialogue(npc)
		npc._accept_choice()
		_check(GameState.get_cash() == initial_cash + npc.quest_cash_amount, "Nestor gives quest cash")
		var cash := GameState.get_cash()
		npc._start_quest()
		_check(GameState.get_cash() == cash, "Nestor start reward once")
		var chicken := ItemData.new()
		chicken.item_id = "half_chicken"
		InventoryManager.add_item(chicken)
		for index in range(6):
			var filler := ItemData.new()
			filler.item_id = "static_fixture_%d" % index
			InventoryManager.add_item(filler)
		await _finish_dialogue(npc)
		var before_turn_in := GameState.get_cash()
		npc._accept_choice()
		_check(InventoryManager.get_total_quantity("tarp") == 1 and not InventoryManager.has_item_with_id("half_chicken"), "Nestor chicken exchanged for tarp")
		_check(GameState.get_cash() == before_turn_in + npc.sukli_amount, "Nestor gives sukli")
		npc._complete_quest()
		_check(InventoryManager.get_total_quantity("tarp") == 1, "Nestor reward cannot duplicate")
	elif target == "MoneyBeggar":
		await _test_donation(scene, npc, controller, player)
	elif target == "SmokeBreakNPC":
		GameState.tindahan_smoke_break_taken = false
		var minutes := GlobalTimer.current_minutes
		await _finish_dialogue(npc)
		npc._accept_choice()
		var deadline := Time.get_ticks_msec() + 10000
		while npc._pending_smoke and Time.get_ticks_msec() < deadline:
			await get_tree().process_frame
		_check(not npc._pending_smoke and not fixture.locked, "Smoke action completes and releases player")
		npc._on_choice_accepted()
		_check(GameState.tindahan_smoke_break_taken and GlobalTimer.current_minutes == minutes + npc.time_cost_minutes, "Smoke costs 20 minutes once")
	elif target == "PharmaDude":
		await _finish_dialogue(npc)
		_check(ShopUi._current_shop != null and npc.shop_path == "res://game/resources/shops/PharmacyShop.tres", "Pharma dialogue opens pharmacy shop")
		ShopUi.close_shop(true)
		_check(not ShopUi.shop_panel.visible, "Pharmacy shop closes")
	else:
		await _finish_dialogue(npc)
	var root_transform := scene.transform
	var visual_transform: Transform3D = visuals.get_child(0).transform
	npc.interact()
	_check(player.current_animation == "talk_enter", target + " conversation responsive on reentry")
	fixture.global_position = Vector3(20, 20, 20)
	await _physics_frames()
	_check(fixture.detected == null and fixture.prompt.is_empty(), target + " physics exit removes prompt")
	_check(not npc.is_showing and player.current_animation == "talk_exit", target + " physics exit interrupts conversation")
	_complete_clip(player)
	_check(scene.transform == root_transform and visuals.get_child(0).transform == visual_transform, target + " interaction preserves root visual scale and facing")
	controller.set("_fidget_wait", 0.0)
	controller._process(0.001)
	var weak: WeakRef = weakref(controller)
	fixture.queue_free()
	scene.queue_free()
	await get_tree().process_frame
	_check(weak.get_ref() == null, target + " removal during active playback frees controller")

func _capture_locations() -> void:
	var directory := OS.get_environment("STATIC_NPC_CAPTURE_DIR")
	if directory.is_empty():
		_check(false, "STATIC_NPC_CAPTURE_DIR required")
		return
	DirAccess.make_dir_recursive_absolute(directory)
	GameState.grocery_donation_given = false
	# Review illumination and hidden overlays affect only this disposable capture fixture.
	VhsCrtOverlay.visible = false
	get_window().content_scale_size = Vector2i(960, 720)
	for location in LOCATIONS:
		var scene: Node3D = load("res://game/scenes/locations/%s.tscn" % location).instantiate()
		add_child(scene)
		await get_tree().process_frame
		await _physics_frames()
		for node in _nodes(scene):
			if node is CanvasLayer:
				node.visible = false
		var camera := Camera3D.new()
		scene.add_child(camera)
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.make_current()
		var light := DirectionalLight3D.new()
		camera.add_child(light)
		light.light_energy = 1.0
		for target in LOCATIONS[location]:
			var npc := scene.get_node(target) as Node3D
			var controller := npc.get_node("NPCAnimation")
			controller.set_process(false)
			var player := _animation_player(npc.get_node("visuals"))
			player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
			var height: float = HEIGHTS[target]
			var floor_offset := -0.3448443 if target == "PharmaDude" else 0.0
			var center := npc.global_position + Vector3.UP * (height * 0.52 + floor_offset)
			camera.size = maxf(height * 1.35, 2.1)
			var views := {
				"front": npc.global_basis.z.normalized() * (1.1 if target == "PanicBuyer" else 1.25) + Vector3.UP * 0.12,
				"side": npc.global_basis.x.normalized() * 1.25 + Vector3.UP * 0.12,
				"elevated": npc.global_basis.z.normalized() * 1.5 + Vector3.UP * 0.95,
			}
			for clip in player.get_animation_list():
				if clip == "RESET":
					continue
				player.play(clip)
				player.seek(player.get_animation(clip).length * 0.5, true)
				for view in views:
					camera.global_position = center + views[view]
					camera.look_at(center)
					await _capture_image(directory.path_join(target + "_" + clip + "_" + view + ".png"))
		scene.queue_free()
		await get_tree().process_frame

func _capture_image(path: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var result := get_viewport().get_texture().get_image().save_png(path)
	_check(result == OK, "capture " + path.get_file())
