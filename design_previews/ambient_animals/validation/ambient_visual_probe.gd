extends Node

const OUTPUT := "C:/Temp/bagyong-ambient-integration-20261011/captures"
const VIEWS := {
	"grocery": {
		"RestingCat": Vector3(10.5, 0.8, -14.0),
		"WalkingCat": Vector3(-5.8, 0.8, -14.4),
		"WanderingDog": Vector3(8.5, 0.8, -11.0),
	},
	"tindahan": {
		"RestingCat": Vector3(18.8, 1.0, -10.0),
		"WalkingDog": Vector3(3.8, 0.7, -6.9),
	},
}
var measurements: Array[Dictionary] = []
var failures := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()

func _run() -> void:
	if OS.get_environment("BAGYONG_ISOLATED_SMOKE") != OS.get_user_data_dir():
		push_error("Visual probe requires isolated user data.")
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	get_tree().current_scene = null
	GlobalTimer.start_fresh()
	GlobalTimer.pause_timer(self)
	SceneManager.has_played_opening = true
	for location_id in VIEWS:
		var location := load("res://game/scenes/locations/%s.tscn" % location_id).instantiate() as Node3D
		get_tree().root.add_child(location)
		get_tree().current_scene = location
		SceneManager.current_location = "ate_linda" if location_id == "tindahan" else location_id
		await get_tree().process_frame
		# Hold at approved anchors for repeatable camera comparisons; animations continue.
		for animal in location.get_node("AmbientAnimals").get_children():
			animal.set_physics_process(false)
		var player := get_tree().get_first_node_in_group("player") as PlayerV2
		player.set_movement_locked(true)
		var camera := player.get_node("camera_mount/Camera3D") as Camera3D
		camera.make_current()
		var qualities := [&"high"] if OS.get_cmdline_user_args().has("--quick") else [&"high", &"performance"]
		var filters := [false] if OS.get_cmdline_user_args().has("--quick") else [false, true]
		for quality in qualities:
			VisualSettings.set_quality_preset(quality)
			for vhs in filters:
				VisualSettings.set_vhs_crt_enabled(vhs)
				for animal_name in VIEWS[location_id]:
					player.global_position = VIEWS[location_id][animal_name]
					player.velocity = Vector3.ZERO
					await get_tree().create_timer(1.8).timeout
					var animal := location.get_node("AmbientAnimals/" + animal_name) as AmbientAnimal
					var centre := animal.global_position + Vector3(0, 0.2 if animal.species == 0 else 0.35, 0)
					var visible_in_camera := camera.is_position_in_frustum(centre)
					if not visible_in_camera:
						failures += 1
					var label := "%s_%s_%s_vhs_%s" % [location_id, animal_name, quality, str(vhs)]
					await RenderingServer.frame_post_draw
					get_viewport().get_texture().get_image().save_png(OUTPUT.path_join(label + ".png"))
					var visible_pixels := -1
					if not vhs:
						var mesh := animal._mesh_instances[0]
						var original := mesh.material_override
						var mask := StandardMaterial3D.new()
						mask.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
						mask.albedo_color = Color.MAGENTA
						mesh.material_override = mask
						await RenderingServer.frame_post_draw
						await RenderingServer.frame_post_draw
						var mask_image := get_viewport().get_texture().get_image()
						mask_image.save_png(OUTPUT.path_join(label + "_visibility.png"))
						visible_pixels = 0
						for y in mask_image.get_height():
							for x in mask_image.get_width():
								var pixel := mask_image.get_pixel(x, y)
								if pixel.r > pixel.g + 0.18 and pixel.b > pixel.g + 0.18:
									visible_pixels += 1
						mesh.material_override = original
						if visible_pixels < 25:
							failures += 1
					measurements.append({"label": label, "camera_visible": visible_in_camera,
						"animal": animal.global_position, "player": player.global_position,
						"camera": camera.global_position, "clip": animal._clip,
						"screen": camera.unproject_position(centre), "visible_pixels": visible_pixels,
						"process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000})
					print("ANIMAL_VISUAL ", label, " frustum=", visible_in_camera, " visible_pixels=", visible_pixels)
		get_tree().current_scene = null
		location.queue_free()
		await get_tree().process_frame
	var file := FileAccess.open(OUTPUT.path_join("measurements.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(measurements, "\t"))
	print("Animal camera probes: ", measurements.size(), " captures, ", failures, " visibility failures")
	get_tree().quit(0 if failures == 0 else 1)
