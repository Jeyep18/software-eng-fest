class_name Nanay1
extends NPC

@export var sequence_pre_departure: DialogueSequence
@export var sequence_return_early: DialogueSequence   # 0–4 hrs
@export var sequence_return_mid: DialogueSequence     # 4–8 hrs
@export var sequence_return_late: DialogueSequence    # 8+ hrs

var _has_departed: bool = false

func _ready() -> void:
	super._ready()
	prompt_label = "Talk to Nanay"

func _pick_sequence() -> DialogueSequence:
	if not _has_departed:
		# Pre-departure: always start with pre_departure.
		# Briefing is auto-chained in _hide_dialogue — never picked manually.
		return sequence_pre_departure
		notify_departed()
	var elapsed_hrs: float = GlobalTimer.elapsed_minutes / 60.0
	if elapsed_hrs >= 8.0:
		return sequence_return_late
	if elapsed_hrs >= 4.0:
		return sequence_return_mid
	return sequence_return_early
	

func _hide_dialogue() -> void:
	# When pre_departure finishes, chain directly into briefing.
	# Does NOT call super — keeps the UI alive and transitions seamlessly.
	if _current_sequence == sequence_pre_departure:
		_current_sequence = sequence_pre_departure
		_current_line = 0
		_show_current_line()
		_discover_all_needs()
		return

func _discover_all_needs() -> void:
	NeedsLog.discover(NeedsLog.Need.ROOF)
	NeedsLog.discover(NeedsLog.Need.MEDICINE)
	NeedsLog.discover(NeedsLog.Need.FOOD)
	NeedsLog.discover(NeedsLog.Need.WINDOWS)
	NeedsLog.discover(NeedsLog.Need.WATER)
	NeedsLog.discover(NeedsLog.Need.FLASHLIGHT)

	super._hide_dialogue()

func notify_departed() -> void:
	_has_departed = true
