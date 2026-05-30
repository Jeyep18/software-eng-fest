extends QuestNPC

@export var offer_sequence: DialogueSequence
@export var done_sequence: DialogueSequence
@export var time_cost_minutes: int = 20

var _pending_smoke: bool = false

func _ready() -> void:
	super._ready()
	prompt_label = "Talk"

func _pick_sequence() -> DialogueSequence:
	_pending_smoke = false
	if GameState.tindahan_smoke_break_taken:
		return done_sequence
	_pending_smoke = true
	return offer_sequence

func _on_dialogue_completed() -> void:
	if _pending_smoke:
		show_choice_prompt("Smoke with him and lose %d minutes?" % time_cost_minutes, "Smoke", "No thanks")

func _on_choice_accepted() -> void:
	if GameState.tindahan_smoke_break_taken:
		return
	GameState.tindahan_smoke_break_taken = true
	get_tree().call_group("hotbar_ui", "set_hotbar_visible", false)
	get_tree().call_group("player", "set_movement_locked", true)
	await TransitionOverlay.fade_to_black()
	GlobalTimer.add_time(time_cost_minutes)
	await get_tree().create_timer(0.5).timeout
	await TransitionOverlay.fade_from_black()
	get_tree().call_group("player", "set_movement_locked", false)
	get_tree().call_group("hotbar_ui", "set_hotbar_visible", true)
	_pending_smoke = false

func _on_choice_declined() -> void:
	_pending_smoke = false
