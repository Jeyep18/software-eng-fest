extends Node

const TUTORIAL = preload("res://game/ui/tutorial/TutorialModal.tscn")
var _checks := 0
var _failures := 0
var _close_count := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()

func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("TUTORIAL FAIL: " + description)

func _settle() -> void:
	for index in 4:
		await get_tree().process_frame

func _press_accept() -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_ENTER
	key.pressed = true
	Input.parse_input_event(key)
	await get_tree().process_frame
	key.pressed = false
	Input.parse_input_event(key)
	await _settle()

func _run() -> void:
	if OS.get_environment("BAGYONG_ISOLATED_SMOKE") != OS.get_user_data_dir():
		push_error("Tutorial regression requires isolated user data.")
		get_tree().quit(1)
		return
	_test_instruction_copy()
	await _run_entry_paths()
	if OS.get_cmdline_user_args().has("--entry-only"):
		print("Tutorial entry regression: %d checks, %d failures" % [_checks, _failures])
		get_tree().quit(0 if _failures == 0 else 1)
		return
	LocalizationManager.set_language("english")
	var source := Button.new()
	source.text = "Tutorial"
	add_child(source)
	source.grab_focus()
	var tutorial := TUTORIAL.instantiate() as TutorialModal
	add_child(tutorial)
	_check(tutorial.PAGES.size() == 5 and tutorial.find_children("*", "ScrollContainer", true, false).is_empty(), "five pages replace the scrolling tutorial")
	tutorial.open(true, true, func(): _close_count += 1)
	await _settle()
	_check_layout(tutorial, "standalone first open before paging")
	_check(tutorial._page_index == 0 and tutorial._counter.text == "1 / 5" and tutorial._back_button.disabled, "opening begins on page one with Back disabled")
	_check(get_tree().paused and CursorState.is_requesting_visible(tutorial) and tutorial._next_button.has_focus(), "opening owns pause, cursor and keyboard focus")
	_check(tutorial._next_button.find_next_valid_focus() == tutorial._do_not_show_button and tutorial._do_not_show_button.find_prev_valid_focus() == tutorial._next_button, "first-page focus stays inside visible actions")
	await _press_accept()
	_check(tutorial.visible and tutorial._page_index == 1 and get_tree().paused, "Enter advances the focused Next button")
	for page in range(2, 5):
		tutorial._next_button.pressed.emit()
		_check(tutorial.visible and tutorial._page_index == page and get_tree().paused, "Next advances without closing or unpausing page %d" % (page + 1))
	_check(tutorial._next_button.text == "Done" and tutorial._counter.text == "5 / 5", "last page names the closing action")
	tutorial._back_button.pressed.emit()
	_check(tutorial._page_index == 3 and tutorial.visible, "Back returns to previous page")
	tutorial._next_button.pressed.emit()
	tutorial._next_button.pressed.emit()
	_check(not tutorial.visible and not get_tree().paused and not CursorState.is_requesting_visible(tutorial) and _close_count == 1, "Done releases ownership and calls completion once")
	_check(source.has_focus(), "closing restores the prior control focus")
	tutorial.close()
	_check(_close_count == 1, "duplicate close cannot repeat completion")
	tutorial.open(false, true)
	_check(tutorial._page_index == 0 and not tutorial._do_not_show_button.visible, "reopening resets to page one and applies suppression visibility")
	var cancel := InputEventAction.new()
	cancel.action = "ui_cancel"
	cancel.pressed = true
	tutorial._unhandled_input(cancel)
	_check(not tutorial.visible and not get_tree().paused, "Escape closes early and releases its pause")
	get_tree().paused = true
	tutorial.open(false, false)
	tutorial.close()
	_check(get_tree().paused, "Pause-menu replay preserves the menu's pause")
	tutorial.open(false, true)
	tutorial.close()
	_check(get_tree().paused, "closing preserves a pause that predates the tutorial")
	get_tree().paused = false
	tutorial.open(false, true)
	tutorial.queue_free()
	await _settle()
	_check(not get_tree().paused and not is_instance_valid(tutorial), "scene teardown releases an open tutorial pause")
	tutorial = TUTORIAL.instantiate() as TutorialModal
	add_child(tutorial)
	tutorial.open(true, true)
	tutorial._do_not_show_button.pressed.emit()
	_check(not TutorialModal.should_show_on_start() and not tutorial.visible and not get_tree().paused, "session suppression closes and prevents the next automatic tutorial")
	tutorial.open(false, true)
	var english_title := tutorial._title.text
	LocalizationManager.set_language("tagalog")
	_check(tutorial._title.text != english_title and tutorial._title.text == "Bago dumating ang bagyo", "open tutorial retranslates immediately")
	for scale_percent in [100, 140, 175]:
		VisualSettings.set_ui_scale_percent(scale_percent)
		for language in ["english", "tagalog"]:
			LocalizationManager.set_language(language)
			for page in 5:
				tutorial._page_index = page
				tutorial._refresh_page()
				await _settle()
				_check_layout(tutorial, "%s %d%% page %d" % [language, scale_percent, page + 1])
				if OS.get_cmdline_user_args().has("--capture") and DisplayServer.get_name() != "headless":
					await RenderingServer.frame_post_draw
					get_viewport().get_texture().get_image().save_png("user://tutorial_%s_%d_page%d.png" % [language, scale_percent, page + 1])
	var original_canvas_size := get_window().content_scale_size
	get_window().content_scale_size = Vector2i(1280, 720)
	for language in ["english", "tagalog"]:
		LocalizationManager.set_language(language)
		for page in 5:
			tutorial._page_index = page
			tutorial._refresh_page()
			await _settle()
			_check_layout(tutorial, "compact canvas %s page %d" % [language, page + 1])
	get_window().content_scale_size = original_canvas_size
	tutorial.close()
	tutorial.free()
	TutorialModal._hidden_for_session = false
	source.free()
	print("Tutorial paging regression: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)

func _test_instruction_copy() -> void:
	var previous_language := LocalizationManager.get_language()
	for language in ["english", "tagalog"]:
		LocalizationManager.set_language(language)
		var before := LocalizationManager.translate_key("tutorial.before.body")
		var shop := LocalizationManager.translate_key("tutorial.shop.body").to_lower()
		var finish := LocalizationManager.translate_key("tutorial.finish.body").to_lower()
		_check(before.contains("6 PM" if language == "english" else "alas-sais"), "opening names the storm deadline in " + language)
		_check(shop.contains("completed tasks" if language == "english" else "gawain") and shop.contains("time" if language == "english" else "oras"), "tutorial explains travel and task time costs in " + language)
		_check(shop.contains("cash" if language == "english" else "pera") and shop.contains("clock" if language == "english" else "orasan"), "tutorial connects the budget and running clock in " + language)
		_check(finish.contains("4 cans" if language == "english" else "4 na de lata") and not finish.contains("chicken") and not finish.contains("manok"), "tutorial keeps the food goal to four cans in " + language)
	LocalizationManager.set_language(previous_language)

func _run_entry_paths() -> void:
	var original_canvas_size := get_window().content_scale_size
	var original_aspect := get_window().content_scale_aspect
	var original_scale := VisualSettings.get_ui_scale_percent()
	var original_language := LocalizationManager.get_language()
	var original_paused := get_tree().paused
	# Headless windows otherwise expand the logical canvas to a square.
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	get_tree().paused = false
	for entry in ["main_menu", "pause_menu"]:
		var scene_path := "res://game/scenes/main_menu/Main_Menu1.tscn" if entry == "main_menu" else "res://game/ui/pause/PauseMenu.tscn"
		var parent := load(scene_path).instantiate() as Node
		add_child(parent)
		if entry == "pause_menu":
			parent._open()
			await parent._panel_tween.finished
		var source: Button = parent.tutorial_button if entry == "main_menu" else parent.nav_tutorial
		for canvas_size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
			get_window().content_scale_size = canvas_size
			await _settle()
			_check(get_viewport().get_visible_rect().size == Vector2(canvas_size), "entry matrix uses the requested logical canvas")
			for language in ["english", "tagalog"]:
				LocalizationManager.set_language(language)
				for scale_percent in [100, 140, 175]:
					VisualSettings.set_ui_scale_percent(scale_percent)
					await _settle()
					source.grab_focus()
					var was_paused := get_tree().paused
					if entry == "main_menu":
						parent._on_tutorial_pressed()
					else:
						parent._on_nav_tutorial()
					var tutorial := get_tree().get_first_node_in_group("tutorial_modal") as TutorialModal
					var label := "%s %s %d%% %s" % [entry, language, scale_percent, canvas_size]
					_check(tutorial != null, "real entry creates a fresh tutorial: " + label)
					if tutorial == null:
						continue
					await get_tree().process_frame
					_check_layout(tutorial, "first processed frame " + label)
					_check(tutorial._page_index == 0 and tutorial._next_button.has_focus() and CursorState.is_requesting_visible(tutorial), "fresh entry starts on page one with focus and cursor: " + label)
					await _settle()
					for page in 5:
						_check_layout(tutorial, "%s page %d" % [label, page + 1])
						if OS.get_cmdline_user_args().has("--capture") and DisplayServer.get_name() != "headless":
							await RenderingServer.frame_post_draw
							get_viewport().get_texture().get_image().save_png("user://tutorial_entry_%s_%s_%d_%dx%d_page%d.png" % [entry, language, scale_percent, canvas_size.x, canvas_size.y, page + 1])
						if page < 4:
							tutorial._next_button.pressed.emit()
							await _settle()
					tutorial._next_button.pressed.emit()
					_check(not tutorial.visible and get_tree().paused == was_paused and not CursorState.is_requesting_visible(tutorial) and source.has_focus(), "Done restores the entry's pause and focus and releases cursor: " + label)
					await _settle()
					_check(not is_instance_valid(tutorial), "real entry frees its closed modal: " + label)
		get_tree().paused = false
		parent.queue_free()
		await _settle()
	get_window().content_scale_size = original_canvas_size
	get_window().content_scale_aspect = original_aspect
	VisualSettings.set_ui_scale_percent(original_scale)
	LocalizationManager.set_language(original_language)
	get_tree().paused = original_paused
	await _settle()

func _check_layout(tutorial: TutorialModal, label: String) -> void:
	var viewport_rect := get_viewport().get_visible_rect()
	var panel_rect := tutorial._panel.get_global_rect()
	_check(viewport_rect.encloses(panel_rect), "panel fits viewport: " + label)
	var content_fits := true
	var text_fits := true
	for control in tutorial._panel.find_children("*", "Control", true, false):
		if control.is_visible_in_tree():
			content_fits = content_fits and panel_rect.encloses(control.get_global_rect())
			if control is Label:
				text_fits = text_fits and control.size.y + 1.0 >= control.get_minimum_size().y
	_check(content_fits, "all copy, image and navigation fit panel: " + label)
	_check(text_fits and tutorial._image.size.y >= 100.0, "text and image remain readable: " + label)
	_check(tutorial._image.texture != null, "localized gameplay image loads: " + label)
	_check(tutorial._counter.get_line_count() == 1, "page counter stays on one line: " + label)
	_check(tutorial._hint.get_line_count() == 1, "footer close hint stays on one line: " + label)
