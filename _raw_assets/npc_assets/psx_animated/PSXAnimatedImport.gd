@tool
extends EditorScenePostImport
## Assigned only to the 11 corrected animated NPC assets.

func _post_import(scene: Node) -> Object:
	_configure(scene)
	return scene

func _configure(node: Node) -> void:
	if node is AnimationPlayer:
		for clip in node.get_animation_list():
			var animation: Animation = node.get_animation(clip)
			animation.loop_mode = Animation.LOOP_LINEAR if clip in ["idle_loop", "talk_loop", "relieved_loop"] else Animation.LOOP_NONE
			for track in range(animation.get_track_count()):
				animation.track_set_interpolation_type(track, Animation.INTERPOLATION_NEAREST)
		if node.has_animation("idle_loop"):
			node.autoplay = "idle_loop"
	if node is MeshInstance3D and node.mesh != null:
		for surface in range(node.mesh.get_surface_count()):
			var material := node.get_active_material(surface) as BaseMaterial3D
			if material != null:
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	for child in node.get_children():
		_configure(child)
