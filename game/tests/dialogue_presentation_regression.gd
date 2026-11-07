extends Node

const UI_STYLE = preload("res://game/ui/theme/GameUIStyle.gd")
const NPC_UI = preload("res://game/ui/dialogue/npc/dialogue_ui.tscn")
const MONOLOGUE_UI = preload("res://game/ui/dialogue/monologue/monologue_ui.tscn")
const HUD = preload("res://game/ui/hud/PreparationChecklistHUD.tscn")
const ACTION_KEY := "dialogue.i_inabot_ni_nanay_ang_pera_para_sa_mga_kailangan.3f35f1e4"
const THOUGHT_KEY := "dialogue.kailangan_ni_lola_ang_b_gamot_b_kailangan_ko_pum.09f4c2a6"

var _checks := 0
var _failures := 0

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	if OS.get_environment("BAGYONG_ISOLATED_SMOKE") != OS.get_user_data_dir():
		push_error("Dialogue presentation regression requires isolated userdata.")
		get_tree().quit(1)
		return
	GameState.reset()
	NeedsLog.reset()
	var backdrop := ColorRect.new()
	backdrop.color = Color("#18242a")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var hud := HUD.instantiate()
	add_child(hud)
	var npc := NPC_UI.instantiate() as DialogueUI
	add_child(npc)
	var monologue := MONOLOGUE_UI.instantiate() as MonologueUI
	add_child(monologue)
	var npc_label := npc.get_node("%SpeakerDialogue") as RichTextLabel
	var monologue_label := monologue.get_node("%SpeakerDialougue") as RichTextLabel
	var action := _find_line("res://game/entities/npcs/family/nanay/nanay.tscn", "[color=#c7b8dd]")
	var thought := _find_line("res://game/entities/npcs/family/lola/lola.tscn", "[color=#a9d8e8]")
	var spoken_italic := _find_line("res://game/entities/npcs/family/lola/lola.tscn", "[i]Mahalaga")
	_check(action != null and thought != null and spoken_italic != null, "authored action, thought and spoken italic lines exist")
	if action == null or thought == null or spoken_italic == null:
		get_tree().quit(1)
		return
	for label in [npc_label, monologue_label]:
		var italic := label.get_theme_font("italics_font") as FontVariation
		var bold_italic := label.get_theme_font("bold_italics_font") as FontVariation
		_check(italic != null and italic.base_font == UI_STYLE.FONT_REGULAR
			and italic.variation_transform != Transform2D.IDENTITY, "regular italic has an actual slant")
		_check(bold_italic != null and bold_italic.base_font == UI_STYLE.FONT_SEMIBOLD
			and bold_italic.variation_transform != Transform2D.IDENTITY, "bold italic retains weight and slant")
	_check(monologue_label.get_theme_color("default_color") == Color("#a9d8e8"), "monologues default to pale blue")
	_check(npc_label.get_theme_color("default_color") != Color("#a9d8e8"), "ordinary speech keeps its existing color")
	LocalizationManager.set_language("english")
	npc.show_line(action)
	npc_label.visible_ratio = 0.5
	var portrait: Texture2D = npc.get_node("%SpeakerImage").texture
	LocalizationManager.set_language("tagalog")
	_check(npc_label.get_parsed_text() == _plain_text(action.get_text()) and npc_label.visible_ratio == 0.5,
		"live language switch retranslates mixed dialogue and preserves typing progress")
	_check(npc.get_node("%SpeakerImage").texture == portrait, "live language switch preserves the current portrait")
	npc.hide_ui()
	monologue.show_line("Yung [b]martilyo[/b] ni Tatay.", "Player")
	monologue_label.visible_ratio = 0.5
	LocalizationManager.set_language("english")
	_check(monologue_label.get_parsed_text() == _plain_text(LocalizationManager.translate("Yung [b]martilyo[/b] ni Tatay."))
		and monologue_label.visible_ratio == 0.5, "live language switch retranslates monologue and preserves typing progress")
	monologue.hide_ui()
	for language in ["english", "tagalog"]:
		LocalizationManager.set_language(language)
		for scale_percent in [100, 140, 175]:
			VisualSettings.set_ui_scale_percent(scale_percent)
			GameState.cash_balance = 700
			GameState.cash_changed.emit(700)
			npc.show_line(action)
			npc.skip_to_end()
			monologue.hide_ui()
			await _settle()
			var action_text := LocalizationManager.translate_key(ACTION_KEY)
			_check(action.get_text() == action_text and action_text.begins_with("[color=#c7b8dd][i]")
				and action_text.contains("[/i][/color] "), "localized action ends its color before speech: " + language)
			_check(npc_label.get_parsed_text() == _plain_text(action_text), "action markup parses without changing dialogue")
			_check(npc.get_node("%SpeakerImage").texture == action.expression, "action retains the speaker portrait")
			_check(hud.cash_label.text == "PHP 700", "compact balance uses the same currency in both languages")
			var small_size: Vector2 = hud.cash_panel.size
			_check(small_size.x < 210.0 * VisualSettings.get_ui_scale(), "cash card no longer reserves the old wide panel")
			_check(hud.cash_label.size.x >= hud.cash_label.get_minimum_size().x
				and hud.cash_label.size.y >= hud.cash_label.get_minimum_size().y, "cash label fits without clipping")
			_check(hud.checklist_panel.offset_top >= hud.cash_panel.offset_bottom + 8.0, "objectives stay below the cash card")
			await _capture("action_%s_%d" % [language, scale_percent])
			GameState.cash_balance = 1234567890
			GameState.cash_changed.emit(GameState.cash_balance)
			await _settle()
			_check(hud.cash_label.text == "PHP 1234567890" and hud.cash_panel.size.x > small_size.x,
				"cash card grows with a large balance")
			_check(hud.cash_label.size.x >= hud.cash_label.get_minimum_size().x, "large balance fits the cash card")
			GameState.cash_balance = 700
			GameState.cash_changed.emit(700)
			await _settle()
			_check(is_equal_approx(hud.cash_panel.size.x, small_size.x), "cash card shrinks again after spending")
			npc.show_line(thought)
			npc.skip_to_end()
			_check(thought.get_text() == LocalizationManager.translate_key(THOUGHT_KEY)
				and npc_label.text.contains("[color=#a9d8e8]")
				and npc_label.text.contains("[color=#e0b45b]"), "embedded thought retains blue and yellow emphasis")
			await _capture("thought_%s_%d" % [language, scale_percent])
			npc.show_line(spoken_italic)
			npc.skip_to_end()
			_check(npc_label.text.contains("[i]") and not npc_label.text.contains("#c7b8dd")
				and not npc_label.text.contains("#a9d8e8"), "spoken italic emphasis is not classified as narration")
			npc.hide_ui()
			monologue.show_line("Yung [b]martilyo[/b] ni Tatay.", "Player")
			_check(monologue_label.visible_ratio == 0.0, "monologue still starts with the typewriter hidden")
			var tween := monologue.run_typewriter(1000.0)
			await tween.finished
			_check(monologue_label.visible_ratio == 1.0
				and monologue_label.text.contains("[color=#e0b45b]"), "typewriter completes with yellow emphasis intact")
			_check(monologue.get_node("%SpeakerImage").texture.resource_path.ends_with("/stylized/player/thinking.png"),
				"monologue retains the thinking portrait")
			await _capture("monologue_%s_%d" % [language, scale_percent])
			monologue.hide_ui()
	hud.show_cash_gain(50)
	_check(hud.cash_gain_label.visible and hud.cash_gain_label.text == "+50 PHP", "cash gain feedback is preserved")
	await get_tree().create_timer(2.5).timeout
	_check(not hud.cash_gain_label.visible, "cash gain feedback still dismisses")
	hud.queue_free()
	npc.queue_free()
	monologue.queue_free()
	await get_tree().process_frame
	print("Dialogue presentation regression: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)

func _find_line(scene_path: String, text_fragment: String) -> DialogueLine:
	var packed := load(scene_path) as PackedScene
	var state := packed.get_state()
	for node in state.get_node_count():
		for property in state.get_node_property_count(node):
			var sequence = state.get_node_property_value(node, property)
			if sequence is DialogueSequence:
				for line in sequence.lines:
					if line.text.contains(text_fragment):
						return line
	return null

func _plain_text(text: String) -> String:
	return RegEx.create_from_string("\\[[^\\]]+\\]").sub(text, "", true)

func _settle() -> void:
	for _frame in range(4):
		await get_tree().process_frame

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await _settle()
	await RenderingServer.frame_post_draw
	_check(get_viewport().get_texture().get_image().save_png("user://presentation_%s.png" % label) == OK,
		"render capture: " + label)

func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print("PRESENTATION ", "PASS " if condition else "FAIL ", label)
