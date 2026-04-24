extends Button

func _ready() -> void:
	pressed.connect(_on_end_day_pressed)

func _on_end_day_pressed() -> void:
	# Close the map UI and resume the timer first,
	# otherwise the pause stack will block storm_arrived from processing.
	GlobalTimer.resume_timer()
	GlobalTimer.force_storm_arrival()
