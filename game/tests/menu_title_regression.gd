extends Node

var _checks := 0
var _failures := 0

func _ready() -> void:
	_run.call_deferred()

func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("MENU TITLE FAIL: " + description)

func _run() -> void:
	if OS.get_environment("BAGYONG_ISOLATED_SMOKE") != OS.get_user_data_dir():
		push_error("Menu title regression requires isolated user data.")
		get_tree().quit(1)
		return
	var menu := preload("res://game/scenes/main_menu/Main_Menu1.tscn").instantiate()
	add_child(menu)
	var title: Label = menu.get_node("VBoxContainer/VBoxContainer/TitleArt")
	var tagline: Label = menu.get_node("VBoxContainer/VBoxContainer/Tagline")
	var old_font: FontFile = preload("res://game/assets/fonts/bates_shower/Bates Shower.ttf")
	_check(title.label_settings.font == old_font and tagline.label_settings.font == old_font, "restored title and tagline use their original Bates Shower font")
	_check(title.label_settings.font_size == 100 and title.label_settings.line_spacing == 80.0 and tagline.label_settings.font_size == 45, "typography values match the recovered menu version")
	var exports := ConfigFile.new()
	_check(exports.load("res://export_presets.cfg") == OK, "export presets load")
	_check(not str(exports.get_value("preset.0", "exclude_filter", "")).contains("bates_shower"), "the confirmed original font remains available to Windows exports")
	_check(title.text == "Bagyong\nBahay" and tagline.text == "Handa ka na ba?", "original title arrangement and tagline are restored")
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	if DisplayServer.get_name() != "headless":
		await get_tree().create_timer(3.2).timeout
	for canvas_size in [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(1280, 800)]:
		get_window().content_scale_size = canvas_size
		for language in ["english", "tagalog"]:
			LocalizationManager.set_language(language)
			for percent in [100, 140, 175]:
				VisualSettings.set_ui_scale_percent(percent)
				for frame in 4:
					await get_tree().process_frame
				var label := "%s %d%% %s" % [language, percent, canvas_size]
				var viewport_rect := get_viewport().get_visible_rect()
				var replay_rect: Rect2 = menu.replay_intro_button.get_global_rect()
				var controls: Array[Control] = [title, tagline]
				for button in menu.menu_buttons.get_children():
					if button is Button:
						controls.append(button)
				_check(controls.size() == 8 and title.get_line_count() == 2, "two-line title, tagline and all six actions: " + label)
				var all_inside := viewport_rect.encloses(replay_rect)
				var no_overlap := true
				for index in controls.size():
					var rect := controls[index].get_global_rect()
					all_inside = all_inside and viewport_rect.encloses(rect)
					no_overlap = no_overlap and not rect.intersects(replay_rect)
					for other in range(index + 1, controls.size()):
						no_overlap = no_overlap and not rect.intersects(controls[other].get_global_rect())
				_check(all_inside, "title and every action fit the viewport: " + label)
				_check(no_overlap, "title, tagline, actions and Replay Intro do not overlap: " + label)
				_check(menu.menu_layout.get_global_rect().end.y <= replay_rect.position.y - 20.0, "column reserves a clear Replay Intro gap: " + label)
				if DisplayServer.get_name() != "headless":
					await RenderingServer.frame_post_draw
					get_viewport().get_texture().get_image().save_png("user://menu_title_%s_%d_%dx%d.png" % [language, percent, canvas_size.x, canvas_size.y])
	menu.queue_free()
	await get_tree().process_frame
	print("Menu title regression: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)
