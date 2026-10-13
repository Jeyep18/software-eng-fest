extends Node
## Run in an imported disposable project with isolated APPDATA/LOCALAPPDATA.

const CLIPS := {
	0: {"idle_loop": 3.0, "walk_loop": 19.0 / 24.0, "sit_enter": 1.0, "sit_loop": 4.0, "sit_exit": 1.0},
	1: {"idle_loop": 2.5, "wag_loop": 2.5, "walk_loop": 20.0 / 24.0, "run_loop": 13.0 / 24.0,
		"sit_enter": 1.25, "sit_loop": 1.25, "sit_exit": 1.25,
		"lie_enter": 1.25, "lie_loop": 1.25, "lie_exit": 1.25, "sniff": 2.0},
}
var _checks := 0
var _failures := 0
var _fixture: Node3D

func _run() -> void:
	if OS.get_environment("BAGYONG_ISOLATED_SMOKE") != OS.get_user_data_dir():
		push_error("Ambient regression requires explicitly isolated user data.")
		get_tree().quit(1)
		return
	get_tree().current_scene = null
	TutorialModal.mark_do_not_show_again()
	SceneManager.reset()
	GlobalTimer.start_fresh()
	GlobalTimer.pause_timer(self)
	_fixture = Node3D.new()
	_fixture.position = Vector3(100, 0, 100)
	_fixture.add_to_group("player")
	add_child(_fixture)
	for species in [AmbientAnimal.Species.CAT, AmbientAnimal.Species.DOG]:
		await _test_species(species)
	_fixture.queue_free()
	await get_tree().process_frame
	for location in ["grocery", "tindahan"]:
		await _test_location(location)
	await _test_lifecycle()
	print("Ambient animal regression: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()

func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("AMBIENT FAIL: " + description)

func _nodes(node: Node) -> Array[Node]:
	var result: Array[Node] = [node]
	for child in node.get_children():
		result.append_array(_nodes(child))
	return result

func _animation_player(animal: Node) -> AnimationPlayer:
	for node in _nodes(animal):
		if node is AnimationPlayer:
			return node
	return null

func _skeleton(animal: Node) -> Skeleton3D:
	for node in _nodes(animal):
		if node is Skeleton3D:
			return node
	return null

func _bone_poses(skeleton: Skeleton3D) -> Array[Transform3D]:
	skeleton.force_update_all_bone_transforms()
	var result: Array[Transform3D] = []
	for bone in skeleton.get_bone_count():
		result.append(skeleton.get_bone_global_pose(bone))
	return result

func _pose_error(first: Array[Transform3D], last: Array[Transform3D]) -> float:
	var error := 0.0
	for index in first.size():
		error = maxf(error, first[index].origin.distance_to(last[index].origin))
		for axis in 3:
			error = maxf(error, first[index].basis[axis].distance_to(last[index].basis[axis]))
	return error

func _test_geometry(animal: Node3D, label: String) -> void:
	var skin_count := 0
	for node in _nodes(animal):
		_check(not node is CollisionObject3D and not node is CollisionShape3D, label + " has no blocking/interaction physics: " + node.name)
		_check(not node.is_in_group("player") and not node.is_in_group("interactables"), label + " is decorative: " + node.name)
		if not node is MeshInstance3D:
			continue
		var mesh := node as MeshInstance3D
		_check(mesh.mesh != null, label + " imported mesh exists")
		if mesh.skin == null or mesh.mesh == null:
			continue
		skin_count += 1
		var valid := mesh.skin.get_bind_count() > 0
		for bind in mesh.skin.get_bind_count():
			var pose := mesh.skin.get_bind_pose(bind)
			valid = valid and pose.origin.is_finite() and pose.basis.get_scale().is_finite() and absf(pose.basis.determinant()) > 0.00000001
		_check(valid, label + " finite invertible skin binds")
		for surface in mesh.mesh.get_surface_count():
			var arrays := mesh.mesh.surface_get_arrays(surface)
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var stride := weights.size() / maxi(vertices.size(), 1)
			valid = vertices.size() > 0 and stride == 8
			for vertex in vertices.size():
				var total := 0.0
				valid = valid and vertices[vertex].is_finite()
				for influence in stride:
					var weight := weights[vertex * stride + influence]
					valid = valid and is_finite(weight) and weight >= 0.0
					total += weight
				valid = valid and absf(total - 1.0) < 0.0001
			_check(valid, label + " all skin influences retained and normalized")
	_check(skin_count == 1, label + " has one shared skinned body")

func _test_clips(animal: Node3D, label: String) -> void:
	var player := _animation_player(animal)
	var skeleton := _skeleton(animal)
	_check(player != null and skeleton != null, label + " imported animation player and skeleton")
	if player == null or skeleton == null:
		return
	var expected: Dictionary = CLIPS[animal.get("species")]
	_check(skeleton.get_bone_count() == (17 if animal.species == AmbientAnimal.Species.CAT else 38), label + " original rig bone count retained")
	var actual: Array[String] = []
	for clip in player.get_animation_list():
		if clip != "RESET":
			actual.append(String(clip))
	_check(actual.size() == expected.size(), label + " exact animation count")
	var mode := player.callback_mode_process
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for clip: String in expected:
		_check(player.has_animation(clip), label + " includes " + clip)
		if not player.has_animation(clip):
			continue
		var animation := player.get_animation(clip)
		var looped := clip.ends_with("_loop")
		_check(animation.loop_mode == (Animation.LOOP_LINEAR if looped else Animation.LOOP_NONE), label + " explicit loop mode " + clip)
		_check(absf(animation.length - float(expected[clip])) < 0.001, label + " full 24fps duration " + clip)
		player.play(clip, 0.0)
		player.seek(0.0, true)
		var first := _bone_poses(skeleton)
		var finite := true
		var moving := false
		for frame in range(int(ceil(animation.length * 24.0)) + 1):
			player.seek(minf(frame / 24.0, animation.length - 0.00001), true)
			var poses := _bone_poses(skeleton)
			moving = moving or _pose_error(first, poses) > 0.00001
			for pose in poses:
				finite = finite and pose.origin.is_finite() and pose.basis.get_scale().is_finite() and absf(pose.basis.determinant()) > 0.00000001
		_check(finite and moving, label + " finite animated bone deformation " + clip)
		if looped:
			_check(_pose_error(first, _bone_poses(skeleton)) < 0.0025, label + " closed loop seam " + clip)
	var transitions := [["sit_enter", true, "sit_loop", false], ["sit_loop", false, "sit_exit", false],
		["sit_exit", true, "idle_loop", false], ["idle_loop", false, "sit_enter", false]]
	if animal.species == AmbientAnimal.Species.DOG:
		transitions.append_array([["lie_enter", true, "lie_loop", false], ["lie_loop", false, "lie_exit", false],
			["lie_exit", true, "idle_loop", false], ["idle_loop", false, "lie_enter", false],
			["idle_loop", false, "sniff", false], ["sniff", true, "idle_loop", false]])
	for transition: Array in transitions:
		var first := _clip_pose(player, skeleton, transition[0], transition[1])
		var last := _clip_pose(player, skeleton, transition[2], transition[3])
		_check(_pose_error(first, last) < 0.0025, label + " matching transition " + transition[0] + " → " + transition[2])
	player.callback_mode_process = mode

func _clip_pose(player: AnimationPlayer, skeleton: Skeleton3D, clip: String, at_end: bool) -> Array[Transform3D]:
	player.play(clip, 0.0)
	player.seek(player.get_animation(clip).length - 0.00001 if at_end else 0.0, true)
	return _bone_poses(skeleton)

func _test_species(species: int) -> void:
	var label := "cat" if species == AmbientAnimal.Species.CAT else "dog"
	var packed: PackedScene = load("res://game/entities/animals/ambient_%s.tscn" % label)
	seed(91825)
	var expected_random := randi()
	seed(91825)
	var animal := packed.instantiate() as AmbientAnimal
	animal.waypoints = PackedVector3Array([Vector3.ZERO, Vector3(2, 0, 0), Vector3(4, 0, 0)])
	animal.allow_running = species == AmbientAnimal.Species.DOG
	add_child(animal)
	_check(randi() == expected_random, label + " initialization preserves gameplay RNG")
	animal.set_physics_process(false)
	animal._animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	_check(animal.species == species and animal.process_mode == Node.PROCESS_MODE_PAUSABLE, label + " production species and pause mode")
	_test_geometry(animal, label)
	_test_clips(animal, label)
	var coat := animal._mesh_instances[0].material_override as StandardMaterial3D
	_check(animal.material_variants.size() == 3 and coat != null and coat.albedo_texture != null, label + " three textured coat choices")
	var textures := {}
	for material: StandardMaterial3D in animal.material_variants:
		textures[material.albedo_texture] = true
		_check(material.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST, label + " nearest PSX coat sampling")
	_check(textures.size() == 3 and textures.has(coat.albedo_texture), label + " selected coat belongs to three distinct atlases")
	var twin := packed.instantiate() as AmbientAnimal
	add_child(twin)
	twin.set_physics_process(false)
	_check(animal._mesh_instances[0].mesh == twin._mesh_instances[0].mesh, label + " body geometry shared between instances")
	var other_coat := twin._mesh_instances[0].material_override as StandardMaterial3D
	_check(other_coat != coat, label + " instances own independent material overrides")
	coat.albedo_color = Color(0.5, 0.5, 0.5)
	_check(other_coat.albedo_color == Color.WHITE, label + " one coat mutation cannot change another animal")
	coat.albedo_color = Color.WHITE
	twin.queue_free()
	await get_tree().process_frame
	animal._clip = &""
	animal._begin_idle(2.0)
	_test_proximity(animal, label)
	_test_rest_transitions(animal, label)
	seed(13741)
	expected_random = randi()
	seed(13741)
	animal._rng.seed = 42
	animal._begin_idle(0.0)
	var stayed_on_route := true
	var matched_gait := true
	var smooth_turns := true
	var visited: Dictionary = {0: true}
	var saw_run := false
	for step in 2000:
		var before := animal.position
		var yaw := animal.rotation.y
		var speed := animal.run_speed if animal._running else animal.walk_speed
		animal._physics_process(0.05)
		animal._animation_player.advance(0.05)
		stayed_on_route = stayed_on_route and _on_route(animal.position, animal.waypoints)
		matched_gait = matched_gait and animal.position.distance_to(before) <= speed * 0.05 + 0.0001
		smooth_turns = smooth_turns and absf(angle_difference(yaw, animal.rotation.y)) <= 0.1501
		saw_run = saw_run or animal._clip == &"run_loop"
		for index in animal.waypoints.size():
			if animal.position.distance_to(animal.waypoints[index]) < 0.01:
				visited[index] = true
	_check(randi() == expected_random, label + " rest, gait and timing preserve gameplay RNG")
	_check(stayed_on_route and visited.size() == animal.waypoints.size(), label + " repeated real controller movement stays on every authored leg")
	_check(matched_gait and smooth_turns, label + " bounded gait speed and gradual turns throughout route")
	_check(animal._mesh_instances[0].material_override == coat, label + " coat stable across movement and rest cycles")
	_check(saw_run if species == AmbientAnimal.Species.DOG else not saw_run, label + " running allowed only for designated dog")
	await _test_pause(animal, label)
	var weak: WeakRef = weakref(animal)
	animal.queue_free()
	await get_tree().process_frame
	_check(weak.get_ref() == null, label + " active controller and model freed together")

func _test_proximity(animal: AmbientAnimal, label: String) -> void:
	animal._begin_walk()
	animal.rotation.y = -PI * 0.5
	_fixture.global_position = animal.global_position
	var before := animal.transform
	animal._physics_process(0.2)
	_check(animal.transform == before and animal._player_blocked and animal._clip == &"idle_loop", label + " nearby player stops movement and gait")
	_fixture.global_position = Vector3(100, 0, 100)
	animal._physics_process(0.2)
	_check(animal.position != before.origin and not animal._player_blocked and animal._clip in [&"walk_loop", &"run_loop"], label + " player leaving resumes current leg")

func _finish_clip(animal: AmbientAnimal) -> void:
	var player := animal._animation_player
	player.advance(player.get_animation(animal._clip).length + 0.05)

func _select_rest(animal: AmbientAnimal, requested: StringName) -> bool:
	for value in range(1, 300):
		animal._rng.seed = value
		animal._clip = &""
		animal._choose_rest()
		if animal._clip == requested:
			return true
	return false

func _test_rest_transitions(animal: AmbientAnimal, label: String) -> void:
	_check(_select_rest(animal, &"sit_enter"), label + " weighted rest can choose sitting")
	_finish_clip(animal)
	_check(animal._state == AmbientAnimal.State.SIT and animal._clip == &"sit_loop" and animal._wait >= 10.0 and animal._wait <= 18.0, label + " sit entry finishes into timed loop")
	animal._wait = 0.0
	animal._physics_process(0.01)
	_check(animal._clip == &"sit_exit", label + " sit timeout plays standing transition")
	_finish_clip(animal)
	_check(animal._state == AmbientAnimal.State.IDLE, label + " sit exit returns to standing pause")
	if animal.species != AmbientAnimal.Species.DOG:
		return
	_check(_select_rest(animal, &"sniff"), label + " weighted rest can choose sniff")
	_finish_clip(animal)
	_check(animal._state == AmbientAnimal.State.IDLE and animal._clip in [&"idle_loop", &"wag_loop"], label + " sniff finishes into standing pause")
	_check(_select_rest(animal, &"lie_enter"), label + " weighted rest can choose lying")
	_finish_clip(animal)
	_check(animal._state == AmbientAnimal.State.LIE and animal._clip == &"lie_loop" and animal._wait >= 8.0 and animal._wait <= 14.0, label + " lie entry finishes into timed loop")
	animal._wait = 0.0
	animal._physics_process(0.01)
	_check(animal._clip == &"lie_exit", label + " lying timeout plays standing transition")
	_finish_clip(animal)
	_check(animal._state == AmbientAnimal.State.IDLE, label + " lie exit returns to standing pause")

func _test_pause(animal: AmbientAnimal, label: String) -> void:
	animal._begin_walk()
	animal.set_physics_process(true)
	animal._animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	for frame in 4:
		await get_tree().physics_frame
	var before := animal.transform
	var clip_position := animal._animation_player.current_animation_position
	get_tree().paused = true
	for frame in 6:
		await get_tree().process_frame
	_check(animal.transform == before and is_equal_approx(clip_position, animal._animation_player.current_animation_position), label + " actual SceneTree pause freezes transform and animation time")
	get_tree().paused = false
	for frame in 4:
		await get_tree().physics_frame
	_check(not is_equal_approx(clip_position, animal._animation_player.current_animation_position), label + " actual unpause resumes animation")
	animal.set_physics_process(false)
	animal._animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL

func _test_location(location: String) -> void:
	var scene: Node3D = load("res://game/scenes/locations/%s.tscn" % location).instantiate()
	var root := scene.get_node_or_null("AmbientAnimals") as Node3D
	var authored_positions: Dictionary = {}
	var authored_routes: Dictionary = {}
	if root != null:
		for animal: AmbientAnimal in root.get_children():
			authored_positions[animal.name] = animal.position
			authored_routes[animal.name] = animal.waypoints.duplicate()
	add_child(scene)
	_check(root != null, location + " has scene-owned AmbientAnimals root")
	if root == null:
		scene.queue_free()
		await get_tree().process_frame
		return
	var expected := 3 if location == "grocery" else 2
	_check(root.get_child_count() == expected, location + " exact decorative animal count")
	_check(root.transform == Transform3D.IDENTITY, location + " route parent uses world-aligned coordinates")
	var cats := 0
	var dogs := 0
	var weak_animals: Array[WeakRef] = []
	var far_player := Node3D.new()
	scene.add_child(far_player)
	far_player.position = Vector3(100, 0, 100)
	for animal: AmbientAnimal in root.get_children():
		var label := location + " " + animal.name
		weak_animals.append(weakref(animal))
		cats += 1 if animal.species == AmbientAnimal.Species.CAT else 0
		dogs += 1 if animal.species == AmbientAnimal.Species.DOG else 0
		animal.set_physics_process(false)
		animal._animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		animal._player = far_player
		_check(animal.get_parent() == root, label + " lifecycle owned by location")
		if animal.waypoints.size() < 2:
			var before := animal.transform
			var saw_standing := false
			var saw_sitting := false
			for frame in 1000:
				animal._physics_process(0.1)
				animal._animation_player.advance(0.1)
				saw_standing = saw_standing or animal._state == AmbientAnimal.State.IDLE
				saw_sitting = saw_sitting or animal._state == AmbientAnimal.State.SIT
			_check(animal.transform == before and saw_standing and saw_sitting, label + " seated/standing rest cycles preserve stationed position and facing")
		else:
			_check(animal.position.is_equal_approx(authored_positions[animal.name]), label + " starts at saved editor position")
			var original_route: PackedVector3Array = authored_routes[animal.name]
			var same_route := true
			for index in animal.waypoints.size():
				same_route = same_route and (animal.waypoints[index] - animal.waypoints[0]).is_equal_approx(original_route[index] - original_route[0])
			_check(same_route, label + " relocation preserves route distances and directions")
			_check(animal.position.is_equal_approx(animal.waypoints[0]), label + " starts at first authored endpoint")
			_check(animal.waypoints.size() == (3 if location == "grocery" and animal.species == AmbientAnimal.Species.DOG else 2), label + " exact waypoint count")
			_check(animal.allow_running == (location == "grocery" and animal.species == AmbientAnimal.Species.DOG), label + " running limited to covered palengke dog")
			animal._rng.seed = 42
			animal._begin_idle(0.0)
			var bounded := true
			var visited: Dictionary = {0: true}
			for frame in 2000:
				animal._physics_process(0.05)
				animal._animation_player.advance(0.05)
				bounded = bounded and _on_route(animal.position, animal.waypoints)
				for index in animal.waypoints.size():
					if animal.position.distance_to(animal.waypoints[index]) < 0.01:
						visited[index] = true
			_check(bounded and visited.size() == animal.waypoints.size(), label + " actual location route traverses every endpoint and stays inside its authored segments")
			if location == "tindahan":
				var no_running := true
				for trial in 200:
					animal._begin_walk()
					no_running = no_running and not animal._running
				_check(no_running, label + " repeated random gait choices never run")
	_check(cats == (2 if location == "grocery" else 1) and dogs == 1, location + " fixed cat/dog species distribution")
	scene.queue_free()
	await get_tree().process_frame
	var freed := true
	for weak in weak_animals:
		freed = freed and weak.get_ref() == null
	_check(freed, location + " entire animal population freed with location")
	_check(_animal_storm_connections() == 0, location + " leaves no animal storm signal callbacks")

func _animal_storm_connections() -> int:
	var count := 0
	for connection: Dictionary in GlobalTimer.get_signal_connection_list("storm_arrived"):
		var callback: Callable = connection["callable"]
		if callback.get_object() is AmbientAnimal:
			count += 1
	return count

func _scene_is(location: String) -> bool:
	var current := get_tree().current_scene
	return current != null and current.scene_file_path == SceneManager.SCENE_PATHS[location]

func _test_lifecycle() -> void:
	SceneManager.reset()
	StormEnroachment.reset()
	SceneManager.travel_to("grocery", "", 0)
	if not await _wait_until(func(): return _scene_is("grocery") and not SceneManager.is_travelling, "real travel loads palengke"):
		return
	var old_animals: Array[WeakRef] = []
	for animal in get_tree().current_scene.get_node("AmbientAnimals").get_children():
		old_animals.append(weakref(animal))
	_check(_animal_storm_connections() == 3, "palengke subscribes exactly three scene-owned animal storm callbacks")
	SceneManager.travel_to("tindahan", "", 0)
	if not await _wait_until(func(): return _scene_is("tindahan") and not SceneManager.is_travelling, "real travel loads tindahan"):
		return
	var freed := true
	for weak in old_animals:
		freed = freed and weak.get_ref() == null
	_check(freed and _animal_storm_connections() == 2, "travel frees old models/controllers/callbacks and creates only two destination animals")
	var animals := get_tree().current_scene.get_node("AmbientAnimals").get_children()
	old_animals.clear()
	for animal: AmbientAnimal in animals:
		old_animals.append(weakref(animal))
		animal._begin_walk()
	GlobalTimer.force_storm_arrival()
	var stopped := true
	for animal: AmbientAnimal in animals:
		stopped = stopped and animal._storm_suspended and not animal.is_physics_processing() and not animal._animation_player.is_playing()
		var before := animal.transform
		var clip_position := animal._animation_player.current_animation_position
		animal._physics_process(5.0)
		animal._begin_walk()
		animal._on_animation_finished(animal._clip)
		stopped = stopped and animal.transform == before and is_equal_approx(clip_position, animal._animation_player.current_animation_position)
	_check(stopped, "actual storm signal immediately stops every root/clip and rejects late animation callbacks")
	if not await _wait_until(func(): return _scene_is("ending"), "storm transition reaches actual ending"):
		return
	freed = true
	for weak in old_animals:
		freed = freed and weak.get_ref() == null
	_check(freed and _animal_storm_connections() == 0, "storm scene replacement frees every animal and callback")
	var no_animals := true
	for node in _nodes(get_tree().current_scene):
		no_animals = no_animals and not node is AmbientAnimal
	_check(no_animals, "ending scene contains no ambient animals")
	get_tree().current_scene.queue_free()
	get_tree().current_scene = null
	await get_tree().process_frame

func _on_route(point: Vector3, waypoints: PackedVector3Array) -> bool:
	for index in range(waypoints.size() - 1):
		if Geometry3D.get_closest_point_to_segment(point, waypoints[index], waypoints[index + 1]).distance_to(point) < 0.0001:
			return true
	return false

func _wait_until(predicate: Callable, label: String) -> bool:
	var deadline := Time.get_ticks_msec() + 10000
	while not predicate.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	var succeeded: bool = predicate.call()
	_check(succeeded, label)
	return succeeded
