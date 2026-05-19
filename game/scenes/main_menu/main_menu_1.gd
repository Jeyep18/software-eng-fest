extends Node3D

@onready var leaderboards_button: Button = $VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/leaderboards_button
@onready var leaderboards_modal: CanvasLayer = $LeaderboardsModal

# MainMenu.gd
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	leaderboards_button.pressed.connect(_on_leaderboards_pressed)
	await TransitionOverlay.fade_from_black()
	AudioManager.play_ambience(preload("res://game/assets/sfx/u_7hpxkdroz2-storm-461601.mp3"))
	AudioManager.play_music(preload("res://game/assets/sfx/PhaseShift(chosic.com)-ScottBuckley.mp3"))

func _on_leaderboards_pressed() -> void:
	if leaderboards_modal.has_method("open"):
		leaderboards_modal.open()
