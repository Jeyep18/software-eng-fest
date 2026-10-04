extends Node

const RULES = preload("res://game/ui/lotto/ScratchLottoRules.gd")

var _checks: int = 0
var _failures: int = 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	if OS.get_environment("BAGYONG_ISOLATED_SMOKE") != OS.get_user_data_dir():
		push_error("Scratch lotto regression requires isolated userdata.")
		get_tree().quit(1)
		return
	if OS.get_cmdline_user_args().has("--visual-only"):
		await _test_visuals()
		print("Scratch lotto visual: %d checks, %d failures" % [_checks, _failures])
		get_tree().quit(0 if _failures == 0 else 1)
		return
	_test_rules()
	await _test_ui()
	print("Scratch lotto regression: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)


func _test_rules() -> void:
	var weight_total := 0
	for weight in RULES.WEIGHTS:
		weight_total += weight
	_check(RULES.FRUIT_IDS.size() == 8 and RULES.PRIZES.size() == 8 and weight_total == 100, "eight fruit weights total 100")
	var first_rng := RandomNumberGenerator.new()
	var second_rng := RandomNumberGenerator.new()
	first_rng.seed = 1428
	second_rng.seed = 1428
	var first_ticket: Array[String] = RULES.roll_ticket(first_rng)
	var second_ticket: Array[String] = RULES.roll_ticket(second_rng)
	_check(first_ticket == second_ticket and first_ticket.size() == 6, "seeded rolls are reproducible six-well tickets")
	var all_valid := true
	for fruit in first_ticket:
		all_valid = all_valid and RULES.FRUIT_IDS.has(fruit)
	_check(all_valid, "every rolled fruit has a supported icon and prize")
	_check(RULES.calculate_payout(["apple", "apple", "apple", "banana", "orange", "grapes"]) == 180, "top row pays")
	_check(RULES.calculate_payout(["apple", "banana", "orange", "raspberry", "raspberry", "raspberry"]) == 5000, "bottom row pays")
	_check(RULES.calculate_payout(["apple", "apple", "apple", "peach", "peach", "peach"]) == 2680, "two rows add prizes")
	_check(RULES.calculate_payout(["apple", "banana", "apple", "orange", "apple", "grapes"]) == 0, "three fruit outside one row do not pay")
	_check(RULES.calculate_payout(["apple", "apple", "apple"]) == 0, "incomplete tickets do not pay")
	for index in RULES.FRUIT_IDS.size():
		var fruit: String = RULES.FRUIT_IDS[index]
		var prize: int = RULES.PRIZES[index]
		_check(RULES.calculate_payout([fruit, fruit, fruit, "apple", "banana", "orange"]) == prize,
			"top row pays %s prize" % fruit)
		_check(RULES.calculate_payout(["apple", "banana", "orange", fruit, fruit, fruit]) == prize,
			"bottom row pays %s prize" % fruit)
	var row_probability := 0.0
	var expected_payout := 0.0
	for index in RULES.WEIGHTS.size():
		var triple_probability: float = pow(float(RULES.WEIGHTS[index]) / 100.0, 3.0)
		row_probability += triple_probability
		expected_payout += 2.0 * triple_probability * RULES.PRIZES[index]
	_check(absf(1.0 - pow(1.0 - row_probability, 2.0) - 0.086079296) < 0.0000001, "ticket win probability matches design")
	_check(absf(expected_payout - 22.13084) < 0.0001, "expected payout matches design")


func _test_ui() -> void:
	GameState.reset()
	GlobalTimer.start_fresh()
	var ui := ScratchLottoUI.new()
	add_child(ui)
	await get_tree().process_frame
	ui.open_ui()
	_check(ui.is_open() and not GlobalTimer.is_paused, "opening lotto leaves the game clock running")
	var minutes_before := GlobalTimer.current_minutes
	GlobalTimer.seconds_per_game_minute = 0.04
	await get_tree().create_timer(0.14).timeout
	_check(GlobalTimer.current_minutes > minutes_before, "game minutes advance while lotto is open")
	_check(not ui.buy_ticket() and GameState.get_cash() == 0, "insufficient cash creates no ticket")

	GameState.add_cash(50)
	SceneManager.storm_transition_pending = true
	_check(not ui.buy_ticket() and GameState.get_cash() == 50, "storm transition blocks purchase before charging")
	SceneManager.storm_transition_pending = false
	ui._rng.seed = 1428
	_check(ui.buy_ticket() and GameState.get_cash() == 0, "buy charges exactly one ticket")
	var first_expected: int = RULES.calculate_payout(ui._ticket)
	_check(not ui.buy_ticket() and GameState.get_cash() == 0, "a covered ticket blocks another purchase")
	var first_slot: ScratchLottoSlot = ui._slots[0]
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(0.0, first_slot.size.y * 0.1)
	first_slot._gui_input(press)
	for row in 5:
		for horizontal_fraction in [0.0, 1.0]:
			var motion := InputEventMouseMotion.new()
			motion.button_mask = MOUSE_BUTTON_MASK_LEFT
			motion.position = Vector2(first_slot.size.x * horizontal_fraction, first_slot.size.y * (0.1 + row * 0.18))
			first_slot._gui_input(motion)
	_check(first_slot.is_revealed(), "mouse drag erases half the foil and reveals one well")
	ui.reveal_all()
	_check(GameState.get_cash() == first_expected, "resolving credits the calculated prize")
	ui.reveal_all()
	_check(GameState.get_cash() == first_expected, "reveal all cannot pay twice")

	GameState.add_cash(50)
	var cash_before_second := GameState.get_cash()
	_check(ui.buy_ticket() and GameState.get_cash() == cash_before_second - 50, "buy again replaces only a settled ticket")
	var second_expected: int = RULES.calculate_payout(ui._ticket)
	ui.request_close()
	_check(ui.is_open() and GameState.get_cash() == cash_before_second - 50 + second_expected, "first close reveals and resolves an unfinished ticket")
	ui.request_close()
	_check(not ui.is_open(), "second close exits after showing the result")

	ui.open_ui()
	GameState.add_cash(50)
	ui.buy_ticket()
	var third_expected: int = RULES.calculate_payout(ui._ticket)
	var after_third_purchase := GameState.get_cash()
	ui._on_storm_arrived()
	_check(not ui.is_open() and GameState.get_cash() == after_third_purchase + third_expected, "storm interruption resolves a paid ticket")
	ui._on_storm_arrived()
	_check(GameState.get_cash() == after_third_purchase + third_expected, "repeated storm close cannot pay twice")

	ui.open_ui()
	GameState.add_cash(50)
	ui.buy_ticket()
	var final_expected: int = RULES.calculate_payout(ui._ticket)
	var after_final_purchase := GameState.get_cash()
	ui.queue_free()
	await get_tree().process_frame
	_check(GameState.get_cash() == after_final_purchase + final_expected, "scene exit settles a paid ticket")
	GlobalTimer.reset()


func _test_visuals() -> void:
	GameState.reset()
	GameState.add_cash(650)
	VisualSettings.set_vhs_crt_enabled(true)
	SceneManager.has_played_opening = true
	SceneManager.current_location = "pharmacy"
	var pharmacy := preload("res://game/scenes/locations/pharmacy.tscn").instantiate()
	add_child(pharmacy)
	var player := pharmacy.get_node("playerv2") as Node3D
	player.global_position = Vector3(2.18, 0.6, -7.5)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var lottohan := pharmacy.get_node("Lottohan") as Interactable
	_check(lottohan.get_overlapping_bodies().has(player), "storefront zone overlaps the player at the counter")
	_check(player.get("_nearby_interactables").has(lottohan), "player discovers the storefront interaction")
	var ui := pharmacy.get_node("Lottohan/LottoUI") as ScratchLottoUI
	lottohan.interact()
	_check(ui.is_open() and lottohan.is_showing, "storefront interaction opens lotto")
	_check(player.get("_is_movement_locked"), "lotto locks player movement")
	_check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "lotto owns a visible cursor")
	var map_screen := player.get_node("MapScreen") as CanvasLayer
	map_screen.call("open_map")
	_check(not map_screen.visible, "map cannot open over lotto")
	var backpack := get_tree().get_first_node_in_group("backpack_ui") as CanvasLayer
	backpack.call("_toggle")
	_check(not backpack.visible, "backpack cannot open over lotto")
	_check(ui.buy_ticket(), "visual ticket purchase succeeds")
	await get_tree().process_frame
	get_window().mode = Window.MODE_WINDOWED
	await get_tree().process_frame
	for window_size in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		get_window().size = window_size
		await get_tree().process_frame
		await get_tree().process_frame
		_check(get_window().size == window_size, "window resized to %s" % window_size)
		print("Scratch lotto display: mode=", get_window().mode, " window=", get_window().size,
			" minimum=", get_window().min_size, " viewport=", get_viewport().get_visible_rect().size,
			" vhs=", VisualSettings.is_vhs_crt_enabled())
		for language in ["english", "tagalog"]:
			LocalizationManager.set_language(language)
			for scale_percent in [100, 175]:
				VisualSettings.ui_scale_percent = scale_percent
				await get_tree().process_frame
				await RenderingServer.frame_post_draw
				var capture := get_viewport().get_texture().get_image()
				if capture.get_size() != window_size:
					capture.resize(window_size.x, window_size.y, Image.INTERPOLATE_BILINEAR)
				var image_path := "user://scratch_lotto_%s_%d_%d.png" % [language, scale_percent, window_size.x]
				_check(capture.save_png(image_path) == OK, "saved %s at %d%% in %s" % [language, scale_percent, window_size])
				print("Scratch lotto capture: ", ProjectSettings.globalize_path(image_path))
	var pause_menu := player.get_node("PauseMenu") as CanvasLayer
	var escape := InputEventAction.new()
	escape.action = &"ui_cancel"
	escape.pressed = true
	pause_menu.call("_input", escape)
	_check(ui.is_open() and ui._settled and not pause_menu.visible, "first Escape reveals result without pausing")
	await RenderingServer.frame_post_draw
	var result_path := "user://scratch_lotto_result.png"
	_check(get_viewport().get_texture().get_image().save_png(result_path) == OK, "saved revealed result")
	print("Scratch lotto capture: ", ProjectSettings.globalize_path(result_path))
	pause_menu.call("_input", escape)
	_check(not ui.is_open() and not pause_menu.visible, "second Escape closes lotto without pausing")
	_check(not player.get("_is_movement_locked"), "closing lotto restores movement")
	_check(not lottohan.is_showing, "closing lotto restores storefront prompt")
	pharmacy.queue_free()
	LocalizationManager.set_language("english")
	VisualSettings.reset_visual_settings()


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("Scratch lotto regression: " + description)
