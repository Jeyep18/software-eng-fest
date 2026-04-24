# start_button.gd
extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	AudioManager.stop_music(true)
	disabled = true
	await TransitionOverlay.fade_to_black()
	SceneManager.load_scene("home")
	GlobalTimer.resume_timer()
