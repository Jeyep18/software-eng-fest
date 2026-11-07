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

func _check_layout(tutorial: TutorialModal, label: String) -> void:
	var viewport_rect := get_viewport().get_visible_rect()
	var panel_rect := tutorial._panel.get_global_rect()
	_check(viewport_rect.encloses(panel_rect), "panel fits viewport: " + label)
	_check(panel_rect.encloses(tutorial._body.get_global_rect()) and panel_rect.encloses(tutorial._footer.get_global_rect()) and panel_rect.encloses(tutorial._title.get_global_rect()), "copy and navigation fit panel: " + label)
	_check(tutorial._body.size.y + 1.0 >= tutorial._body.get_minimum_size().y and tutorial._image.size.y >= 100.0, "body and image remain readable: " + label)
	_check(tutorial._image.texture != null, "localized gameplay image loads: " + label)
	_check(tutorial._counter.get_line_count() == 1, "page counter stays on one line: " + label)
