extends Node
## Exercise real scene sequences and portrait switching with isolated userdata.

var _checks := 0
var _failures := 0

func _ready() -> void:
	_run.call_deferred()

func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("PORTRAIT FAIL " + label)

func _run() -> void:
	if OS.get_environment("BAGYONG_ISOLATED_SMOKE") != OS.get_user_data_dir():
		push_error("Portrait regression requires isolated userdata")
		get_tree().quit(1)
		return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://game/tests/dialogue_portrait_manifest.json"))
	var portrait_count := 0
	for character in manifest.characters:
		for expression in manifest.characters[character]:
			var texture := load("res://game/assets/npc_portraits/stylized/%s/%s.png" % [character, expression]) as Texture2D
			_check(texture != null and texture.get_size() == Vector2(1254, 1254), "%s/%s imports" % [character, expression])
			var decoded: Image = texture.get_image() if texture != null else null
			var source := Image.new()
			var source_error := source.load_png_from_buffer(FileAccess.get_file_as_bytes("res://game/assets/npc_portraits/stylized/%s/%s.png" % [character, expression]))
			if decoded != null:
				decoded.convert(Image.FORMAT_RGBA8)
				source.convert(Image.FORMAT_RGBA8)
			_check(source_error == OK and decoded != null and decoded.get_data() == source.get_data(), "%s/%s decodes without pixel changes" % [character, expression])
			portrait_count += 1
			await get_tree().process_frame
	_check(portrait_count == 68, "complete expression library")
	var lines: Dictionary = {}
	for path in manifest.npc_scenes:
		var packed := load("res://" + path) as PackedScene
		_check(packed != null, "NPC scene loads: " + path)
		if packed == null:
			continue
		var state := packed.get_state()
		for node in state.get_node_count():
			for property in state.get_node_property_count(node):
				var sequence = state.get_node_property_value(node, property)
				if sequence is DialogueSequence:
					for line in sequence.lines:
						lines[line.resource_path] = line
		# Allow rendering resources from the previous model to retire between scenes.
		await get_tree().process_frame
	_check(lines.size() == 66, "64 active lines and two configured Linda fallback lines")
	var ui := preload("res://game/ui/dialogue/npc/dialogue_ui.tscn").instantiate() as DialogueUI
	add_child(ui)
	var image := ui.get_node("%SpeakerImage") as TextureRect
	for language in ["english", "tagalog"]:
		LocalizationManager.set_language(language)
		for line: DialogueLine in lines.values():
			_check(line.expression != null and line.expression.resource_path.begins_with("res://game/assets/npc_portraits/stylized/"), "line has approved portrait: " + line.resource_path)
			ui.show_line(line)
			ui.skip_to_end()
			_check(image.visible and image.texture == line.expression, "portrait changes with line: " + line.resource_path)
			_check(ui.get_node("%SpeakerName").text == line.get_speaker_name(), "localized speaker: " + line.resource_path)
			_check(ui.get_node("%SpeakerDialogue").get_parsed_text() != "", "localized dialogue displays: " + line.resource_path)
	var no_portrait := DialogueLine.new()
	no_portrait.text = "Portrait visibility regression"
	ui.show_line(no_portrait)
	_check(not image.visible, "missing portrait hides previous speaker")
	ui.show_line(lines.values()[0])
	_check(image.visible, "next portrait restores visibility")
	var monologue := preload("res://game/ui/dialogue/monologue/monologue_ui.tscn").instantiate() as MonologueUI
	add_child(monologue)
	monologue.hide_ui()
	_check(monologue.get_node("%SpeakerImage").texture.resource_path.ends_with("/stylized/player/thinking.png"), "shared monologue uses player thinking with glasses")
	var capture_dir := OS.get_environment("PORTRAIT_CAPTURE_DIR")
	if capture_dir != "" and DisplayServer.get_name() != "headless":
		LocalizationManager.set_language("english")
		for identity in ["nanay", "ate_linda", "grocery_girl", "player"]:
			for line: DialogueLine in lines.values():
				if line.expression.resource_path.contains("/" + identity + "/"):
					ui.show_line(line)
					ui.skip_to_end()
					for _frame in range(6):
						await get_tree().process_frame
					await RenderingServer.frame_post_draw
					_check(get_viewport().get_texture().get_image().save_png(capture_dir.path_join(identity + ".png")) == OK, "render capture: " + identity)
					break
		ui.hide_ui()
		monologue.show_line("Kailangan kong maghanda.", "Player")
		monologue.skip_to_end()
		await RenderingServer.frame_post_draw
		_check(get_viewport().get_texture().get_image().save_png(capture_dir.path_join("player_thinking.png")) == OK, "monologue render capture")
	monologue.hide_ui()
	ui.hide_ui()
	monologue.queue_free()
	ui.queue_free()
	await get_tree().process_frame
	print("Portrait regression: %d checks, %d failures; %d lines, %d portraits" % [_checks, _failures, lines.size(), portrait_count])
	get_tree().quit(0 if _failures == 0 else 1)
