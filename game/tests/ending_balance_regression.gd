extends Node

var _checks := 0
var _failures := 0


func _ready() -> void:
	_run.call_deferred()


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print("ENDING BALANCE ", "PASS " if condition else "FAIL ", description)


func _run() -> void:
	var ending := preload("res://game/scenes/ending/EndingSequence.tscn").instantiate()
	ending._snapshot = {"weighted_progress": 0, "resolved_ids": [], "visited": [], "nestor_status": SideQuestLog.STATE_NOT_STARTED}
	_check(ending._get_household_title() == "Too Little Prepared", "empty household tier")
	ending._snapshot["weighted_progress"] = 4
	_check(ending._get_household_title() == "A Night of Shortages", "partial household tier")
	ending._snapshot["weighted_progress"] = 8
	ending._snapshot["resolved_ids"] = ["food", "water", "medicine", "windows"]
	_check(ending._get_household_title() == "Essentials Secured, Gaps Remain", "essential household tier")
	ending._snapshot["resolved_ids"] = ["food", "water", "roof", "windows", "flashlight"]
	_check(ending._get_household_title() == "A Night of Shortages", "missing medicine prevents essential tier")
	ending._snapshot["weighted_progress"] = NeedsLog.TOTAL_WEIGHT
	ending._snapshot["resolved_ids"] = ["food", "water", "medicine", "roof", "windows", "flashlight"]
	_check(ending._get_household_title() == "A Prepared Home", "complete household tier")

	ending.SLIDES.clear()
	ending._append_visited_shots()
	_check(ending.SLIDES.is_empty(), "unvisited places and unaccepted Nestor are absent")
	ending._snapshot["nestor_status"] = SideQuestLog.STATE_ACTIVE
	ending._append_visited_shots()
	_check(ending.SLIDES.size() == 1 and "still waiting" in ending.SLIDES[0]["text"], "accepted unfinished quest shows waiting Nestor")
	ending.SLIDES.clear()
	ending._snapshot["nestor_status"] = SideQuestLog.STATE_READY_TO_TURN_IN
	ending._append_visited_shots()
	_check(ending.SLIDES.size() == 1 and "still waiting" in ending.SLIDES[0]["text"], "chicken not delivered keeps Nestor waiting")
	ending.SLIDES.clear()
	ending._snapshot["nestor_status"] = SideQuestLog.STATE_COMPLETED
	ending._append_visited_shots()
	_check(ending.SLIDES.size() == 1 and "food on the table" in ending.SLIDES[0]["text"], "delivered quest shows fed family")
	ending.SLIDES.clear()
	ending._snapshot["nestor_status"] = SideQuestLog.STATE_NOT_STARTED
	ending._snapshot["visited"] = ["hardware", "grocery", "pharmacy", "tindahan", "barangay_hall", "mang_romy"]
	ending._append_visited_shots()
	_check(ending.SLIDES.size() == 4, "only visited finished public scenes enter montage")
	ending._apply_visual_cue({"need": NeedsLog.Need.WINDOWS, "visual_cue_path": "World3D/WindowArea/WindowTaskVisualCue"}, false, true)
	var window_cue: Node3D = ending.get_node("World3D/WindowArea/WindowTaskVisualCue")
	var whole_window_visible := window_cue.visible
	for plank in window_cue.get_children():
		whole_window_visible = whole_window_visible and plank.visible
	_check(whole_window_visible, "one completed window shows all its planks")
	var all_shots_have_focus := true
	for slide in ending.SLIDES:
		all_shots_have_focus = all_shots_have_focus and slide["anchor"] is Node3D and slide["focus"] is Node3D
		all_shots_have_focus = all_shots_have_focus and slide["focus"].position.z < slide["anchor"].position.z
	_check(all_shots_have_focus, "every public shot has an editable focus in front of its camera")
	var key := InputEventKey.new()
	key.pressed = true
	_check(ending._is_continue_input(key), "pressed key continues result")
	key.echo = true
	_check(not ending._is_continue_input(key), "held key repeat does not continue result")
	var click := InputEventMouseButton.new()
	click.pressed = true
	_check(ending._is_continue_input(click), "mouse click continues result")
	var button := InputEventJoypadButton.new()
	button.pressed = true
	_check(ending._is_continue_input(button), "gamepad button continues result")
	_check(not ending._is_continue_input(InputEventMouseMotion.new()), "mouse movement does not continue result")
	if OS.get_cmdline_user_args().has("--visual-only"):
		if OS.get_environment("BAGYONG_ISOLATED_SMOKE") != OS.get_user_data_dir():
			_check(false, "visual capture requires isolated userdata")
		else:
			await _capture_shots(ending)
	else:
		ending.free()
	print("Ending balance regression: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)


func _capture_shots(ending: Node) -> void:
	Engine.time_scale = 0.001
	VisualSettings.set_vhs_crt_enabled(not OS.get_cmdline_user_args().has("--vhs-off"))
	add_child(ending)
	for i in range(4):
		await get_tree().process_frame
	ending.fade_overlay.color.a = 0.0
	ending.slide_label.hide()
	ending.result_panel.hide()
	ending.ending_camera.make_current()
	for location_id in ["Hardware", "Grocery", "Pharmacy", "Tindahan"]:
		ending._set_shot_environment(location_id.to_lower())
		ending._snap_camera_to(ending.get_node("LocationSets/%s/Start" % location_id))
		var focus: Vector3 = ending.get_node("LocationSets/%s/Focus" % location_id).global_position
		ending.ending_camera.look_at(focus)
		var start_offset: Vector3 = ending.ending_camera.global_position - focus
		_check(ending.world_environment.environment == ending.SHOP_ENV, "%s uses shop environment" % location_id)
		_check(not ending.house_sun.visible and not ending.get_node("Environment/VoxelGI").visible, "%s hides house lighting" % location_id)
		if location_id == "Hardware" or location_id == "Grocery" or location_id == "Pharmacy":
			var location_gi: VoxelGI = ending.get_node("LocationSets/%s/VoxelGI" % location_id)
			_check(location_gi.visible and location_gi.data != null, "%s uses its baked lighting" % location_id)
		if location_id == "Tindahan":
			ending.get_node("LocationSets/Tindahan/NestorVisual").show()
		_check(await _capture(ending, location_id.to_lower() + "_start"), "saved %s start" % location_id)
		ending._orbit_camera(1.0, focus, start_offset)
		_check(is_equal_approx(ending.ending_camera.global_position.distance_to(focus), start_offset.length()), "%s orbit keeps focal distance" % location_id)
		_check((-ending.ending_camera.global_basis.z).dot((focus - ending.ending_camera.global_position).normalized()) > 0.999, "%s orbit keeps focus centered" % location_id)
		_check(await _capture(ending, location_id.to_lower() + "_orbit_end"), "saved %s orbit end" % location_id)
	ending.get_node("LocationSets/Tindahan/NestorVisual").hide()
	_check(await _capture(ending, "tindahan_delivered"), "saved empty Nestor scene")
	ending.get_node("LocationSets/Tindahan/NestorVisual").show()
	var waiting_source := "Mang Nestor was still waiting outside the tindahan when the storm came. The promised meal never reached his family; they had no food on the table."
	ending.slide_label.show()
	ending.slide_label.modulate.a = 1.0
	for language in ["english", "tagalog"]:
		LocalizationManager.set_language(language)
		ending.slide_label.text = LocalizationManager.translate(waiting_source)
		_check(await _capture(ending, "nestor_text_" + language), "saved Nestor caption in %s" % language)
		if language == "tagalog":
			_check(ending.slide_label.text != waiting_source, "Tagalog Nestor caption is translated")
	ending.slide_label.hide()
	ending._set_shot_environment("")
	ending._snap_camera_to(ending.get_node("World3D/WindowArea"))
	_check(ending.world_environment.environment == ending.HOUSE_ENV and ending.house_sun.visible, "house shot restores house environment")
	_check(not ending.get_node("LocationSets/Hardware/VoxelGI").visible and not ending.get_node("LocationSets/Grocery/VoxelGI").visible and not ending.get_node("LocationSets/Pharmacy/VoxelGI").visible, "house shot hides town baked lighting")
	var house_focus: Vector3 = ending.ending_camera.global_position - ending.ending_camera.global_basis.z * 3.0
	var house_offset: Vector3 = ending.ending_camera.global_position - house_focus
	ending._orbit_camera(1.0, house_focus, house_offset)
	_check(is_equal_approx(ending.ending_camera.global_position.distance_to(house_focus), 3.0), "house orbit keeps focal distance")
	ending._apply_visual_cue({"need": NeedsLog.Need.WINDOWS, "visual_cue_path": "World3D/WindowArea/WindowTaskVisualCue"}, false, true)
	_check(await _capture(ending, "window_partial"), "saved partial window scene")
	ending._snapshot = {
		"weighted_progress": NeedsLog.TOTAL_WEIGHT,
		"resolved_ids": ["medicine", "food", "windows", "roof", "water", "flashlight"],
		"nestor_status": SideQuestLog.STATE_COMPLETED,
		"difficulty_id": "standard",
		"difficulty_label": "Standard",
		"remaining_minutes": 240,
		"unranked": false,
	}
	ending.fade_overlay.color.a = 1.0
	for language in ["english", "tagalog"]:
		LocalizationManager.set_language(language)
		ending._populate_result_panel()
		var footer: String = ending.result_panel.get_node("VBoxContainer/FooterLabel").text
		_check(footer.contains(LocalizationManager.translate("Safety is not a privilege to be earned. It is a basic accountability of those in power.")), "result restores safety message in %s" % language)
		_check(ending._continue_label.text == LocalizationManager.translate("Press any key or button to continue"), "result continue prompt is localized in %s" % language)
		ending.result_panel.show()
		for child in ending.result_panel.get_node("VBoxContainer").get_children():
			if child is CanvasItem:
				child.modulate.a = 1.0
		_check(await _capture(ending, "result_" + language), "saved result panel in %s" % language)
		await get_tree().process_frame
	ending.queue_free()
	Engine.time_scale = 1.0


func _capture(ending: Node, label: String) -> bool:
	await RenderingServer.frame_post_draw
	var suffix := "_no_vhs" if not VisualSettings.is_vhs_crt_enabled() else ""
	var path := "user://ending_balance_%s%s.png" % [label, suffix]
	var result := ending.get_viewport().get_texture().get_image().save_png(path)
	print("ENDING BALANCE IMAGE ", ProjectSettings.globalize_path(path))
	return result == OK
