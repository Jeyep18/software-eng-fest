extends Node3D

func _ready() -> void:
	TransitionOverlay.fade_from_black()
	AudioManager.play_ambience(preload("res://game/assets/sfx/594553__marlene_coetzer__quiet-house-ambience.wav"))
	AudioManager.play_ambience(preload("res://game/assets/sfx/freesound_community-scary-ambience-59002.mp3"))
	
