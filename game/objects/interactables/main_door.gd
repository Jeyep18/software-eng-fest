extends NarrativeObject

func _on_body_entered(body: Node3D) -> void:
	super._on_body_entered(body)
	if body is PlayerV2 and not body._is_input_locked and not body._is_movement_locked:
		interact()

func interact() -> void:
	if SceneManager.is_travelling:
		return
	if not GameState.house_tasks_unlocked:
		super.interact()
		return

	var map_screen = get_tree().get_first_node_in_group("map_screen")
	if map_screen == null or not map_screen.has_method("open_map"):
		push_warning("MainDoor: Could not find MapScreen to open.")
		return

	map_screen.open_map()
