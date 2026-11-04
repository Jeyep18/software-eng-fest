extends Node

const MENU = preload("res://game/scenes/main_menu/Main_Menu1.tscn")

var _checks := 0
var _failures := 0

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	if OS.get_environment("BAGYONG_ISOLATED_SMOKE") != OS.get_user_data_dir():
		push_error("Main menu modal regression requires isolated userdata: %s" % OS.get_user_data_dir())
		get_tree().quit(1)
		return

	LocalizationManager.set_language("english")
	VisualSettings.set_ui_scale_percent(140)
	var menu := MENU.instantiate()
	add_child(menu)
	await get_tree().create_timer(0.8).timeout

	var credits: CanvasLayer = menu.credits_modal
	var credits_body: RichTextLabel = credits.get_node("%Body")
	var credits_close: Button = credits.get_node("%Close")
	var credits_sources: Button = credits.get_node("%Sources")
	var credits_title: Label = credits.get_node("%Title")
	var credits_panel: PanelContainer = credits.get_node("%Panel")
	var quit: Button = menu.quit_button
	var cancel: Button = quit.find_child("Cancel", true, false)
	var confirm: Button = quit.find_child("Confirm", true, false)

	_check(not credits.visible and not quit.is_confirmation_open(), "both dialogs start hidden")
	menu.credits_button.grab_focus()
	_key(KEY_ENTER)
	await get_tree().process_frame
	_check(credits.visible and credits_close.has_focus(), "Enter opens credits and focuses Close")
	_check(credits_title.text == "Game credits" and credits_body.get_parsed_text().contains("3 Netherite Ingots"), "English heading and development credit")
	_check(credits_body.get_parsed_text().contains("BokerTV") and credits_body.get_parsed_text().contains("Henaway"), "confirmed broadcast and new sound credits are present")
	await _capture("credits_english")
	_click(menu.quit_button.get_global_rect().get_center())
	_check(not quit.is_confirmation_open(), "click cannot reach the menu behind credits")
	_click(credits_body.get_global_rect().get_center(), MOUSE_BUTTON_WHEEL_DOWN)
	await get_tree().process_frame
	_check(credits_body.get_v_scroll_bar().value > 0, "mouse wheel scrolls the credits")
	_key(KEY_TAB)
	_check(credits_body.has_focus(), "Tab focuses the credits text")
	var first_scroll := credits_body.get_v_scroll_bar().value
	_key(KEY_PAGEDOWN)
	_check(credits_body.get_v_scroll_bar().value > first_scroll, "Page Down scrolls the credits")
	_key(KEY_END)
	await get_tree().process_frame
	var scroll := credits_body.get_v_scroll_bar()
	_check(is_equal_approx(scroll.value, scroll.max_value - scroll.page), "End reaches the last section")
	_key(KEY_HOME)
	_check(is_zero_approx(scroll.value), "Home returns to the first section")
	_key(KEY_TAB)
	_check(credits_sources.has_focus(), "Tab reaches the source list")
	_key(KEY_TAB)
	_check(credits_close.has_focus(), "focus cycles within credits")
	_key(KEY_ESCAPE)
	_check(not credits.visible and menu.credits_button.has_focus(), "Escape closes credits and restores source focus")

	LocalizationManager.set_language("tagalog")
	VisualSettings.set_ui_scale_percent(175)
	_click(menu.credits_button.get_global_rect().get_center())
	await get_tree().process_frame
	_check(credits.visible and credits_title.text == "Mga kredito" and credits_close.text == "Isara", "mouse opens localized credits")
	_check(get_viewport().get_visible_rect().encloses(credits_panel.get_global_rect()), "credits fit at 175%")
	await _capture("credits_tagalog_175")
	_click(credits_close.get_global_rect().get_center())
	_check(not credits.visible and menu.credits_button.has_focus(), "Close button restores source focus")

	_click(quit.get_global_rect().get_center())
	await get_tree().process_frame
	_check(quit.is_confirmation_open() and cancel.has_focus(), "Quit opens and focuses Cancel")
	_check(cancel.text == "Bumalik" and confirm.text == "Lumabas", "quit actions are localized")
	_check(get_viewport().get_visible_rect().encloses(confirm.get_global_rect()), "quit actions fit at 175%")
	_check(not menu._dev_sequence_input_allowed(), "quit dialog blocks the developer sequence")
	await _capture("quit_tagalog_175")
	_key(KEY_TAB)
	_check(confirm.has_focus(), "Tab moves from Cancel to Quit")
	_key(KEY_TAB)
	_check(cancel.has_focus(), "quit focus cycles inside the prompt")
	_key(KEY_ENTER)
	_check(not quit.is_confirmation_open() and quit.has_focus(), "Enter on Cancel returns to the menu")
	_key(KEY_ENTER)
	_key(KEY_ESCAPE)
	_check(not quit.is_confirmation_open() and quit.has_focus(), "Escape cancels quit and restores focus")

	print("Main menu modal regression: %d checks, %d failures" % [_checks, _failures])
	if _failures > 0 or not OS.get_cmdline_user_args().has("--confirm-quit"):
		get_tree().quit(0 if _failures == 0 else 1)
		return

	_key(KEY_ENTER)
	await get_tree().process_frame
	_click(confirm.get_global_rect().get_center())
	print("Quit confirmation entered fade: ", quit.disabled and confirm.disabled)
	await get_tree().create_timer(2.0).timeout
	push_error("Confirmed quit did not exit")
	get_tree().quit(1)

func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	get_viewport().push_input(event, true)
	var release := event.duplicate() as InputEventKey
	release.pressed = false
	get_viewport().push_input(release, true)

func _click(at: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.global_position = at
	event.button_index = button
	event.pressed = true
	get_viewport().push_input(event, true)
	var release := event.duplicate() as InputEventMouseButton
	release.pressed = false
	get_viewport().push_input(release, true)

func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	_check(get_viewport().get_texture().get_image().save_png("user://%s.png" % name) == OK, "saved " + name)

func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print("PASS " if condition else "FAIL ", description)
