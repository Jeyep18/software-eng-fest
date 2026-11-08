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
	await _test_input_isolation(menu)

	var credits: CanvasLayer = menu.credits_modal
	var credits_body: RichTextLabel = credits.get_node("%Body")
	var credits_close: Button = credits.get_node("%Close")
	var reader: PanelContainer = credits.get_node("%Reader")
	var scroll_container: ScrollContainer = credits.get_node("%Scroll")
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
	_check(credits_title.text == "BAGYONG BAHAY" and credits_body.get_parsed_text().contains("3 Netherite Ingots")
		and credits_body.get_parsed_text().contains("Jeyep18"), "game title and original team credit")
	_check(credits_body.get_parsed_text().contains("Bates Shower") and credits_body.get_parsed_text().contains("Imagex"), "restored title font retains its creator credit")
	_check(credits._tabs.size() == 4 and credits._source_links.size() == credits.CONTENT.SOURCE_LINKS.size(), "four views retain the complete keyboard source catalog")
	_check(credits.find_children("*", "OptionButton", true, false).is_empty(), "credits has no dropdown selectors")
	_check(credits_close.get_meta("button_role") == &"secondary", "Close has a secondary action style")
	await _capture("credits_english")
	_click(menu.quit_button.get_global_rect().get_center())
	_check(not quit.is_confirmation_open(), "click cannot reach the menu behind credits")
	_click(reader.get_global_rect().get_center(), MOUSE_BUTTON_WHEEL_DOWN)
	await get_tree().process_frame
	_check(scroll_container.scroll_vertical > 0, "mouse wheel scrolls the credits")
	credits_close.grab_focus()
	_key(KEY_TAB)
	_check(credits._tabs[0].has_focus(), "Tab enters the view navigation")
	for index in 4:
		_key(KEY_TAB)
	_check(scroll_container.has_focus(), "Tab focuses the bounded reading viewport")
	var first_scroll := scroll_container.scroll_vertical
	_key(KEY_PAGEDOWN)
	_check(scroll_container.scroll_vertical > first_scroll, "Page Down scrolls the credits")
	_key(KEY_END)
	await get_tree().process_frame
	var scroll := scroll_container.get_v_scroll_bar()
	_check(is_equal_approx(scroll.value, scroll.max_value - scroll.page), "End reaches the last section")
	_key(KEY_HOME)
	_check(is_zero_approx(scroll.value), "Home returns to the first section")
	_key(KEY_TAB)
	_check(credits._source_links[0].has_focus(), "Tab reaches a directly activatable source link")
	for link in credits._source_links:
		_check(link is LinkButton and link.focus_mode == Control.FOCUS_ALL and link.pressed.get_connections().size() == 1, "source link is keyboard accessible and wired once")
		_key(KEY_TAB)
	_check(credits_close.has_focus(), "focus cycles within credits")
	_click(credits._tabs[1].get_global_rect().get_center())
	await get_tree().process_frame
	_check(credits_body.get_parsed_text().contains("Jeyep18"), "Licenses opens offline project terms")
	_check(credits_body.get_parsed_text().contains("Lyndschoko") and credits_body.get_parsed_text().contains("CC BY 4.0")
		and credits_body.get_parsed_text().contains("CUSTOM ASSET AND PLATFORM TERMS"), "asset notices retain attribution and custom terms")
	_check(credits_body.get_parsed_text().contains("Permission is hereby granted")
		and credits_body.get_parsed_text().contains("Third-party components"), "offline engine and dependency notices")
	_check(credits_body.get_parsed_text().contains("Creative Commons")
		and credits_body.get_parsed_text().contains("OPEN FONT LICENSE"), "full media and font licenses load offline")
	_check(credits_body.get_parsed_text().contains("Free for personal use only"), "the restored font's embedded notice is available offline")
	for entry: Array in credits.CONTENT.LICENSE_FILES:
		_check(_words(credits_body.get_parsed_text()).contains(_words(FileAccess.get_file_as_string(entry[1]))), "reflow preserves complete notice wording: " + entry[0])
	_check(_words(credits_body.get_parsed_text()).contains(_words(Engine.get_license_text())), "engine license wording is preserved")
	_click(credits._tabs[2].get_global_rect().get_center())
	_check(credits_body.get_parsed_text().contains("leaderboard") and not credits._sources.is_visible_in_tree(), "Privacy explains local scores without source controls")
	_click(credits._tabs[3].get_global_rect().get_center())
	_check(credits_body.get_parsed_text().contains("Codex") and credits_body.get_parsed_text().contains("ChatGPT"), "AI use discloses confirmed development assistance")
	VisualSettings.set_ui_scale_percent(100)
	_click(credits._tabs[0].get_global_rect().get_center())
	await get_tree().process_frame
	_check(get_viewport().get_visible_rect().encloses(credits_panel.get_global_rect()), "credits fit at 100%")
	await _capture("credits_english_100")
	credits._tabs[0].grab_focus()
	_key(KEY_RIGHT)
	_key(KEY_ENTER)
	_check(credits._view == 1 and credits._tabs[1].has_focus(), "arrow and Enter navigate to Licenses")
	_key(KEY_ESCAPE)
	_check(not credits.visible and menu.credits_button.has_focus(), "Escape closes credits and restores source focus")

	LocalizationManager.set_language("tagalog")
	VisualSettings.set_ui_scale_percent(175)
	_click(menu.credits_button.get_global_rect().get_center())
	await get_tree().process_frame
	_check(credits.visible and credits._tabs[0].text == "Mga kredito" and credits_close.text == "Isara", "mouse opens localized credits")
	_check(get_viewport().get_visible_rect().encloses(credits_panel.get_global_rect()), "credits fit at 175%")
	await _capture("credits_tagalog_175")
	for index in range(1, 4):
		_click(credits._tabs[index].get_global_rect().get_center())
		await get_tree().process_frame
		_check(not credits_body.text.is_empty() and credits_panel.get_global_rect().encloses(reader.get_global_rect()), "localized reader fits at 175% " + str(index))
		await _capture("notice_%d_tagalog_175" % index)
	await _test_credits_layouts(credits)
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

