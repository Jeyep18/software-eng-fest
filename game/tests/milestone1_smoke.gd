extends Node
## Scripted integration smoke, not a visual/manual playthrough.
## Run only in a disposable project with APPDATA redirected to temporary data.
## Uses normal engine timing; storm arrival is forced to avoid a 12-hour game wait.

var _checks: int = 0
var _failures: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()

func _check(condition: bool, label: String) -> bool:
	_checks += 1
	if not condition:
		_failures += 1
	print("MILESTONE1 ", "PASS " if condition else "FAIL ", label)
	return condition

func _wait_until(condition: Callable, label: String, seconds: float = 15.0) -> bool:
	var deadline: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await get_tree().create_timer(0.1, true).timeout
	return _check(condition.call(), label)

func _scene_is(scene_id: String) -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.scene_file_path == SceneManager.SCENE_PATHS[scene_id]

func _finish() -> void:
	print("Milestone 1 smoke: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://milestone1_%s.png" % label)

func _dismiss_tutorial() -> bool:
	var player := get_tree().get_first_node_in_group("player")
	if not await _wait_until(func(): return player.find_child("TutorialModal", true, false) != null,
			"tutorial appears after Nanay completes her introduction"):
		return false
	var tutorial := player.find_child("TutorialModal", true, false) as TutorialModal
	_check(tutorial.visible and get_tree().paused, "tutorial pauses the scene tree")
	await _capture("tutorial")
	tutorial.close()
	await get_tree().process_frame
	return _check(not get_tree().paused and not player.get("_is_input_locked"), "tutorial dismissal restores player input")

func _finish_dialogue(speaker: Node) -> void:
	if not speaker.get("_is_showing"):
		speaker.call("interact")
	_check(speaker.get("_is_showing") and GlobalTimer.is_paused, "dialogue opens and pauses clock: " + speaker.name)
	for _step in range(100):
		if not speaker.get("_is_showing"):
			break
		# Repeated interact is the actual skip-typewriter/advance-line route.
		speaker.call("interact")
		await get_tree().process_frame
	_check(not speaker.get("_is_showing"), "dialogue closes: " + speaker.name)

func _travel(location_id: String) -> bool:
	SceneManager.travel_to(location_id)
	return await _wait_until(func(): return _scene_is(location_id) and not SceneManager.is_travelling,
		"travel completes: " + location_id)

func _start_from_menu() -> bool:
	var menu := get_tree().current_scene
	menu.call("request_start_game", null)
	_check(menu.get("_difficulty_layer").visible, "difficulty selector opens")
	menu.call("_on_difficulty_confirmed", GameState.Difficulty.STANDARD)
	if not await _wait_until(func(): return _scene_is("home"), "new run reaches home"):
		return false
	return await _wait_for_wake_up()

func _wait_for_wake_up() -> bool:
	if not await _wait_until(func():
		var player := get_tree().get_first_node_in_group("player")
		return player != null and player.has_node("OpeningMonologue"), "waking opens the kitchen and TV monologue"):
		return false
	var player := get_tree().get_first_node_in_group("player") as PlayerV2
	var monologue := player.get_node("OpeningMonologue") as NarrativeObject
	_check(monologue.is_showing and monologue.monologue_lines == PlayerV2.OPENING_MONOLOGUE_LINES
		and player._is_movement_locked, "wake-up monologue uses the existing player dialogue")
	_check(not GlobalTimer.has_started and GlobalTimer.current_minutes == 0 and not get_tree().paused,
		"wake-up monologue leaves preparation unstarted without pausing the scene tree")
	player._resolve_interaction_target()
	_check(player._current_target == monologue, "wake-up monologue owns dialogue advancement")
	for line_index in PlayerV2.OPENING_MONOLOGUE_LINES.size():
		_check(monologue._current_line == line_index and monologue._ui._speaker_dialog.get_parsed_text()
			== LocalizationManager.translate(PlayerV2.OPENING_MONOLOGUE_LINES[line_index]), "wake-up line appears in order: %d" % line_index)
		Input.action_press("interact")
		await get_tree().create_timer(0.05).timeout
		Input.action_release("interact")
		await get_tree().create_timer(0.05).timeout
		_check(not monologue._is_typing, "E skips wake-up line typing: %d" % line_index)
		await _capture("wake_up_monologue_%d" % line_index)
		await get_tree().process_frame
		Input.action_press("interact")
		await get_tree().create_timer(0.05).timeout
		Input.action_release("interact")
		await get_tree().create_timer(0.05).timeout
		if line_index < PlayerV2.OPENING_MONOLOGUE_LINES.size() - 1:
			_check(player.has_node("OpeningMonologue") and player._is_movement_locked and not GlobalTimer.has_started,
				"advancing a wake-up line keeps dialogue active and preparation unstarted")
	return _check(not player.has_node("OpeningMonologue") and not player._is_input_locked
		and not player._is_movement_locked and not GlobalTimer.has_started,
		"E dismisses the wake-up monologue and restores untimed exploration")

