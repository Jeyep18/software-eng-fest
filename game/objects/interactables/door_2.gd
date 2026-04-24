class_name Door
extends Interactable

@export var door_destination: String = "act1"
@export var spawn_point_id: String = ""

func interact() -> void:
	if door_destination.is_empty():
		push_error("Door: door_destination not set on " + name)
		return
	
	await TransitionOverlay.fade_to_black()
	AudioManager.play_sfx(preload("res://game/assets/sfx/15419__pagancow__dorm-door-opening.wav"))
	SceneManager.travel_to(door_destination, spawn_point_id)
