class_name Lola
extends NPC

@export var sequence_first_meeting: DialogueSequence
@export var sequence_hint_medicine: DialogueSequence
@export var sequence_hint_roof: DialogueSequence
@export var sequence_hint_food: DialogueSequence
@export var sequence_hint_all_done: DialogueSequence
var _has_met: bool = false

func _ready() -> void:
	super._ready()
	prompt_label = "Talk to Lola"

func _pick_sequence() -> DialogueSequence:
	if not _has_met:
		return sequence_first_meeting
	if not NeedsLog.is_discovered(NeedsLog.Need.MEDICINE):
		return sequence_hint_medicine
	if not NeedsLog.is_discovered(NeedsLog.Need.ROOF):
		return sequence_hint_roof
	if not NeedsLog.is_discovered(NeedsLog.Need.FOOD):
		return sequence_hint_food
	return sequence_hint_all_done

func _hide_dialogue() -> void:
	if not _has_met and _current_sequence == sequence_first_meeting:
		_has_met = true
		NeedsLog.discover(NeedsLog.Need.MEDICINE)
	super._hide_dialogue()