func _test_untimed_opening() -> bool:
	var player := get_tree().get_first_node_in_group("player") as PlayerV2
	var map := get_tree().get_first_node_in_group("map_screen")
	var hud := player.get_node("HUDOverlay")
	var objectives := player.get_node("PreparationChecklistHUD")
	_check(GlobalTimer.is_paused and not GlobalTimer.has_started and GlobalTimer.current_minutes == 0,
		"new run has an unstarted clock")
	_check(not get_tree().paused and not player._is_movement_locked and get_tree().get_nodes_in_group("tutorial_modal").is_empty(),
		"waking permits exploration without a tutorial")
	_check(not hud.top_bar.visible and not objectives.checklist_panel.visible, "clock and objectives remain hidden")
	map.open_map()
	var map_key := InputEventAction.new()
	map_key.action = "open_map"
	map_key.pressed = true
	map._input(map_key)
	_check(not map.visible, "direct map opening and M are blocked before Nanay")
	var generation := SceneManager.transition_generation
	SceneManager.travel_to("hardware", "", 0)
	_check(not SceneManager.is_travelling and generation == SceneManager.transition_generation, "outdoor travel cannot bypass the map lock")
	var door := get_tree().current_scene.get_node("Main_Door")
	var start_position := player.global_position
	player.global_position = door.global_position + Vector3(0, 0.1, 0)
	player.velocity = Vector3.ZERO
	if not await _wait_until(func(): return door.is_showing, "approaching the door opens the money reminder", 3.0):
		return false
	player._facing_direction = -1.0
	player._resolve_interaction_target()
	_check(player._current_target == door and player._is_movement_locked and not player._last_prompt_visible,
		"automatic door monologue remains advanceable while facing away without a conflicting world prompt")
	door._skip_to_line_end()
	await _capture("locked_door")
	await _finish_dialogue(door)
	_check(not map.visible and not player._is_movement_locked, "door reminder closes without opening the map")
	player.global_position = start_position
	await get_tree().create_timer(0.2).timeout
	await _finish_dialogue(get_tree().current_scene.get_node("Fridge/Area3D"))
	_check(NeedsLog.is_discovered(NeedsLog.Need.FOOD) and not objectives._objective_notice.visible,
		"inspection records discoveries without announcing objectives")
	InventoryManager.add_item(load("res://game/resources/items/wrench.tres"))
	InventoryManager.add_item(load("res://game/resources/items/water_jugs.tres"))
	for site_name in ["Roof", "Window", "Window2", "FillWaterTask", "RadioTask", "MedicineTask"]:
		var site := get_tree().current_scene.get_node(site_name) as TaskObject
		site.interact()
		_check(site._is_showing and not site._showing_ready_branch, "untimed task inspection uses missing-supplies dialogue: " + site_name)
		await _finish_dialogue(site)
		_check(not site._is_completed and not site._is_completing, "inspection cannot complete preparation before Nanay: " + site_name)
	_check(InventoryManager.get_total_quantity("wrench") == 1 and InventoryManager.get_total_quantity("water_jug") == 1,
		"untimed inspection retains supplies even when the task requirements are met")
	InventoryManager.reset()
	objectives.checklist_panel.refresh()
	_check(objectives.checklist_panel._list.get_child_count() == 0, "full checklist also hides objectives before Nanay")
	GlobalTimer.add_time(25)
	GlobalTimer.resume_timer()
	await get_tree().create_timer(2.0).timeout
	_check(GlobalTimer.is_paused and GlobalTimer.current_minutes == 0, "inspection close, anonymous resume and burst costs cannot start the opening clock")
	if not await _travel("bodega"):
		return false
	_check(GlobalTimer.is_paused and GlobalTimer.current_minutes == 0 and not GameState.house_tasks_unlocked, "bodega remains accessible without starting time")
	get_tree().get_first_node_in_group("map_screen").open_map()
	_check(not get_tree().get_first_node_in_group("map_screen").visible, "bodega cannot bypass the map lock")
	if not await _travel("home"):
		return false
	var nanay := get_tree().current_scene.get_node("nanay/Area3D")
	nanay.interact()
	nanay._hide_dialogue()
	_check(not GameState.house_tasks_unlocked and not GlobalTimer.has_started and GameState.get_cash() == 0,
		"an interrupted conversation grants no cash and starts no clock")
	await _capture("untimed_home")
	return true

