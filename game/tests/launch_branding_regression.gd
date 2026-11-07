extends Node

class IntroProbe extends "res://game/scenes/intro/IntroSequence.gd":
	var studio_shown := false
	var cards: Array[String] = []

	func _run_studio_splash() -> void:
		studio_shown = true

	func _show_card(text: String, _style: String, _hold: float, _fade: float) -> void:
		cards.append(text)
		if cards.size() == 2:
			_skipped = true

	func _end_sequence() -> void:
		pass

var _checks := 0
var _failures := 0

func _ready() -> void:
	_run.call_deferred()

func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("BRANDING FAIL: " + description)

func _run() -> void:
	if OS.get_environment("BAGYONG_ISOLATED_SMOKE") != OS.get_user_data_dir():
		push_error("Branding regression requires isolated user data.")
		get_tree().quit(1)
		return
	_check(ProjectSettings.get_setting("application/config/name") == "Bagyong Bahay", "application has the game title")
	_check(get_tree().root.title == "Bagyong Bahay", "window has the game title")
	_check(not ProjectSettings.get_setting("application/boot_splash/show_image"), "default engine boot image is disabled")
	_check(OS.get_user_data_dir().ends_with("/Godot/app_userdata/Software Festival 2026"), "Windows scores and settings keep their original folder")
	var icon_path: String = ProjectSettings.get_setting("application/config/icon")
	_check(icon_path == "res://game/assets/branding/game_icon.png" and load(icon_path) is Texture2D, "project icon loads from the supplied artwork")
	var native_icon: String = ProjectSettings.get_setting("application/config/windows_native_icon")
	_check(native_icon == "res://game/assets/branding/game_icon.ico" and FileAccess.file_exists(native_icon), "Windows native icon is available")
	var exports := ConfigFile.new()
	_check(exports.load("res://export_presets.cfg") == OK, "export configuration loads")
	for preset in ["preset.0.options", "preset.1.options"]:
		_check(exports.get_value(preset, "application/modify_resources", false), "executable icon rewriting is enabled: " + preset)
		_check(exports.get_value(preset, "application/icon", "") == native_icon, "executable uses the supplied icon: " + preset)
		_check(exports.get_value(preset, "application/console_wrapper_icon", "") == native_icon, "console wrapper uses the supplied icon: " + preset)
	var intro := preload("res://game/scenes/intro/IntroSequence.tscn").instantiate()
	intro.set_script(IntroProbe)
	add_child(intro)
	await get_tree().process_frame
	_check(intro.studio_shown and intro._studio_label.texture != null, "studio artwork opens the production intro")
	_check(intro.cards == [intro.CONTENT_WARNING, intro.DEDICATION], "studio leads directly to warning and dedication without an engine card")
	intro.queue_free()
	await get_tree().process_frame
	print("Launch branding regression: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)
