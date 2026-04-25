extends Node3D

# MainMenu.gd
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	TransitionOverlay.fade_from_black()
	AudioManager.play_ambience(preload("res://game/assets/sfx/u_7hpxkdroz2-storm-461601.mp3"))
	AudioManager.play_music(preload("res://game/assets/sfx/PhaseShift(chosic.com)-ScottBuckley.mp3"))
