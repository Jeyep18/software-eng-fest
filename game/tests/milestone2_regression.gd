extends Node
## Run in an imported disposable copy with isolated APPDATA, like milestone1_smoke.

var _checks: int = 0
var _failures: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()

func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print("MILESTONE2 ", "PASS " if condition else "FAIL ", description)

func _run() -> void:
	if OS.get_environment("BAGYONG_ISOLATED_SMOKE") != OS.get_user_data_dir():
		push_error("Milestone 2 requires explicit isolated userdata.")
		get_tree().quit(1)
		return
	if OS.get_cmdline_user_args().has("--visual-only"):
		get_tree().current_scene = null
		TutorialModal.mark_do_not_show_again()
		await _test_visuals()
		print("Milestone 2 visual: %d checks, %d failures" % [_checks, _failures])
		get_tree().quit(0 if _failures == 0 else 1)
		return
	await _test_localization()
	await _test_pause_owners()
	_test_shop()
	await _test_nestor()
	# Keep the runner alive through production scene replacements.
	get_tree().current_scene = null
	TutorialModal.mark_do_not_show_again()
	if not OS.get_cmdline_user_args().has("--unit-only"):
		await _test_lifecycle()
	print("Milestone 2 regression: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)

func _test_localization() -> void:
	LocalizationManager.set_language("english")
	var temporary_label := Label.new()
	add_child(temporary_label)
	temporary_label.free()
	var label := Label.new()
	label.text = "Talk to Nanay"
	add_child(label)
	await get_tree().process_frame
	LocalizationManager.set_language("tagalog")
	_check(label.text == LocalizationManager.translate("Talk to Nanay") and label.text != "Talk to Nanay", "existing label switches to Tagalog")
	LocalizationManager.set_language("english")
	_check(label.text == "Talk to Nanay", "label switches back to English")
	label.text = "Dynamic value: 123"
	LocalizationManager.set_language("tagalog")
	_check(label.text == "Dynamic value: 123", "dynamic text is not replaced by stale translation")
	label.text = "Talk to Nanay"
	LocalizationManager.localize_tree(label)
	_check(label.text == LocalizationManager.translate("Talk to Nanay"), "dynamic source can become translatable again")
	var button := Button.new()
	button.text = "Resume"
	add_child(button)
	await get_tree().process_frame
	_check(button.text == "Resume", "authored English action button remains English in Tagalog")
	button.queue_free()
	label.queue_free()
	LocalizationManager.set_language("english")

func _test_pause_owners() -> void:
	GlobalTimer.start_fresh()
	var first := Node.new()
	var second := Node.new()
	add_child(first)
	add_child(second)
	GlobalTimer.pause_timer(first)
	GlobalTimer.pause_timer(first)
	GlobalTimer.pause_timer(second)
	GlobalTimer.resume_timer(first)
	_check(GlobalTimer.is_paused, "one owner cannot release another owner's pause")
	second.queue_free()
	await get_tree().process_frame
	_check(not GlobalTimer.is_paused, "freed owner releases its pause")
	GlobalTimer.pause_timer(first)
	GlobalTimer.reset()
	first.queue_free()
	await get_tree().process_frame
	_check(GlobalTimer.is_paused and GlobalTimer._pause_stack == 0, "old owner exit cannot unpause reset timer")
	GlobalTimer.start_fresh()
	GlobalTimer.pause_timer()
	GlobalTimer.resume_timer()
	_check(not GlobalTimer.is_paused, "anonymous legacy pause API still works")

func _test_shop() -> void:
	GlobalTimer.start_fresh()
	ShopUi.reset()
	var shop: ShopData = load("res://game/resources/items/shops/HardwareShop.tres")
	ShopUi.open_shop(shop)
	ShopUi.open_shop(shop)
	InventoryManager.reset()
	GameState.add_cash(10000)
	var offer: ShopItem = ShopUi._current_shop.items[0]
	var initial_stock: int = offer.stock
	ShopUi._on_buy_pressed(offer)
	_check(offer.stock == initial_stock - 1, "purchase consumes finite stock")
	ShopUi.close_shop()
	ShopUi.open_shop(shop)
	_check(ShopUi._current_shop.items[0].stock == initial_stock - 1, "stock persists when shop reopens")
	offer.stock = 0
	var cash_before: int = GameState.get_cash()
	ShopUi._on_buy_pressed(offer)
	_check(GameState.get_cash() == cash_before, "repeated stale purchase cannot buy exhausted stock")
	ShopUi.close_shop()
	_check(not GlobalTimer.is_paused, "repeated shop open owns one pause")
	ShopUi.reset()
	ShopUi.open_shop(shop)
	_check(ShopUi._current_shop.items[0].stock == initial_stock and shop.items[0].stock == initial_stock, "reset restores stock without changing shared resource")
	ShopUi.close_shop()
	GlobalTimer.reset()

func _test_nestor() -> void:
	InventoryManager.reset()
	SideQuestLog.reset()
	var npc_scene: Node = load("res://game/entities/quest_npcs/mang_nestor.tscn").instantiate()
	add_child(npc_scene)
	var nestor: Node = npc_scene.get_node("Area3D")
	nestor._start_quest()
	var starting_cash: int = GameState.get_cash()
	nestor._start_quest()
	_check(GameState.get_cash() == starting_cash, "quest advance money given once")
	var chicken := ItemData.new()
	chicken.item_id = "half_chicken"
	InventoryManager.add_item(chicken)
	for i in range(6):
		var filler := ItemData.new()
		filler.item_id = "filler_%d" % i
		InventoryManager.add_item(filler)
	_check(nestor._pick_sequence() == nestor.complete_sequence, "full backpack allows chicken turn-in dialogue")
	var cash_before: int = GameState.get_cash()
	nestor._complete_quest()
	_check(InventoryManager.get_total_quantity("tarp") == 1 and not InventoryManager.has_item_with_id("half_chicken"), "full backpack exchanges chicken for tarp")
	_check(GameState.get_cash() == cash_before + nestor.sukli_amount, "quest pays change once")
	var completed_cash: int = GameState.get_cash()
	InventoryManager.remove_item(1)
	InventoryManager.add_item(chicken)
	nestor._complete_quest()
	_check(GameState.get_cash() == completed_cash and InventoryManager.get_total_quantity("tarp") == 1
		and InventoryManager.has_item_with_id("half_chicken"), "repeated turn-in cannot consume another chicken or duplicate reward")
	_check(nestor._pick_sequence() == nestor.done_sequence, "completed quest selects done dialogue on return")
	nestor.show_choice_prompt("Give the Half Chicken to Mang Nestor?", "Give", "Keep it")
	_check(GlobalTimer.is_paused, "quest choice owns timer pause")
	nestor.interact()
	_check(not nestor._is_showing and GlobalTimer.is_paused, "repeat interaction cannot reopen dialogue over quest choice")
	LocalizationManager.set_language("tagalog")
	_check(nestor._choice_body.text == "Ibigay ang Half Chicken kay Mang Nestor?", "open quest choice updates to Tagalog")
	nestor.show_choice_prompt("Give PHP %d?", "Give", "Sorry", [20])
	_check(nestor._choice_body.text == "Magbigay ng PHP 20?", "formatted choice translates before substitution")
	LocalizationManager.set_language("english")
	_check(nestor._choice_body.text == "Give PHP 20?", "formatted choice updates back to English")
	npc_scene.queue_free()
	await get_tree().process_frame
	_check(not GlobalTimer.is_paused, "removing quest choice releases its pause without accepting it")

func _scene_is(scene_id: String) -> bool:
	return get_tree().current_scene != null and get_tree().current_scene.scene_file_path == SceneManager.SCENE_PATHS[scene_id]

func _wait_until(condition: Callable, description: String, seconds: float = 12.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await get_tree().create_timer(0.05, true).timeout
	var passed: bool = condition.call()
	_check(passed, description)
	return passed

func _fresh_home() -> bool:
	get_tree().paused = false
	SceneManager.reset()
	ShopUi.reset()
	GlobalTimer.reset()
	StormEnroachment.reset()
	InventoryManager.reset()
	SideQuestLog.reset()
	NeedsLog.reset()
	GameState.reset()
	SceneManager.has_played_opening = true
	SceneManager.load_scene("home")
	if not await _wait_until(func(): return _scene_is("home") and TransitionOverlay.overlay.color.a < 0.01, "fresh home finishes fade"):
		return false
	GlobalTimer.start_fresh()
	GameState.house_tasks_unlocked = true
	return true

func _ending(description: String) -> bool:
	if not await _wait_until(func(): return _scene_is("ending"), description):
		return false
	await get_tree().create_timer(1.5, true).timeout
	_check(_scene_is("ending") and not SceneManager.is_travelling and SceneManager.get_pending_spawn_id().is_empty(), "ending remains final destination with no pending spawn")
	return true

func _test_lifecycle() -> void:
	if not await _fresh_home():
		return
	var hud := get_tree().get_first_node_in_group("preparation_checklist_hud")
	var row: Control = hud._make_objective_row("removed_test", "Talk to Nanay")
	hud.checklist_items.add_child(row)
	hud._remove_objective_row(row, true)
	row.free()
	await get_tree().create_timer(1.3).timeout
	_check(not hud._objective_row_tweens.has("removed_test"), "freed animated objective callback clears bookkeeping safely")
	GlobalTimer.current_minutes = 719
	var travel_events: Array[String] = []
	SceneManager.travel_completed.connect(func(location: String): travel_events.append(location))
	SceneManager.travel_to("ate_linda", "", 2)
	if not await _ending("travel cost crossing deadline reaches ending"):
		return
	_check(travel_events.is_empty(), "deadline travel never emits successful arrival")
	if not await _fresh_home():
		return
	GlobalTimer.current_minutes = 710
	StormEnroachment._set_state("hardware", "danger")
	SceneManager.travel_to("hardware", "", 1)
	if not await _ending("danger penalty crossing deadline reaches ending"):
		return
	_check(travel_events.is_empty(), "danger penalty cannot start a competing travel")
	if not await _fresh_home():
		return
	SceneManager.travel_to("ate_linda", "", 2)
	await get_tree().create_timer(0.1).timeout
	GlobalTimer.force_storm_arrival()
	if not await _ending("storm during departure fade reaches ending"):
		return
	_check(travel_events.is_empty(), "interrupted departure never emits arrival")
	if not await _fresh_home():
		return
	SceneManager.travel_to("ate_linda", "", 1)
	if not await _wait_until(func(): return _scene_is("ate_linda") and SceneManager.is_travelling, "arrival scene loads before travel fade completes"):
		return
	GlobalTimer.force_storm_arrival()
	if not await _ending("storm during arrival fade reaches ending"):
		return
	_check(travel_events.is_empty(), "interrupted arrival never emits travel completion")
	# A reset must invalidate a storm coroutine even after it starts fading.
	if not await _fresh_home():
		return
	GlobalTimer.force_storm_arrival()
	await get_tree().create_timer(0.1).timeout
	if not await _fresh_home():
		return
	await get_tree().create_timer(1.0).timeout
	_check(_scene_is("home") and not GlobalTimer.is_paused, "reset cancels stale storm transition")
	SceneManager.travel_to("ate_linda", "", 2)
	await get_tree().create_timer(0.1).timeout
	if not await _fresh_home():
		return
	await get_tree().create_timer(1.0).timeout
	_check(_scene_is("home") and travel_events.is_empty(), "reset cancels stale travel and completion signal")
	# Actual task completion, including the window override, at the deadline.
	for task_name in ["MedicineTask", "Window"]:
		if not await _fresh_home():
			return
		var task: TaskObject = get_tree().current_scene.get_node(task_name)
		for item_id: String in task.required_item_ids:
			InventoryManager.add_item(load("res://game/resources/items/%s.tres" % item_id))
		GlobalTimer.current_minutes = 719
		task._complete_task()
		if not await _ending("task cost crossing deadline: " + task_name):
			return
		var completed: bool = NeedsLog.is_resolved(NeedsLog.Need.MEDICINE) if task_name == "MedicineTask" else NeedsLog.is_window_boarded("bedroom_window")
		_check(completed, "deadline preserves committed result: " + task_name)
	if not await _fresh_home():
		return
	var interrupted_task: TaskObject = get_tree().current_scene.get_node("MedicineTask")
	InventoryManager.add_item(load("res://game/resources/items/medicine.tres"))
	interrupted_task._complete_task()
	await get_tree().create_timer(0.1).timeout
	GlobalTimer.force_storm_arrival()
	if not await _ending("forced storm cancels uncommitted task"):
		return
	_check(InventoryManager.has_item_with_id("medicine") and not NeedsLog.is_resolved(NeedsLog.Need.MEDICINE), "canceled task keeps supplies and remains unresolved")
	if not await _fresh_home():
		return
	var smoke_scene: Node = load("res://game/entities/quest_npcs/smoke_break_npc.tscn").instantiate()
	get_tree().current_scene.add_child(smoke_scene)
	GlobalTimer.current_minutes = 719
	smoke_scene.get_node("Area3D")._on_choice_accepted()
	if not await _ending("smoke break cost reaches ending without a competing fade"):
		return
	_check(GameState.tindahan_smoke_break_taken, "smoke break remains a one-time choice")
	# Modal/scene teardown must not carry pauses into a replacement scene.
	for mode in ["dialogue", "shop", "map", "backpack", "pause", "tutorial"]:
		if not await _fresh_home():
			return
		var player := get_tree().get_first_node_in_group("player")
		match mode:
			"dialogue": get_tree().current_scene.get_node("nanay/Area3D").interact()
			"shop": ShopUi.open_shop(load("res://game/resources/items/shops/HardwareShop.tres"))
			"map": get_tree().get_first_node_in_group("map_screen").open_map()
			"backpack": get_tree().get_first_node_in_group("backpack_ui")._toggle()
			"pause": player.get_node("PauseMenu")._open()
			"tutorial":
				var tutorial: TutorialModal = load("res://game/ui/tutorial/TutorialModal.tscn").instantiate()
				player.add_child(tutorial)
				tutorial.open()
		if mode in ["map", "backpack"]:
			_check(not GlobalTimer.is_paused, mode + " still leaves timer running")
		GlobalTimer.force_storm_arrival()
		if not await _ending("forced storm during " + mode):
			return
		_check(not get_tree().paused and not ShopUi.is_open(), "ending releases modal/tree ownership: " + mode)
	# Travel return must retain a finished task and shop stock.
	if not await _fresh_home():
		return
	NeedsLog.resolve(NeedsLog.Need.MEDICINE)
	SceneManager.travel_to("hardware", "", 1)
	if not await _wait_until(func(): return _scene_is("hardware") and not SceneManager.is_travelling, "normal travel reaches hardware"):
		return
	GameState.add_cash(1000)
	ShopUi.open_shop(load("res://game/resources/items/shops/HardwareShop.tres"))
	var offer: ShopItem = ShopUi._current_shop.items[0]
	var stock: int = offer.stock
	ShopUi._on_buy_pressed(offer)
	ShopUi.close_shop()
	SceneManager.travel_to("home", "", 1)
	if not await _wait_until(func(): return _scene_is("home") and not SceneManager.is_travelling, "return home completes"):
		return
	_check(get_tree().current_scene.get_node("MedicineTask")._is_completed, "resolved task survives return visit")
	SceneManager.travel_to("hardware", "", 1)
	if not await _wait_until(func(): return _scene_is("hardware") and not SceneManager.is_travelling, "return to hardware completes"):
		return
	ShopUi.open_shop(load("res://game/resources/items/shops/HardwareShop.tres"))
	_check(ShopUi._current_shop.items[0].stock == stock - 1, "stock survives scene return")
	ShopUi.close_shop()

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://milestone2_%s.png" % label)

func _test_visuals() -> void:
	for language in ["english", "tagalog"]:
		for scale_percent in [100, 175]:
			VisualSettings.set_ui_scale_percent(scale_percent)
			LocalizationManager.set_language(language)
			if not await _fresh_home():
				return
			var suffix := "%s_%d" % [language, scale_percent]
			var map := get_tree().get_first_node_in_group("map_screen")
			StormEnroachment._set_state("hardware", "danger")
			map.open_map()
			map._on_node_selected("hardware")
			await _capture("map_" + suffix)
			var time_label: Label = map.confirm_time
			_check(map.confirm_panel.get_global_rect().encloses(time_label.get_global_rect()), "map travel text stays in confirmation panel " + suffix)
			_check(map.panel.get_global_rect().encloses(map.confirm_panel.get_global_rect()), "map confirmation stays on screen " + suffix)
			map.close_map()
			ShopUi.open_shop(load("res://game/resources/items/shops/HardwareShop.tres"))
			await _capture("shop_" + suffix)
			ShopUi.close_shop()
			var npc_scene: Node = load("res://game/entities/quest_npcs/mang_nestor.tscn").instantiate()
			get_tree().current_scene.add_child(npc_scene)
			var nestor: Node = npc_scene.get_node("Area3D")
			nestor.show_choice_prompt("Accept Mang Nestor's PHP 150 and buy Half Chicken from Go To Chooks beside the Pharmacy?", "Accept", "Not now")
			await _capture("quest_" + suffix)
			nestor._close_choice_prompt()
			npc_scene.queue_free()
			var backpack := get_tree().get_first_node_in_group("backpack_ui")
			InventoryManager.add_item(load("res://game/resources/items/working_flashlight.tres"))
			backpack._toggle()
			backpack._on_slot_clicked(0)
			await _capture("backpack_" + suffix)
			_check(backpack.info_name.size.y > 1.0, "selected item name remains visible " + suffix)
			backpack.close_backpack()
	VisualSettings.set_ui_scale_percent(140)
	LocalizationManager.set_language("english")