func _test_input_isolation(menu: Node) -> void:
	var board: CanvasLayer = menu.leaderboards_modal
	menu.leaderboards_button.grab_focus()
	_key(KEY_ENTER)
	await get_tree().create_timer(0.2).timeout
	_check(board.visible and board.close_button.has_focus(), "leaderboards opens with keyboard focus inside")
	_click(menu.settings_button.get_global_rect().get_center())
	_check(not menu._settings_layer.visible, "leaderboards backdrop blocks menu clicks")
	menu._on_settings_close_requested()
	for index in 6:
		_key(KEY_TAB, index % 2 == 1)
		_check(board.is_ancestor_of(get_viewport().gui_get_focus_owner()), "leaderboards contains Tab and Shift-Tab %d" % index)
	_key(KEY_ESCAPE)
	_click(menu.settings_button.get_global_rect().get_center())
	_check(not menu._settings_layer.visible, "leaderboards closing fade still blocks clicks")
	await get_tree().create_timer(0.2).timeout
	_check(not board.visible and menu.leaderboards_button.has_focus(), "Escape closes leaderboards and restores focus")
	board.close()
	await get_tree().create_timer(0.2).timeout
	menu._on_settings_close_requested()
	menu._on_leaderboards_pressed()
	await get_tree().create_timer(0.2).timeout
	_check(board.visible and board.close_button.has_focus(), "leaderboards reopens after its fade")
	_click(board.close_button.get_global_rect().get_center())
	board.close()
	menu.request_start_game(menu.start_button)
	_check(not menu._difficulty_layer.visible, "leaderboards closing fade blocks another menu action")
	await get_tree().create_timer(0.2).timeout
	_check(not board.visible and menu.leaderboards_button.has_focus(), "leaderboards Close restores focus after repeated close")

	for cycle in 2:
		menu.settings_button.grab_focus()
		_key(KEY_ENTER)
		await get_tree().process_frame
		_check(menu._settings_layer.visible and menu._settings_panel.is_ancestor_of(get_viewport().gui_get_focus_owner()), "settings opens with keyboard focus inside %d" % cycle)
		menu.request_start_game(menu.start_button)
		_check(not menu._difficulty_layer.visible, "settings blocks a second menu action")
		if menu._difficulty_layer.visible:
			menu._hide_difficulty_overlay()
		var focus_stayed_inside := true
		for index in 20:
			_key(KEY_TAB, index >= 10)
			focus_stayed_inside = focus_stayed_inside and menu._settings_panel.is_ancestor_of(get_viewport().gui_get_focus_owner())
		_check(focus_stayed_inside, "settings contains forward and backward focus cycling %d" % cycle)
		_key(KEY_ESCAPE)
		_check(not menu._settings_layer.visible and menu.settings_button.has_focus(), "Escape closes settings and restores focus %d" % cycle)
		menu._on_settings_close_requested()

	for cycle in 2:
		menu.request_start_game(menu.start_button)
		await get_tree().process_frame
		_check(menu._difficulty_layer.visible and menu._difficulty_layer.is_ancestor_of(get_viewport().gui_get_focus_owner()), "difficulty opens with keyboard focus inside %d" % cycle)
		var cancel: Button = menu._difficulty_layer.find_child("CancelDifficulty", true, false)
		var choices: Array[Node] = menu._difficulty_layer.find_children("*", "Button", true, false)
		_check(cancel.get_meta("button_role") == &"secondary" and cancel.size.x < choices[0].size.x, "difficulty Cancel is narrower and visually secondary")
		if cycle == 0:
			await _capture("difficulty_buttons")
		menu._on_settings_pressed()
		_check(not menu._settings_layer.visible, "difficulty blocks a second menu action")
		menu._on_settings_close_requested()
		var focus_stayed_inside := true
		for index in 10:
			_key(KEY_TAB, index >= 5)
			focus_stayed_inside = focus_stayed_inside and menu._difficulty_layer.is_ancestor_of(get_viewport().gui_get_focus_owner())
		_check(focus_stayed_inside, "difficulty contains forward and backward focus cycling %d" % cycle)
		_key(KEY_ESCAPE)
		_check(not menu._difficulty_layer.visible and menu.start_button.has_focus() and not menu.start_button.disabled, "Escape cancels difficulty and restores Start %d" % cycle)
		menu._hide_difficulty_overlay()

