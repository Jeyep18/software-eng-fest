# start_button.gd
extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)
	
	# Temporary test — remove after confirming
	print("=== TravelCalculator Test ===")
	print(TravelCalculator.get_travel_path("home", "grocery"))
	print(TravelCalculator.get_travel_time("home", "grocery"))
	print(TravelCalculator.get_travel_time("home", "ate_linda"))
	print(TravelCalculator.get_travel_path("mang_romy", "grocery"))
	print(TravelCalculator.get_travel_label("home", "barangay_hall"))
	print(TravelCalculator.get_travel_time("home", "home"))
	print("=== Test Complete ===")

func _on_pressed() -> void:
	disabled = true
	await TransitionOverlay.fade_to_black()
	SceneManager.load_scene("act1")
