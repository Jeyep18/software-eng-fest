extends QuestNPC

@export var offer_sequence: DialogueSequence
@export var waiting_sequence: DialogueSequence
@export var complete_sequence: DialogueSequence
@export var full_inventory_sequence: DialogueSequence
@export var done_sequence: DialogueSequence
@export var tarp_reward: ItemData
@export var quest_cash_amount: int = 150
@export var sukli_amount: int = 5

var _pending_action: String = ""

func _ready() -> void:
	super._ready()
	prompt_label = "Talk to Mang Nestor"
	if not InventoryManager.inventory_changed.is_connected(_on_inventory_changed):
		InventoryManager.inventory_changed.connect(_on_inventory_changed)

func _pick_sequence() -> DialogueSequence:
	_pending_action = ""
	SideQuestLog.refresh_mang_nestor_chicken()
	var state := SideQuestLog.get_quest_state(SideQuestLog.QUEST_MANG_NESTOR_CHICKEN)

	if state == SideQuestLog.STATE_COMPLETED:
		return done_sequence

	if state == SideQuestLog.STATE_READY_TO_TURN_IN:
		if not InventoryManager.can_accept_item(tarp_reward):
			return full_inventory_sequence
		_pending_action = "complete"
		return complete_sequence

	if state == SideQuestLog.STATE_ACTIVE:
		return waiting_sequence

	_pending_action = "start"
	return offer_sequence

func _on_dialogue_completed() -> void:
	match _pending_action:
		"start":
			_start_quest()
		"complete":
			_complete_quest()
	_pending_action = ""

func _start_quest() -> void:
	SideQuestLog.start_mang_nestor_chicken()
	if not SideQuestLog.mang_nestor_money_given:
		GameState.add_cash(quest_cash_amount)
		SideQuestLog.mang_nestor_money_given = true
		get_tree().call_group("preparation_checklist_hud", "show_cash_gain", quest_cash_amount)

func _complete_quest() -> void:
	if tarp_reward == null:
		push_error("MangNestor: tarp_reward is not assigned.")
		return
	if not InventoryManager.has_item_with_id("half_chicken"):
		SideQuestLog.refresh_mang_nestor_chicken()
		return
	if not InventoryManager.can_accept_item(tarp_reward):
		return
	if not InventoryManager.remove_item_by_id("half_chicken"):
		return
	if not InventoryManager.add_item(tarp_reward):
		return
	if sukli_amount > 0:
		GameState.add_cash(sukli_amount)
		get_tree().call_group("preparation_checklist_hud", "show_cash_gain", sukli_amount)
	SideQuestLog.complete_mang_nestor_chicken()

func _on_inventory_changed() -> void:
	SideQuestLog.refresh_mang_nestor_chicken()
