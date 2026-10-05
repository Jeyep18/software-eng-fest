extends Node

var _checks := 0
var _failures := 0


func _ready() -> void:
	_run.call_deferred()


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print("MAP UI ", "PASS " if condition else "FAIL ", description)


func _run() -> void:
	if OS.get_environment("BAGYONG_ISOLATED_SMOKE") != OS.get_user_data_dir():
		push_error("Map UI regression requires isolated userdata: %s" % OS.get_user_data_dir())
		get_tree().quit(1)
		return
	var wide := OS.get_cmdline_user_args().has("--wide")
	var wide_viewport: SubViewport
	if wide:
		wide_viewport = SubViewport.new()
		wide_viewport.size = Vector2i(2560, 1080)
		wide_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(wide_viewport)
	LocalizationManager.set_language("english")
	GlobalTimer.start_fresh()
	var map := preload("res://game/ui/map/MapScreen.tscn").instantiate()
	if wide:
		wide_viewport.add_child(map)
	else:
		add_child(map)
	map.open_map()
	await get_tree().create_timer(0.2).timeout
	_check(map.visible, "map opens")
	if wide:
		var viewport_size := map.get_viewport().get_visible_rect().size
		_check(viewport_size.x >= 2500.0, "ultrawide viewport is active")
		_check(map.map_page.position.is_equal_approx((viewport_size - Vector2(1920, 1080)) * 0.5), "paper is centered in ultrawide viewport")
	_check(map.get_node("MapPage/Panel/MapNodes").get_child_count() == 6, "five live destinations and one storm overlay")
	_check(map.get_node("MapPage/Paper").texture != null, "paper with fixed roads is loaded")
	var storm_front: TextureRect = map.get_node("MapPage/StormFront")
	_check(storm_front.texture != null and storm_front.mouse_filter == Control.MOUSE_FILTER_IGNORE, "fixed storm clouds load behind interactive map controls")
	_check(map.get_node("MapPage/Panel/EndDayPanel/EndDayMargin/EndDayColumn/EndDay").has_method("_on_end_day_pressed"), "early end control remains wired")
	_check(map.get_node("MapPage/Panel/MapHint").text == LocalizationManager.translate("Press M to open or close map"), "M key hint is live text")
	var nodes: Dictionary = map._node_buttons
	var icons_centered := true
	for location_id in nodes.keys():
		icons_centered = icons_centered and (nodes[location_id].position + MapNodeButton.ICON_CENTER).is_equal_approx(map.NODE_POSITIONS[location_id])
	_check(icons_centered, "destination art centers match the printed map circles")
	_check(nodes["home"]._current_label.visible and nodes["home"]._click_area.disabled, "current location is marked and disabled")
	_check(nodes["hardware"]._click_area.focus_mode == Control.FOCUS_ALL, "destination supports keyboard focus")
	nodes["hardware"]._on_mouse_entered()
	await get_tree().create_timer(0.2).timeout
	_check(nodes["hardware"]._glow.modulate.a > 0.9 and nodes["hardware"]._icon.position.y < nodes["hardware"].ICON_Y, "hover lifts and highlights an icon")
	nodes["hardware"]._on_mouse_exited()
	if OS.get_cmdline_user_args().has("--visual-only"):
		await _capture(map, "english_initial")
	map._on_node_selected("hardware")
	_check(map.confirm_panel.visible and map._selected_travel_cost > 0, "travel confirmation keeps a quoted cost")
	await get_tree().process_frame
	var confirm_gap: float = map.confirm_panel.get_global_rect().end.y - map.confirm_button.get_global_rect().end.y
	var end_day_gap: float = map.end_day_panel.get_global_rect().end.y - map.end_day_button.get_global_rect().end.y
	_check(confirm_gap < 25.0 and end_day_gap < 25.0,
		"map action panel bottom gaps: travel %.1f, end %.1f" % [confirm_gap, end_day_gap])
	if OS.get_cmdline_user_args().has("--visual-only"):
		await _capture(map, "english_confirm")
	map._on_cancel_selection()
	_check(not map.confirm_panel.visible and map._selected_location.is_empty(), "cancel clears travel selection")
	GlobalTimer.add_time(240)
	_check(nodes["grocery"]._state_label.visible and not nodes["grocery"]._click_area.disabled, "danger indicator keeps destination available")
	if OS.get_cmdline_user_args().has("--visual-only"):
		await _capture(map, "english_danger")
	GlobalTimer.add_time(120)
	_check(nodes["grocery"]._state_label.visible and nodes["grocery"]._click_area.disabled, "closed indicator blocks destination")
	_check(map.storm_overlay.node_positions == map.NODE_POSITIONS, "storm retains existing map path anchors")
	if OS.get_cmdline_user_args().has("--visual-only"):
		await _capture(map, "english_closed")
		LocalizationManager.set_language("tagalog")
		await _capture(map, "tagalog")
	var map_action := InputEventAction.new()
	map_action.action = "open_map"
	map_action.pressed = true
	map._input(map_action)
	await get_tree().create_timer(0.2).timeout
	_check(not map.visible, "M action closes the map")
	map._input(map_action)
	await get_tree().create_timer(0.2).timeout
	_check(map.visible, "M action reopens the map")
	var end_day: Button = map.get_node("MapPage/Panel/EndDayPanel/EndDayMargin/EndDayColumn/EndDay")
	end_day.pressed.emit()
	_check(GlobalTimer.current_minutes == GlobalTimer.TOTAL_MINUTES, "End the Day still forces storm arrival")
	_check(LeaderboardManager.consume_remaining_time_snapshot() > 0, "early end preserves remaining-time snapshot")
	print("Map UI regression: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)


func _capture(map: CanvasLayer, language: String) -> void:
	map._refresh_all_nodes()
	await RenderingServer.frame_post_draw
	var path := "user://map_ui_%s.png" % language
	var result := map.get_viewport().get_texture().get_image().save_png(path)
	_check(result == OK, "saved %s visual capture" % language)
	print("MAP UI IMAGE ", ProjectSettings.globalize_path(path))
