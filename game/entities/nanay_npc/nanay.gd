class_name Nanay
extends NPC

@export var sequence_act1_default: DialogueSequence
@export var sequence_after_roof_found: DialogueSequence

func _ready() -> void:
	super._ready()
	prompt_label = "Talk to Ate Linda"

func _pick_sequence() -> DialogueSequence:
	if NeedsLog.is_discovered(NeedsLog.Need.ROOF):
		return sequence_after_roof_found
	return sequence_act1_default
