extends Button
@onready var _quit_button: Button = $"."

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	_quit_button.disabled = true
	await TransitionOverlay.fade_to_black()
	get_tree().quit()
	
