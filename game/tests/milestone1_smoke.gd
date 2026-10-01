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
			"startup tutorial appears after stand-up"):
		return false
	var tutorial := player.find_child("TutorialModal", true, false) as TutorialModal
	_check(tutorial.visible and get_tree().paused, "tutorial pauses the scene tree")
	tutorial.close()
	await get_tree().process_frame
	return _check(not get_tree().paused and not player.get("_is_input_locked"), "tutorial dismissal restores player input")

func _finish_dialogue(speaker: Node) -> void:
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
	return await _dismiss_tutorial()

func _run() -> void:
	if not _check(OS.get_environment("BAGYONG_ISOLATED_SMOKE") == OS.get_user_data_dir(),
			"explicit isolated userdata path supplied (BAGYONG_ISOLATED_SMOKE)"):
		_finish()
		return
	_check(is_equal_approx(Engine.time_scale, 1.0), "engine uses normal timing")
	# Reproduce callbacks whose UI has already been removed. Also inspect the log
	# for errors: Godot runtime errors do not automatically fail assertions.
	var detached_hud = load("res://game/ui/tasksUI/PreparationChecklistHUD.gd").new()
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
	_check(not GlobalTimer.is_paused, "new run clock is active")
	await _capture("home")
	await _finish_dialogue(get_tree().current_scene.get_node("nanay/Area3D"))
	_check(GameState.house_tasks_unlocked and GameState.get_cash() > 0, "Nanay unlocks tasks and grants cash")
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
	ShopUi.open_shop(load("res://game/resources/items/shops/HardwareShop.tres"))
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
			"pause restart replaces home scene") or not await _dismiss_tutorial():
		_finish()
		return
	_check(not GlobalTimer.is_paused and GlobalTimer.current_minutes < 20 and InventoryManager.inventory.is_empty()
		and not GameState.house_tasks_unlocked and NeedsLog.get_all_resolved().is_empty(), "restart resets run state and resumes clock")
	# Fixture triggers the normal storm->ending route without waiting 12 game hours.
	GlobalTimer.force_storm_arrival()
	if not await _wait_until(func(): return _scene_is("ending"), "storm reaches ending"):
		_finish()
		return
	if not await _wait_until(func(): return get_tree().current_scene.has_node("LeaderboardNamePrompt"),
			"ending completes and requests score name", 300.0):
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
		_check(not GlobalTimer.is_paused and GlobalTimer.current_minutes < 20 and InventoryManager.inventory.is_empty(),
			"post-ending second run starts clean with active clock")
	_finish()
