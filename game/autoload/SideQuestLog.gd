extends Node

signal side_objectives_changed
signal side_objective_started(label: String)
signal side_objective_completed(label: String)

const QUEST_MANG_NESTOR_CHICKEN: String = "mang_nestor_chicken"

const STATE_NOT_STARTED: String = "not_started"
const STATE_ACTIVE: String = "active"
const STATE_READY_TO_TURN_IN: String = "ready_to_turn_in"
const STATE_COMPLETED: String = "completed"

var mang_nestor_money_given: bool = false

var _quest_states: Dictionary = {
	QUEST_MANG_NESTOR_CHICKEN: STATE_NOT_STARTED,
}

func _ready() -> void:
	if not InventoryManager.inventory_changed.is_connected(_on_inventory_changed):
		InventoryManager.inventory_changed.connect(_on_inventory_changed)

func start_mang_nestor_chicken() -> void:
	if get_quest_state(QUEST_MANG_NESTOR_CHICKEN) != STATE_NOT_STARTED:
		return
	_quest_states[QUEST_MANG_NESTOR_CHICKEN] = STATE_ACTIVE
	side_objective_started.emit("Buy Half Chicken for Mang Nestor")
	side_objectives_changed.emit()

func refresh_mang_nestor_chicken() -> void:
	var state := get_quest_state(QUEST_MANG_NESTOR_CHICKEN)
	if state != STATE_ACTIVE and state != STATE_READY_TO_TURN_IN:
		return

	var next_state := STATE_READY_TO_TURN_IN if InventoryManager.has_item_with_id("half_chicken") else STATE_ACTIVE
	if state == next_state:
		return
	_quest_states[QUEST_MANG_NESTOR_CHICKEN] = next_state
	side_objectives_changed.emit()

func complete_mang_nestor_chicken() -> void:
	if get_quest_state(QUEST_MANG_NESTOR_CHICKEN) == STATE_COMPLETED:
		return
	_quest_states[QUEST_MANG_NESTOR_CHICKEN] = STATE_COMPLETED
	side_objective_completed.emit("Return to Mang Nestor")
	side_objectives_changed.emit()

func get_quest_state(quest_id: String) -> String:
	return str(_quest_states.get(quest_id, STATE_NOT_STARTED))

func get_active_objectives() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var state := get_quest_state(QUEST_MANG_NESTOR_CHICKEN)
	match state:
		STATE_ACTIVE:
			result.append({
				"key": "side_mang_nestor_buy",
				"label": "Buy Half Chicken for Mang Nestor",
			})
		STATE_READY_TO_TURN_IN:
			result.append({
				"key": "side_mang_nestor_return",
				"label": "Return to Mang Nestor",
			})
	return result

func reset() -> void:
	mang_nestor_money_given = false
	_quest_states = {
		QUEST_MANG_NESTOR_CHICKEN: STATE_NOT_STARTED,
	}
	side_objectives_changed.emit()

func _on_inventory_changed() -> void:
	refresh_mang_nestor_chicken()
