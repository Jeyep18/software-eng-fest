extends Interactable

func _ready() -> void:
	prompt_label = "Go Outside"
	super._ready()

func interact() -> void:
	if SceneManager.is_travelling:
		return

	var map_screen = get_tree().get_first_node_in_group("map_screen")
	if map_screen == null or not map_screen.has_method("open_map"):
		push_warning("MainDoor: Could not find MapScreen to open.")
		return

	map_screen.open_map()
