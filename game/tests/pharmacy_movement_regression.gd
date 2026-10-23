extends Node

var _checks := 0
var _failures := 0

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	if OS.get_environment("BAGYONG_ISOLATED_SMOKE") != OS.get_user_data_dir():
		push_error("Pharmacy movement regression requires isolated userdata.")
		get_tree().quit(1)
		return
	GameState.reset()
	InventoryManager.reset()
	SceneManager.has_played_opening = true
	GlobalTimer.pause_timer(self)
	var scene := preload("res://game/scenes/locations/pharmacy.tscn").instantiate()
	add_child(scene)
	var player := scene.get_node("playerv2") as PlayerV2
	player.set_physics_process(false)
	await get_tree().physics_frame
	await get_tree().physics_frame
	for sprint in [false, true]:
		for start in [Vector3(14.0, 0.7, -7.7), Vector3(16.8, 0.7, -7.7), Vector3(16.99, 0.7, -7.7), Vector3(17.1, 0.7, -7.7)]:
			player.global_position = start
			player.velocity = Vector3.ZERO
			player.set_physics_process(true)
			if sprint:
				Input.action_press("sprint")
			Input.action_press("move_right")
			Input.action_press("move_backward")
			for frame in range(150):
				await get_tree().physics_frame
			Input.action_release("move_right")
			Input.action_release("move_backward")
			Input.action_release("sprint")
			for frame in range(10):
				await get_tree().physics_frame
			player.set_physics_process(false)
			var corner := player.global_position
			_check(corner.x <= 17.0 and corner.z <= -5.4,
				"front/right boundaries still contain the player: " + str(corner))
			for escape in ["move_forward", "move_left"]:
				player.global_position = corner
				player.velocity = Vector3.ZERO
				player.set_physics_process(true)
				Input.action_press(escape)
				for frame in range(60):
					await get_tree().physics_frame
				Input.action_release(escape)
				player.set_physics_process(false)
				var ok := player.global_position.distance_to(corner) > 1.0
				_check(ok, "escape after sprint=%s from %s using %s" % [sprint, start, escape])
				if escape == "move_forward":
					_check(player.global_position.y >= 0.55 and player.global_position.z < -6.8,
						"forward escape reaches the sidewalk top: " + str(player.global_position))
				var contacts: Array[String] = []
				for index in range(player.get_slide_collision_count()):
					var hit := player.get_slide_collision(index)
					contacts.append(str(hit.get_collider().get_path()) + " normal=" + str(hit.get_normal()))
				print("APPROACH ", "PASS " if ok else "FAIL ", "sprint=", sprint, " start=", start,
					" corner=", corner, " escape=", escape, " after=", player.global_position, " contacts=", contacts)
	scene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	print("Pharmacy movement regression: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(1 if _failures else 0)


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("Pharmacy movement regression: " + description)

