class_name ate_linda
extends NPC

@export var sequence_tindahan_default: DialogueSequence

func _ready() -> void:
	super._ready()
	prompt_label = "Talk to Ate Linda"

func _pick_sequence() -> DialogueSequence:
	return sequence_tindahan_default
