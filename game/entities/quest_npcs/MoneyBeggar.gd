extends QuestNPC

@export var ask_sequence: DialogueSequence
@export var thanked_sequence: DialogueSequence
@export var donation_amount: int = 20

var _pending_donation: bool = false

func _ready() -> void:
	super._ready()
	prompt_label = "Talk"

func _pick_sequence() -> DialogueSequence:
	_pending_donation = false
	if GameState.grocery_donation_given:
		return thanked_sequence
	_pending_donation = true
	return ask_sequence

func _on_dialogue_completed() -> void:
	if _pending_donation:
		show_choice_prompt("Give PHP %d?" % donation_amount, "Give", "Sorry")

func _on_choice_accepted() -> void:
	if GameState.grocery_donation_given:
		return
	if GameState.spend_cash(donation_amount):
		GameState.grocery_donation_given = true
	_pending_donation = false

func _on_choice_declined() -> void:
	_pending_donation = false
