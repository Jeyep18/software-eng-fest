class_name Door
extends Interactable

var _is_open: bool = false

@export var _animation_player: AnimationPlayer

func interact() -> void:
	await TransitionOverlay.fade_to_black()
	SceneManager.load_scene("act1")
	if _animation_player == null:
		push_error("Door: _animation_player is not assigned on " + name)
		return

	if _animation_player.is_playing():
		return

	if not _is_open:
		_animation_player.play("door_open1")
		_is_open = true
	else:
		_animation_player.play("door_close1")
		_is_open = false
		
