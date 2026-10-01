extends Node
## Graphical presentation and packaged-resource check; run with isolated userdata.

const SAMPLE_SECONDS: float = 3.0
const TEST_CASES: Array[Dictionary] = [
	{"quality": &"high", "vhs": true, "scale": 100, "size": Vector2i(1280, 720)},
	{"quality": &"high", "vhs": false, "scale": 175, "size": Vector2i(1920, 1080)},
	{"quality": &"balanced", "vhs": true, "scale": 175, "size": Vector2i(1280, 800)},
	{"quality": &"balanced", "vhs": false, "scale": 100, "size": Vector2i(1920, 1080)},
	{"quality": &"performance", "vhs": true, "scale": 100, "size": Vector2i(1280, 800)},
	{"quality": &"performance", "vhs": false, "scale": 175, "size": Vector2i(1280, 720)},
]

var _checks: int = 0
var _failures: int = 0
var _frame_deltas: Array[float] = []
var _collecting: bool = false
var _last_frame_usec: int = 0
var _results: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()

func _process(_delta: float) -> void:
	var now_usec := Time.get_ticks_usec()
	if _collecting:
		_frame_deltas.append(float(now_usec - _last_frame_usec) / 1000000.0)
	_last_frame_usec = now_usec

func _check(condition: bool, label: String) -> bool:
	_checks += 1
	if not condition:
		_failures += 1
	print("MILESTONE3 ", "PASS " if condition else "FAIL ", label)
	return condition

func _run() -> void:
	if not _check(OS.get_environment("BAGYONG_ISOLATED_SMOKE") == OS.get_user_data_dir(),
			"explicit isolated userdata path supplied"):
		get_tree().quit(1)
		return
	if not _check(DisplayServer.get_name() != "headless", "graphical renderer available"):
		_finish()
		return
	_test_packaged_resources()
	# Keep this runner alive while SceneManager replaces production scenes.
	get_tree().current_scene = null
	TutorialModal.mark_do_not_show_again()
	GlobalTimer.reset()
	SceneManager.has_played_opening = true
	SceneManager.load_scene("home")
	if not await _wait_for_home():
		_finish()
		return
	await _test_presentation_matrix()
	_finish()

func _test_packaged_resources() -> void:
	_check(FileAccess.file_exists("res://game/localization/game_text.csv"), "localization CSV exists in runtime resources")
	LocalizationManager.set_language("tagalog")
	_check(LocalizationManager.translate("Talk to Nanay") == "Kausapin si Nanay", "known Tagalog translation loads")
	LocalizationManager.set_language("english")
	var stream := load("res://game/assets/sfx/musicholder-hover-button-287656.mp3") as AudioStream
	_check(stream != null and stream.get_length() > 0.0, "representative packaged audio loads with nonzero length")
	if stream != null:
		var previous_players: Array[int] = []
		for child in AudioManager.get_children():
			previous_players.append(child.get_instance_id())
		AudioManager.play_sfx(stream)
		var playing := false
		for child in AudioManager.get_children():
			if not previous_players.has(child.get_instance_id()) and child is AudioStreamPlayer:
				playing = child.playing and child.bus == "SFX"
		_check(playing, "representative SFX enters playback on the SFX bus")

func _wait_for_home() -> bool:
	var deadline := Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < deadline:
		var scene := get_tree().current_scene
		if scene != null and scene.scene_file_path == SceneManager.SCENE_PATHS["home"] \
				and not SceneManager.is_travelling and TransitionOverlay.overlay.color.a < 0.01:
			return _check(true, "home scene finishes its startup transition")
		await get_tree().create_timer(0.05, true).timeout
	return _check(false, "home scene finishes its startup transition")