func _run() -> void:
	if not _check(OS.get_environment("BAGYONG_ISOLATED_SMOKE") == OS.get_user_data_dir(),
			"explicit isolated userdata path supplied (BAGYONG_ISOLATED_SMOKE)"):
		_finish()
		return
	_check(is_equal_approx(Engine.time_scale, 1.0), "engine uses normal timing")
	# Reproduce callbacks whose UI has already been removed. Also inspect the log
	# for errors: Godot runtime errors do not automatically fail assertions.
	var detached_hud = load("res://game/ui/hud/PreparationChecklistHUD.gd").new()
	detached_hud._schedule_checklist_resize()
	detached_hud.free()
	var temporary_label := Label.new()
	add_child(temporary_label)
	temporary_label.free()
	var surviving_label := Label.new()
	surviving_label.text = "Talk to Nanay"
	add_child(surviving_label)
	await get_tree().process_frame
	_check(surviving_label.text == LocalizationManager.translate("Talk to Nanay"),
		"live labels still localize after temporary UI removal")
	surviving_label.queue_free()
	# Keep this runner alive while the actual production scenes replace each other.
	get_tree().current_scene = null
	get_tree().change_scene_to_file(SceneManager.SCENE_PATHS["intro"])
	if not await _wait_until(func(): return _scene_is("intro") and get_tree().current_scene.get("_skip_enabled"),
			"intro reaches skippable narrative", 35.0):
		_finish()
		return
	var skip := InputEventAction.new()
	skip.action = "ui_accept"
	skip.pressed = true
	get_tree().current_scene.call("_input", skip)
	if not await _wait_until(func(): return _scene_is("main_menu"), "intro skip reaches menu"):
		_finish()
		return
	if not await _start_from_menu():
		_finish()
		return
	if not await _test_untimed_opening():
		_finish()
		return
	await _finish_dialogue(get_tree().current_scene.get_node("nanay/Area3D"))
	_check(GameState.house_tasks_unlocked and GameState.get_cash() == GameState.get_departure_cash(), "Nanay unlocks tasks and grants difficulty cash")
	var first_player := get_tree().get_first_node_in_group("player") as PlayerV2
	_check(GlobalTimer.has_started and first_player.get_node("HUDOverlay").top_bar.visible
		and first_player.get_node("PreparationChecklistHUD").checklist_panel.visible, "Nanay reveals the clock and objectives")
	_check(NeedsLog.is_discovered(NeedsLog.Need.FOOD), "preparation retains discoveries from untimed exploration")
	var impacts := AudioManager.get_children().filter(func(node):
		return node is AudioStreamPlayer and node.stream == preload("res://game/audio/Sfx.gd").PREPARATION_START)
	_check(impacts.size() == 1 and impacts[0].process_mode == Node.PROCESS_MODE_ALWAYS and impacts[0].playing,
		"one preparation impact plays through the paused tutorial")
	if not await _dismiss_tutorial():
		_finish()
		return
	await _wait_until(func(): return first_player.has_node("ExitHint"), "departure hint appears after the allowance notice clears")
	_check(first_player.has_node("ExitHint"), "tutorial dismissal shows the above-player departure hint")
	LocalizationManager.set_language("tagalog")
	_check(first_player.get_node("ExitHint").text == LocalizationManager.translate(PlayerV2.EXIT_HINT), "departure hint updates in Tagalog")
	LocalizationManager.set_language("english")
	await _capture("home")
	var cash_before_repeat := GameState.get_cash()
	await _finish_dialogue(get_tree().current_scene.get_node("nanay/Area3D"))
	_check(GameState.get_cash() == cash_before_repeat and get_tree().get_nodes_in_group("tutorial_modal").is_empty(),
		"repeated Nanay conversation grants no additional cash or tutorial")
	var unlocked_door := get_tree().current_scene.get_node("Main_Door")
	var player_position := first_player.global_position
	first_player.global_position = unlocked_door.global_position + Vector3(0, 0.1, 0)
	first_player.velocity = Vector3.ZERO
	var unlocked_map := get_tree().get_first_node_in_group("map_screen")
	await _wait_until(func(): return unlocked_map.visible, "approaching the door opens the map after Nanay", 3.0)
	unlocked_map.close_map()
	first_player.global_position = player_position
	await get_tree().create_timer(0.2).timeout
	await _finish_dialogue(get_tree().current_scene.get_node("Lola/Area3D"))
	_check(NeedsLog.is_discovered(NeedsLog.Need.MEDICINE), "Lola discovers medicine need")
	_check(not GlobalTimer.is_paused, "NPC dialogue releases clock pause")
	var map := get_tree().get_first_node_in_group("map_screen")
	var backpack := get_tree().get_first_node_in_group("backpack_ui")
	var before: int = GlobalTimer.current_minutes
	map.call("open_map")
	await get_tree().create_timer(GlobalTimer.seconds_per_game_minute * 2.0).timeout
	_check(map.visible and not GlobalTimer.is_paused and GlobalTimer.current_minutes > before, "map leaves clock running")
	backpack.call("_toggle")
	before = GlobalTimer.current_minutes
	await get_tree().create_timer(GlobalTimer.seconds_per_game_minute * 2.0).timeout
	_check(backpack.visible and not map.visible and GlobalTimer.current_minutes > before, "backpack closes map and leaves clock running")
	backpack.call("close_backpack")
	for location_id in ["ate_linda", "hardware"]:
		if not await _travel(location_id):
			_finish()
			return
		if location_id == "ate_linda":
			await get_tree().create_timer(1.0).timeout
			var player := get_tree().get_first_node_in_group("player") as CharacterBody3D
			_check(player.is_on_floor(), "Tindahan spawn has supporting collision")
			await _capture("tindahan")
			await _finish_dialogue(get_tree().current_scene.get_node("Ate_Linda/Area3D"))
			_check(ShopUi.is_open(), "Ate Linda dialogue opens the shop")
			await _capture("shop")
			for shop_item: ShopItem in ShopUi._current_shop.items:
				if shop_item.item_data.item_id == "medicine":
					ShopUi._on_buy_pressed(shop_item)
					break
			_check(InventoryManager.get_total_quantity("medicine") == 1, "medicine purchased from Ate Linda")
			ShopUi.close_shop()
	ShopUi.open_shop(load("res://game/resources/shops/HardwareShop.tres"))
	_check(ShopUi.is_open() and GlobalTimer.is_paused, "hardware shop opens and pauses clock")
	var offer: ShopItem = ShopUi._current_shop.items[0]
	var cash_before: int = GameState.get_cash()
	var stock_before: int = offer.stock
	ShopUi._on_buy_pressed(offer)
	_check(InventoryManager.get_total_quantity(offer.item_data.item_id) == 1
		and GameState.get_cash() == cash_before - offer.price and offer.stock == stock_before - 1,
		"purchase updates inventory, cash and stock")
	ShopUi.close_shop()
	_check(not GlobalTimer.is_paused, "shop close releases clock pause")
	if not await _travel("home"):
		_finish()
		return
	_check(SceneManager.get_pending_spawn_id().is_empty(), "return home consumes spawn marker")
	var task := get_tree().current_scene.get_node("MedicineTask")
	await _finish_dialogue(task)
	if not await _wait_until(func(): return task.get("_is_completed") and not task.get("_is_completing"), "medicine task completion finishes"):
		_finish()
		return
	_check(NeedsLog.is_resolved(NeedsLog.Need.MEDICINE) and InventoryManager.get_total_quantity("medicine") == 0,
		"completed task resolves need and consumes medicine")
	await _finish_dialogue(task)
	_check(not task.get("_is_completing") and not GlobalTimer.is_paused, "repeated task interaction does not repeat completion")
	var previous_scene_id: int = get_tree().current_scene.get_instance_id()
	var pause := get_tree().get_first_node_in_group("player").get_node("PauseMenu")
	pause.call("_open")
	_check(get_tree().paused, "pause menu suspends scene tree")
	pause.call("_on_nav_restart")
	if not await _wait_until(func(): return _scene_is("home") and get_tree().current_scene.get_instance_id() != previous_scene_id,
			"pause restart replaces home scene") or not await _wait_for_wake_up():
		_finish()
		return
	_check(GlobalTimer.is_paused and not GlobalTimer.has_started and GlobalTimer.current_minutes == 0 and InventoryManager.inventory.is_empty()
		and not GameState.house_tasks_unlocked and NeedsLog.get_all_resolved().is_empty(), "restart resets to untimed exploration")
	TutorialModal.mark_do_not_show_again()
	await _finish_dialogue(get_tree().current_scene.get_node("nanay/Area3D"))
	await _wait_until(func(): return get_tree().get_first_node_in_group("player").has_node("ExitHint"), "suppressed tutorial still schedules the departure hint")
	_check(not get_tree().paused and not GlobalTimer.is_paused and get_tree().get_nodes_in_group("tutorial_modal").is_empty()
		and get_tree().get_first_node_in_group("player").has_node("ExitHint"), "suppressed tutorial still starts preparation and shows departure hint")
	if OS.get_cmdline_user_args().has("--opening-only"):
		_finish()
		return
	# Fixture triggers the normal storm->ending route without waiting 12 game hours.
	GlobalTimer.force_storm_arrival()
	if not await _wait_until(func(): return _scene_is("ending"), "storm reaches ending"):
		_finish()
		return
	if not await _wait_until(func(): return get_tree().current_scene.get("_awaiting_result_continue"),
			"ending waits on visible score before name prompt", 300.0):
		_finish()
		return
	_check(get_tree().current_scene.get_node("CanvasLayer/ResultPanel").visible
		and not get_tree().current_scene.has_node("LeaderboardNamePrompt"), "score remains readable until player continues")
	var continue_key := InputEventKey.new()
	continue_key.pressed = true
	get_tree().current_scene.call("_input", continue_key)
	if not await _wait_until(func(): return get_tree().current_scene.has_node("LeaderboardNamePrompt"),
			"continue opens score name prompt"):
		_finish()
		return
	var prompt := get_tree().current_scene.get_node("LeaderboardNamePrompt")
	await _capture("ending")
	var name_input := prompt.find_child("NameInput", true, false) as LineEdit
	name_input.text = "Isolated smoke test"
	name_input.text_changed.emit(name_input.text)
	prompt.find_child("SubmitButton", true, false).emit_signal("pressed")
	if not await _wait_until(func(): return _scene_is("main_menu"), "score submission returns to menu"):
		_finish()
		return
	if await _start_from_menu():
		_check(GlobalTimer.is_paused and not GlobalTimer.has_started and GlobalTimer.current_minutes == 0 and InventoryManager.inventory.is_empty(),
			"post-ending second run starts clean with an unstarted clock")
	_finish()
