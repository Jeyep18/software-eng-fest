class_name DialogueUI
extends Control

@onready var _speaker_name: Label = %SpeakerName
@onready var _speaker_dialogue: RichTextLabel = %SpeakerDialogue
@onready var _interact_prompt: Control = %InteractPrompt
@onready var _speaker_image: TextureRect = %SpeakerImage
@onready var _dialogue_margin: MarginContainer = $MarginContainer

const UI_STYLE = preload("res://game/ui/GameUIStyle.gd")
const GAMEPLAY_HINT_COLOR: String = "#e0b45b"

func _ready() -> void:
	_speaker_name.add_theme_font_override("font", UI_STYLE.FONT_SEMIBOLD)
	_speaker_dialogue.add_theme_font_override("normal_font", UI_STYLE.FONT_REGULAR)
	_speaker_dialogue.add_theme_font_override("bold_font", UI_STYLE.FONT_SEMIBOLD)
	_speaker_dialogue.add_theme_font_override("italics_font", UI_STYLE.FONT_REGULAR)
	_speaker_dialogue.add_theme_font_override("bold_italics_font", UI_STYLE.FONT_SEMIBOLD)
	_speaker_dialogue.add_theme_font_override("mono_font", UI_STYLE.FONT_REGULAR)
	VisualSettings.ui_scale_changed.connect(_on_ui_scale_changed)
	get_viewport().size_changed.connect(_apply_layout)
	_apply_layout()

func _on_ui_scale_changed(_scale: float) -> void:
	_apply_layout()

func _apply_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var setting_scale := VisualSettings.get_ui_scale()
	var ui_scale := minf(1.0 + (setting_scale - 1.0) * 0.625, (viewport_size.x - 48.0) / 1120.0)
	# 140% UI renders dialogue at 125%; leave room for the scaled controls HUD.
	var safe_left := minf(viewport_size.x * 0.24, 240.0 * setting_scale)
	var panel_width := minf(1120.0 * ui_scale, viewport_size.x - safe_left - 24.0)
	var panel_left := maxf((viewport_size.x - panel_width) * 0.5, safe_left)
	_dialogue_margin.anchor_left = 0.5
	_dialogue_margin.anchor_right = 0.5
	_dialogue_margin.offset_left = panel_left - viewport_size.x * 0.5
	_dialogue_margin.offset_right = _dialogue_margin.offset_left + panel_width
	_dialogue_margin.offset_top = -220.0 * ui_scale
	_dialogue_margin.offset_bottom = -24.0
	_speaker_image.custom_minimum_size = Vector2(150, 150) * ui_scale
	_speaker_name.add_theme_font_size_override("font_size", roundi(22.0 * ui_scale))
	for style in ["normal", "bold", "bold_italics", "italics", "mono"]:
		_speaker_dialogue.add_theme_font_size_override(style + "_font_size", roundi(24.0 * ui_scale))
	_interact_prompt.add_theme_font_size_override("normal_font_size", roundi(18.0 * ui_scale))

func show_line(line: DialogueLine) -> void:
	AudioManager.play_voice(preload("res://game/assets/sfx/freesound_community-bllrr-text-loop-82399-FreesoundCommunityPixabay.mp3"), true)
	_speaker_name.text = line.get_speaker_name()
	_speaker_dialogue.bbcode_enabled = true
	_speaker_dialogue.parse_bbcode(_format_dialogue_text(line.get_text()))
	_speaker_dialogue.visible_ratio = 0.0
	
	if line.expression != null:
		_speaker_image.texture = line.expression
		_speaker_image.show()
	else:
		_speaker_image.hide()
	
	show()


func run_typewriter(chars_per_second: float) -> Tween:
	var duration: float = float(_speaker_dialogue.get_parsed_text().length()) / chars_per_second
	var tween: Tween = create_tween()
	tween.tween_property(_speaker_dialogue, "visible_ratio", 1.0, duration)
	tween.finished.connect(AudioManager.stop_voice)
	return tween


func skip_to_end() -> void:
	AudioManager.stop_voice()
	_speaker_dialogue.visible_ratio = 1.0


func set_prompt_visible(isVisible: bool) -> void:
	_interact_prompt.visible = isVisible


func hide_ui() -> void:
	AudioManager.stop_voice()
	hide()

func _format_dialogue_text(text: String) -> String:
	return text.replace("[b]", "[b][color=" + GAMEPLAY_HINT_COLOR + "]").replace("[/b]", "[/color][/b]")

# end of file
