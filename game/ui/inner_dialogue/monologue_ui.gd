class_name MonologueUI
extends Control

@onready var _speaker_name: Label = %SpeakerName
@onready var _speaker_dialog: RichTextLabel = %SpeakerDialougue
@onready var _interact_prompt: Control = %InteractPrompt
@onready var _speaker_image: TextureRect = %SpeakerImage

const UI_STYLE = preload("res://game/ui/GameUIStyle.gd")
const GAMEPLAY_HINT_COLOR: String = "#e0b45b"

func _ready() -> void:
	_speaker_name.add_theme_font_override("font", UI_STYLE.FONT_SEMIBOLD)
	_speaker_dialog.add_theme_font_override("normal_font", UI_STYLE.FONT_REGULAR)
	_speaker_dialog.add_theme_font_override("bold_font", UI_STYLE.FONT_SEMIBOLD)
	_speaker_dialog.add_theme_font_override("italics_font", UI_STYLE.FONT_REGULAR)
	_speaker_dialog.add_theme_font_override("bold_italics_font", UI_STYLE.FONT_SEMIBOLD)
	_speaker_dialog.add_theme_font_override("mono_font", UI_STYLE.FONT_REGULAR)

func show_line(text: String, player_name: String = "...") -> void:
	AudioManager.play_voice(preload("res://game/assets/sfx/freesound_community-bllrr-text-loop-82399-FreesoundCommunityPixabay.mp3"), true)
	_speaker_name.text = LocalizationManager.translate(player_name)
	_speaker_dialog.bbcode_enabled = true
	_speaker_dialog.parse_bbcode(_format_dialogue_text(LocalizationManager.translate(text)))
	_speaker_dialog.visible_ratio = 0.0
	show()

func run_typewriter(chars_per_second: float) -> Tween:
	var duration: float = float(_speaker_dialog.get_parsed_text().length()) / chars_per_second
	var tween: Tween = create_tween()
	tween.tween_property(_speaker_dialog, "visible_ratio", 1.0, duration)
	tween.finished.connect(AudioManager.stop_voice)
	return tween

func skip_to_end() -> void:
	AudioManager.stop_voice()
	_speaker_dialog.visible_ratio = 1.0

func set_prompt_visible(is_visible: bool) -> void:
	_interact_prompt.visible = is_visible

func hide_ui() -> void:
	AudioManager.stop_voice()
	hide()

func _format_dialogue_text(text: String) -> String:
	return text.replace("[b]", "[b][color=" + GAMEPLAY_HINT_COLOR + "]").replace("[/b]", "[/color][/b]")
