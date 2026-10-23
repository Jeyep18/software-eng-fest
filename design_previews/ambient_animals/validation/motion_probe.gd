extends Node
const OUTPUT := "C:/Temp/bagyong-ambient-integration-20261011/motion"
const CASES := {"grocery": ["WalkingCat", "WanderingDog"], "tindahan": ["WalkingDog"]}
var captures := 0
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	if OS.get_environment("BAGYONG_ISOLATED_SMOKE") != OS.get_user_data_dir():
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	get_tree().current_scene = null
	GlobalTimer.start_fresh()
	GlobalTimer.pause_timer(self)
	SceneManager.has_played_opening = true
	VisualSettings.set_quality_preset(&"high")
	VisualSettings.set_vhs_crt_enabled(false)
	for location_id in CASES:
		var location := load("res://game/scenes/locations/%s.tscn" % location_id).instantiate() as Node3D
		get_tree().root.add_child(location)
		get_tree().current_scene = location
		await get_tree().process_frame
		var player := get_tree().get_first_node_in_group("player") as PlayerV2
		player.set_movement_locked(true)
		player.set_physics_process(false)
		var mount := player.get_node("camera_mount") as Camera2D5Controller
		var camera := mount.get_node("Camera3D") as Camera3D
		camera.make_current()
		for animal: AmbientAnimal in location.get_node("AmbientAnimals").get_children():
			animal.set_physics_process(false)
			animal._animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		for animal_name in CASES[location_id]:
			var animal := location.get_node("AmbientAnimals/" + animal_name) as AmbientAnimal
			var folder := OUTPUT.path_join(location_id + "_" + animal_name)
			DirAccess.make_dir_recursive_absolute(folder)
			animal.position = animal.waypoints[0]
			animal.rotation.y = -PI / 2
			animal._waypoint_index = 1
			animal._waypoint_step = 1
			animal._rng.seed = 42
			animal._player = player
			animal._begin_walk()
			player.position = _viewpoint(location_id, animal)
			await get_tree().create_timer(1.8).timeout
			var clips_seen := {}
			for frame in 240:
				animal._physics_process(1.0 / 12.0)
				animal._animation_player.advance(1.0 / 12.0)
				clips_seen[animal._clip] = true
				player.position = _viewpoint(location_id, animal)
				mount._physics_process(1.0 / 12.0)
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(folder.path_join("%04d.png" % frame))
				captures += 1
			print("ANIMAL_MOTION ", location_id, "/", animal_name, " 20 simulated seconds, clips=", clips_seen.keys(), " endpoint=", animal.position)
		if location_id == "grocery":
			for animal_name in ["RestingCat", "WanderingDog"]:
				var animal := location.get_node("AmbientAnimals/" + animal_name) as AmbientAnimal
				if animal.species == AmbientAnimal.Species.DOG:
					animal.position = animal.waypoints[0]
					animal.rotation.y = -PI / 2
				player.position = Vector3(10.5, 0.6179, -14.0) if animal.species == 0 else Vector3(8.7, 0.6179, -12.5)
				await get_tree().create_timer(1.8).timeout
				for clip in animal._animation_player.get_animation_list():
					if clip == "RESET":
						continue
					animal._animation_player.play(clip, 0.0)
					animal._animation_player.seek(animal._animation_player.get_animation(clip).length * 0.5, true)
					await RenderingServer.frame_post_draw
					await RenderingServer.frame_post_draw
					var image := get_viewport().get_texture().get_image()
					var screen := camera.unproject_position(animal.global_position + Vector3(0, 0.15 if animal.species == 0 else 0.25, 0))
					var rect := Rect2i(int(screen.x) - 200, int(screen.y) - 160, 400, 320)
					image.get_region(rect).save_png(OUTPUT.path_join(("cat" if animal.species == 0 else "dog") + "_" + clip + ".png"))
					captures += 1
		get_tree().current_scene = null
		location.queue_free()
		await get_tree().process_frame
	print("ANIMAL_MOTION_CAPTURE ", captures, " frames")
	get_tree().quit()
func _viewpoint(location_id: String, animal: AmbientAnimal) -> Vector3:
	if location_id == "grocery" and animal.species == AmbientAnimal.Species.DOG:
		return Vector3(animal.position.x - 0.8, 0.6179, -12.5)
	if animal.species == AmbientAnimal.Species.CAT:
		return Vector3(-5.8, 0.6179, -14.4)
	return Vector3(3.8, 0.500448, -6.9)
