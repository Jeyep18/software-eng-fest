# start_button.gd
extends Button

func _ready() -> void:
	# Connect the signal in code in case it isn't wired in the editor
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	disabled = true
	await TransitionOverlay.fade_to_black()
	SceneManager.load_scene("act1")
