extends Node
var checks := 0
var failures := 0
var report: Array[Dictionary] = []
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	if OS.get_environment("BAGYONG_ISOLATED_SMOKE") != OS.get_user_data_dir():
		get_tree().quit(1)
		return
	get_tree().current_scene = null
	GlobalTimer.start_fresh()
	GlobalTimer.pause_timer(self)
	SceneManager.has_played_opening = true
	for location_id in ["grocery", "tindahan"]:
		var scene := load("res://game/scenes/locations/%s.tscn" % location_id).instantiate() as Node3D
		get_tree().root.add_child(scene)
		get_tree().current_scene = scene
		var player := get_tree().get_first_node_in_group("player") as PlayerV2
		player.set_movement_locked(true)
		player.position = Vector3(50, 1, 50)
		await get_tree().physics_frame
		await get_tree().physics_frame
		var space := scene.get_world_3d().direct_space_state
		for animal: AmbientAnimal in scene.get_node("AmbientAnimals").get_children():
			if animal.waypoints.size() < 2:
				continue
			animal.set_physics_process(false)
			animal._animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
			var points := PackedVector3Array([animal.position])
			if animal.waypoints.size() > 1:
				points.clear()
				for leg in range(animal.waypoints.size() - 1):
					var count := int(ceil(animal.waypoints[leg].distance_to(animal.waypoints[leg + 1]) / 0.5))
					for step in count + 1:
						points.append(animal.waypoints[leg].lerp(animal.waypoints[leg + 1], float(step) / count))
			var original := animal.transform
			for point in points:
				var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.3, point - Vector3.UP * 0.3)
				ray.exclude = [player.get_rid()]
				var hit := space.intersect_ray(ray)
				checks += 1
				if hit.is_empty() or absf(hit.position.y - point.y) > 0.006:
					failures += 1
					printerr("ANIMAL_GROUND_FAIL ", location_id, "/", animal.name, " ", point, " ", hit)
			for clip in animal._animation_player.get_animation_list():
				if clip == "RESET":
					continue
				animal._animation_player.play(clip, 0.0)
				for phase in [0.0, 0.25, 0.5, 0.75, 0.999999]:
					animal.transform = original
					animal._animation_player.seek(animal._animation_player.get_animation(clip).length * phase, true)
					var bounds := _bounds(animal)
					var top := bounds.end.y
					bounds.position.y = maxf(bounds.position.y, 0.035)
					bounds.size.y = maxf(top - bounds.position.y, 0.03)
					var box := BoxShape3D.new()
					box.size = bounds.size
					var query := PhysicsShapeQueryParameters3D.new()
					query.shape = box
					query.margin = 0.0
					query.exclude = [player.get_rid()]
					for point in points:
						for direction in ([-PI / 2, PI / 2] if points.size() > 1 else [original.basis.get_euler().y]):
							var base := Transform3D(Basis(Vector3.UP, direction), point)
							query.transform = base * Transform3D(Basis.IDENTITY, bounds.get_center())
							var hits: Array[Dictionary] = []
							for hit in space.intersect_shape(query, 8):
								# Decorative animals may cross invisible player-only boundary walls.
								if hit.collider is CSGShape3D and not hit.collider.is_visible_in_tree():
									continue
								hits.append(hit)
							checks += 1
							if not hits.is_empty():
								failures += 1
								for hit in hits:
									printerr("ANIMAL_CLEARANCE_FAIL ", location_id, "/", animal.name, " ", clip, " ", phase, " ", point, " ", hit.collider.get_path())
			animal.transform = original
		get_tree().current_scene = null
		scene.queue_free()
		await get_tree().process_frame
	print("ANIMAL_CLEARANCE ", checks, " checks, ", failures, " failures")
	get_tree().quit(0 if failures == 0 else 1)
func _bounds(animal: AmbientAnimal) -> AABB:
	var mesh := animal._mesh_instances[0]
	var skeleton := mesh.get_node(mesh.skeleton) as Skeleton3D
	skeleton.force_update_all_bone_transforms()
	var arrays := mesh.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var stride := bones.size() / vertices.size()
	var transforms: Array[Transform3D] = []
	for bind in mesh.skin.get_bind_count():
		var index := skeleton.find_bone(mesh.skin.get_bind_name(bind))
		transforms.append(animal.global_transform.affine_inverse() * skeleton.global_transform * skeleton.get_bone_global_pose(index) * mesh.skin.get_bind_pose(bind))
	var bounds := AABB()
	for i in vertices.size():
		var position := Vector3.ZERO
		for influence in stride:
			var key := i * stride + influence
			if weights[key] > 0.0:
				position += transforms[bones[key]] * vertices[i] * weights[key]
		if i == 0:
			bounds = AABB(position, Vector3.ZERO)
		else:
			bounds = bounds.expand(position)
	return bounds
