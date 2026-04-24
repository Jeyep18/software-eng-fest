# end_day.gd
# Attach to the "End Day" Button inside the MapScreen panel.
# When pressed:
#   1. Closes the MapScreen so it doesn't sit on top of the ending cinematic.
#   2. Resumes the timer (clears the pause the MapScreen pushed).
#   3. Forces the clock to 720 min — this fires storm_arrived,
#      which SceneManager catches and loads EndingSequence.tscn.

extends Button

func _ready() -> void:
	pressed.connect(_on_end_day_pressed)

func _on_end_day_pressed() -> void:
	# 1. Close the map UI first.
	#    MapScreen.close_map() restores mouse mode and hides the panel.
	#    We reach it via the scene tree rather than a hardcoded path so
	#    this button works regardless of where MapScreen sits.
	var map_screen = get_tree().get_first_node_in_group("map_screen")
	if map_screen and map_screen.has_method("close_map"):
		map_screen.close_map()

	# 2. Resume the timer — MapScreen.open_map() pushed a pause,
	#    close_map() should have already resumed it, but we call
	#    resume_timer() once more as a safety net in case the
	#    MapScreen implementation does not manage the pause stack.
	#    The storm handler inside GlobalTimer will re-freeze the clock.
	GlobalTimer.resume_timer()

	# 3. Force the clock to the end — emits storm_arrived.
	GlobalTimer.force_storm_arrival()
