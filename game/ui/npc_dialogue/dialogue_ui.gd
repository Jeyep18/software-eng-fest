class_name DialogueUI
extends Control

@onready var _speaker_name: Label = %SpeakerName
@onready var _speaker_dialogue: RichTextLabel = %SpeakerDialogue
@onready var _interact_prompt: Control = %InteractPrompt
@onready var _speaker_image: TextureRect = %SpeakerImage

const GAMEPLAY_HINT_COLOR: String = "#e0b45b"

func show_line(line: DialogueLine) -> void:
	AudioManager.play_voice(preload("res://game/assets/sfx/freesound_community-bllrr-text-loop-82399-FreesoundCommunityPixabay.mp3"), true)
	_speaker_name.text = line.speaker_name
	_speaker_dialogue.bbcode_enabled = true
	_speaker_dialogue.parse_bbcode(_format_dialogue_text(line.text))
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
	return tween


func skip_to_end() -> void:
	AudioManager.stop_voice()
	_speaker_dialogue.visible_ratio = 1.0


func set_prompt_visible(isVisible: bool) -> void:
	_interact_prompt.visible = isVisible


func hide_ui() -> void:
	hide()

func _format_dialogue_text(text: String) -> String:
	return text.replace("[b]", "[b][color=" + GAMEPLAY_HINT_COLOR + "]").replace("[/b]", "[/color][/b]")

# end of file
