# end_day.gd
# Attach to the "End Day" Button inside the MapScreen panel.
# When pressed:
#   1. Closes the MapScreen so it does not sit on top of the ending cinematic.
#   2. Forces the clock to 720 min, which fires storm_arrived.

extends Button

func _ready() -> void:
	pressed.connect(_on_end_day_pressed)

func _on_end_day_pressed() -> void:
	LeaderboardManager.snapshot_remaining_time(GlobalTimer.TOTAL_MINUTES - GlobalTimer.current_minutes)

	var map_screen = get_tree().get_first_node_in_group("map_screen")
	if map_screen and map_screen.has_method("close_map"):
		map_screen.close_map()

	GlobalTimer.force_storm_arrival()
