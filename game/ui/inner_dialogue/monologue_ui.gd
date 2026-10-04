class_name MonologueUI
extends Control

@onready var _speaker_name: Label = %SpeakerName
@onready var _speaker_dialog: RichTextLabel = %SpeakerDialougue
@onready var _interact_prompt: Control = %InteractPrompt
@onready var _outer_margin: MarginContainer = $OuterMargin
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
	var side_margin := maxf(24.0, (viewport_size.x - 1120.0 * ui_scale) * 0.5)
	var left_margin := maxf(side_margin, minf(viewport_size.x * 0.24, 240.0 * setting_scale))
	var right_margin := maxf(24.0, viewport_size.x - left_margin - 1120.0 * ui_scale)
	_outer_margin.add_theme_constant_override("margin_left", roundi(left_margin))
	_outer_margin.add_theme_constant_override("margin_right", roundi(right_margin))
	_speaker_image.custom_minimum_size = Vector2(150, 150) * ui_scale
	_speaker_name.add_theme_font_size_override("font_size", roundi(22.0 * ui_scale))
	for style in ["normal", "bold", "bold_italics", "italics", "mono"]:
		_speaker_dialog.add_theme_font_size_override(style + "_font_size", roundi(24.0 * ui_scale))
	_interact_prompt.add_theme_font_size_override("font_size", roundi(18.0 * ui_scale))

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

# Keep the public parameter name; this sets visibility rather than querying it.
@warning_ignore("shadowed_variable_base_class")
func set_prompt_visible(is_visible: bool) -> void:
	_interact_prompt.visible = is_visible

func hide_ui() -> void:
	AudioManager.stop_voice()
	hide()

func _format_dialogue_text(text: String) -> String:
	return text.replace("[b]", "[b][color=" + GAMEPLAY_HINT_COLOR + "]").replace("[/b]", "[/color][/b]")
