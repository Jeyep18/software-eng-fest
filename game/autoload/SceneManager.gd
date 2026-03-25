# SceneManager.gd
extends Node

var current_location: String = "home"

const SCENE_PATHS: Dictionary = {
	"act1": "res://game/scenes/act1/Act1.tscn",
}

func load_scene(scene_id: String) -> void:
	if not SCENE_PATHS.has(scene_id):
		push_error("SceneManager: Unknown scene ID: " + scene_id)
		return
	get_tree().change_scene_to_file(SCENE_PATHS[scene_id])
	await get_tree().create_timer(0.1).timeout
	await TransitionOverlay.fade_from_black()
