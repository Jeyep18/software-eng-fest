class_name Door
extends Interactable

@export var door_destination: String = "act1"
@export var spawn_point_id: String = ""

func interact() -> void:
	if door_destination.is_empty():
		push_error("Door: door_destination not set on " + name)
		return
	
	await TransitionOverlay.fade_to_black()
	SceneManager.travel_to(door_destination, spawn_point_id)
