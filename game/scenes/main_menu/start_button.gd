# start_button.gd
extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	AudioManager.stop_music(true)
	disabled = true
	await TransitionOverlay.fade_to_black()
	SceneManager.reset()
	StormEnroachment.reset()
	NeedsLog.reset()
	ShopUi.reset()
	InventoryManager.reset()
	var selected_difficulty := GameState.selected_difficulty
	GameState.reset()
	GameState.set_difficulty(selected_difficulty)
	SceneManager.load_scene("home")
	GlobalTimer.start_fresh()