func _words(text: String) -> String:
	return RegEx.create_from_string("\\s+").sub(text, " ", true).strip_edges()

func _test_credits_layouts(credits: CanvasLayer) -> void:
	var original_size := get_window().content_scale_size
	var original_aspect := get_window().content_scale_aspect
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	credits._select_view(0)
	VisualSettings.set_ui_scale_percent(175)
	get_window().content_scale_size = Vector2i(1280, 720)
	for frame in 4:
		await get_tree().process_frame
	var heading := LocalizationManager.translate_key(credits.CONTENT.CREDIT_SECTIONS[0][0], credits.CONTENT.CREDIT_SECTIONS[0][1])
	_check(credits._view == 0 and credits._body.text.begins_with(credits._heading(heading)), "resizing refreshes embedded heading sizes without changing the view")
	for canvas_size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		get_window().content_scale_size = canvas_size
		for language in ["english", "tagalog"]:
			LocalizationManager.set_language(language)
			for scale in [100, 140, 175]:
				VisualSettings.set_ui_scale_percent(scale)
				for view in 4:
					credits._select_view(view)
					for frame in 4:
						await get_tree().process_frame
					var label := "%s %d%% %s view%d" % [language, scale, canvas_size, view]
					var panel_rect: Rect2 = credits._panel.get_global_rect()
					var reader_rect: Rect2 = credits._reader.get_global_rect()
					var bar: VScrollBar = credits._scroll.get_v_scroll_bar()
					_check(get_viewport().get_visible_rect().encloses(panel_rect) and panel_rect.encloses(reader_rect) and panel_rect.encloses(credits._close_button.get_global_rect()), "all modal chrome fits: " + label)
					_check(credits._body.size.x <= credits._scroll.size.x and credits._scroll.get_h_scroll_bar().max_value <= credits._scroll.size.x + 1.0, "text and source links fit the reader width: " + label)
					_check(bar.get_global_rect().end.x >= reader_rect.end.x - 3.0, "scrollbar stays at the reading panel edge: " + label)
					credits._scroll.grab_focus()
					_check((credits._reader.get_theme_stylebox("panel") as StyleBoxFlat).border_color == (GameUIStyle.GAME_THEME.get_stylebox("focus", "Button") as StyleBoxFlat).border_color, "keyboard reading focus is marked on the bounded panel: " + label)
					_key(KEY_END)
					await get_tree().process_frame
					_check(is_equal_approx(bar.value, maxf(0.0, bar.max_value - bar.page)), "keyboard reaches the true document end: " + label)
					_key(KEY_HOME)
					if OS.get_cmdline_user_args().has("--capture"):
						await _capture("reader_%s_%d_%dx%d_view%d" % [language, scale, canvas_size.x, canvas_size.y, view])
	get_window().content_scale_size = original_size
	get_window().content_scale_aspect = original_aspect
	LocalizationManager.set_language("tagalog")
	VisualSettings.set_ui_scale_percent(175)
	credits._select_view(3)
	for frame in 4:
		await get_tree().process_frame

func _key(code: Key, shift: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.shift_pressed = shift
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
