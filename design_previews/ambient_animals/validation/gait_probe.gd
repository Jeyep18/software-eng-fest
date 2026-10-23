extends Node
func _ready() -> void:
	if OS.get_environment("BAGYONG_ISOLATED_SMOKE") != OS.get_user_data_dir():
		get_tree().quit(1)
		return
	for species in ["cat", "dog"]:
		var animal: AmbientAnimal = load("res://game/entities/animals/ambient_%s.tscn" % species).instantiate()
		add_child(animal)
		animal.set_physics_process(false)
		var player := animal._animation_player
		player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		var mesh := animal._mesh_instances[0]
		var skeleton := mesh.get_node(mesh.skeleton) as Skeleton3D
		var arrays := mesh.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var stride := bones.size() / vertices.size()
		for clip in (["walk_loop", "run_loop"] if species == "dog" else ["walk_loop"]):
			var frames := int(round(player.get_animation(clip).length * 24.0))
			var poses: Array[PackedVector3Array] = []
			player.play(clip, 0.0)
			for frame in frames + 1:
				player.seek(minf(frame / 24.0, player.get_animation(clip).length - 0.000001), true)
				skeleton.force_update_all_bone_transforms()
				var transforms: Array[Transform3D] = []
				for bind in mesh.skin.get_bind_count():
					var index := skeleton.find_bone(mesh.skin.get_bind_name(bind))
					transforms.append(skeleton.global_transform * skeleton.get_bone_global_pose(index) * mesh.skin.get_bind_pose(bind))
				var positions := PackedVector3Array()
				for i in vertices.size():
					var position := Vector3.ZERO
					for influence in stride:
						var key := i * stride + influence
						if weights[key] > 0.0:
							position += transforms[bones[key]] * vertices[i] * weights[key]
					positions.append(position)
				poses.append(positions)
			var speeds: Array[float] = []
			for frame in frames:
				for vertex in vertices.size():
					var first := poses[frame][vertex]
					var last := poses[frame + 1][vertex]
					var speed := (last.z - first.z) * 24.0
					if maxf(first.y, last.y) < (0.022 if clip == "run_loop" else 0.02) and speed > 0.03:
						speeds.append(speed)
			speeds.sort()
			print("GAIT ", species, " ", clip, " planted low-surface samples=", speeds.size(), " median backwards paw speed=", speeds[speeds.size() / 2] if not speeds.is_empty() else -1.0)
		animal.queue_free()
		await get_tree().process_frame
	get_tree().quit()
