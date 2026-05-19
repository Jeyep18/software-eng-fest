class_name Nanay1
extends NPC

@export var sequence_pre_departure: DialogueSequence
@export var sequence_return_early: DialogueSequence
@export var sequence_return_mid: DialogueSequence
@export var sequence_return_late: DialogueSequence
@export var cash_to_grant: int = 600

func _ready() -> void:
	super._ready()
	prompt_label = "Talk to Nanay"

func _pick_sequence() -> DialogueSequence:
	if not GameState.house_tasks_unlocked:
		return sequence_pre_departure

	var elapsed_hrs: float = GlobalTimer.current_minutes / 60.0
	if elapsed_hrs >= 8.0:
		return sequence_return_late
	if elapsed_hrs >= 4.0:
		return sequence_return_mid
	return sequence_return_early

func _hide_dialogue() -> void:
	var completed_pre_departure := (
		_current_sequence == sequence_pre_departure
		and _current_sequence != null
		and _current_line >= _current_sequence.lines.size()
	)
	if completed_pre_departure:
		_grant_departure_cash()

	super._hide_dialogue()

func _grant_departure_cash() -> void:
	if GameState.nanay_departure_cash_granted:
		return
	GameState.add_cash(cash_to_grant)
	GameState.complete_nanay_intro()

func notify_departed() -> void:
	GameState.complete_nanay_intro()
