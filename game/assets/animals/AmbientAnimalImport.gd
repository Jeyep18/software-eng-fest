@tool
extends EditorScenePostImport
## Assigned only to the approved cat and dog GLBs.

func _post_import(scene: Node) -> Object:
	_configure(scene)
	return scene


func _configure(node: Node) -> void:
	if node is AnimationPlayer:
		node.autoplay = ""
		for clip in node.get_animation_list():
			var animation: Animation = node.get_animation(clip)
			animation.loop_mode = Animation.LOOP_LINEAR if clip.ends_with("_loop") else Animation.LOOP_NONE
	if node is MeshInstance3D:
		node.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC
		if node.mesh != null:
			for surface in range(node.mesh.get_surface_count()):
				var material := node.get_active_material(surface) as BaseMaterial3D
				if material != null:
					material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	for child in node.get_children():
		_configure(child)
