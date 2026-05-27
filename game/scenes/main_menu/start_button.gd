# start_button.gd
extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	var menu := get_tree().current_scene
	if menu != null and menu.has_method("request_start_game"):
		menu.request_start_game(self)