func _test_presentation_matrix() -> void:
	var window := get_window()
	window.mode = Window.MODE_WINDOWED
	await get_tree().create_timer(0.5, true).timeout
	for index in range(TEST_CASES.size()):
		var test_case: Dictionary = TEST_CASES[index]
		VisualSettings.set_quality_preset(test_case["quality"])
		VisualSettings.set_vhs_crt_enabled(test_case["vhs"])
		VisualSettings.set_ui_scale_percent(test_case["scale"])
		window.size = test_case["size"]
		await get_tree().process_frame
		await get_tree().process_frame
		_check(VisualSettings.get_quality_preset() == test_case["quality"], "case %d quality applied" % index)
		_check(VisualSettings.is_vhs_crt_enabled() == test_case["vhs"] \
			and VhsCrtOverlay.get_node("VhsCrtOverlay").visible == test_case["vhs"], "case %d VHS state applied" % index)
		_check(VisualSettings.get_ui_scale_percent() == test_case["scale"], "case %d UI scale applied" % index)
		_check(_check_scene_quality(test_case["quality"]), "case %d scene lighting, environment and camera effects applied" % index)
		var warmup_start_ms := Time.get_ticks_msec()
		while Time.get_ticks_msec() - warmup_start_ms < 2000:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		_check(window.size == test_case["size"] and image.get_size() == test_case["size"],
			"case %d render resolution applied (actual %s, mode %d)" % [index, image.get_size(), window.mode])
		var screenshot_path := "user://milestone3_case_%02d.png" % index
		_check(image.save_png(screenshot_path) == OK, "case %d screenshot saved" % index)
		_frame_deltas.clear()
		var sample_start_ms := Time.get_ticks_msec()
		_collecting = true
		_last_frame_usec = Time.get_ticks_usec()
		while Time.get_ticks_msec() - sample_start_ms < int(SAMPLE_SECONDS * 1000.0):
			await get_tree().process_frame
		_collecting = false
		var samples := _frame_deltas.duplicate()
		var elapsed_seconds := float(Time.get_ticks_msec() - sample_start_ms) / 1000.0
		var fps := float(samples.size()) / elapsed_seconds
		var p95_ms := _percentile_ms(samples, 0.95)
		_check(samples.size() >= 30, "case %d has at least 30 frame-time samples" % index)
		_results.append({
			"case": index,
			"quality": String(test_case["quality"]),
			"vhs": test_case["vhs"],
			"ui_scale_percent": test_case["scale"],
			"resolution": "%dx%d" % [test_case["size"].x, test_case["size"].y],
			"window_mode": window.mode,
			"screenshot": screenshot_path,
			"viewport_width": image.get_width(),
			"viewport_height": image.get_height(),
			"sample_seconds": SAMPLE_SECONDS,
			"elapsed_seconds": elapsed_seconds,
			"sample_count": samples.size(),
			"average_fps": fps,
			"p95_frame_ms": p95_ms,
		})
		print("MILESTONE3 PERF case=%d samples=%d fps=%.2f p95_ms=%.2f" % [index, samples.size(), fps, p95_ms])

func _percentile_ms(samples: Array[float], percentile: float) -> float:
	if samples.is_empty():
		return 0.0
	var sorted := samples.duplicate()
	sorted.sort()
	var index := clampi(ceili(float(sorted.size()) * percentile) - 1, 0, sorted.size() - 1)
	return sorted[index] * 1000.0

func _check_scene_quality(preset: StringName) -> bool:
	var scene := get_tree().current_scene
	var spotlights := scene.find_children("*", "SpotLight3D", true, false)
	var environments := scene.find_children("*", "WorldEnvironment", true, false)
	var player := get_tree().get_first_node_in_group("player")
	var camera: Camera3D = player.find_child("Camera3D", true, false) as Camera3D if player != null else null
	if spotlights.is_empty() or environments.is_empty() or camera == null or camera.attributes == null:
		return false
	var light := spotlights[0] as Light3D
	if not light.has_meta("visual_quality_base_energy"):
		return false
	var multiplier := 1.0
	match preset:
		&"balanced": multiplier = 0.82
		&"performance": multiplier = 0.62
	var light_applied := is_equal_approx(light.light_energy, float(light.get_meta("visual_quality_base_energy")) * multiplier)
	var environment := (environments[0] as WorldEnvironment).environment
	if environment == null or not environment.has_meta("visual_quality_base_ssil"):
		return false
	var glow_multiplier := 1.0
	match preset:
		&"balanced": glow_multiplier = 0.7
		&"performance": glow_multiplier = 0.35
	var environment_applied := environment.ssil_enabled == bool(environment.get_meta("visual_quality_base_ssil")) \
		if preset == &"high" else not environment.ssil_enabled
	environment_applied = environment_applied and is_equal_approx(environment.glow_intensity,
		float(environment.get_meta("visual_quality_base_glow_intensity")) * glow_multiplier)
	var camera_applied := (camera.attributes as CameraAttributesPractical).dof_blur_far_enabled == (preset != &"performance")
	return light_applied and environment_applied and camera_applied

func _finish() -> void:
	var report := {
		"checks": _checks,
		"failures": _failures,
		"os": OS.get_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"gpu_vendor": RenderingServer.get_video_adapter_vendor(),
		"gpu_name": RenderingServer.get_video_adapter_name(),
		"vsync_mode": DisplayServer.window_get_vsync_mode(),
		"cases": _results,
	}
	var file := FileAccess.open("user://milestone3_report.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "\t"))
	else:
		_failures += 1
		report["failures"] = _failures
	print("Milestone 3 validation: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)
