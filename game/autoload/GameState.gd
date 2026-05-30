# GameState.gd
# Autoload singleton — add to Project > Autoloads as "GameState"
extends Node

var collected_world_items: Array[String] = []
var player_name: String = ""
const STARTING_CASH: int = 0

enum Difficulty { STORY, STANDARD, CHALLENGE }

const DIFFICULTY_IDS: Dictionary = {
	Difficulty.STORY: "story",
	Difficulty.STANDARD: "standard",
	Difficulty.CHALLENGE: "challenge",
}

const DIFFICULTY_LABELS: Dictionary = {
	Difficulty.STORY: "Story",
	Difficulty.STANDARD: "Standard",
	Difficulty.CHALLENGE: "Challenge",
}

const DIFFICULTY_SECONDS_PER_MINUTE: Dictionary = {
	Difficulty.STORY: 2.0,
	Difficulty.STANDARD: 1.5,
	Difficulty.CHALLENGE: 0.8,
}

const DIFFICULTY_SCORE_MULTIPLIERS: Dictionary = {
	Difficulty.STORY: 0.85,
	Difficulty.STANDARD: 1.0,
	Difficulty.CHALLENGE: 1.25,
}

const DIFFICULTY_DEPARTURE_CASH: Dictionary = {
	Difficulty.STORY: 800,
	Difficulty.STANDARD: 700,
	Difficulty.CHALLENGE: 600,
}

var cash_balance: int = STARTING_CASH
var selected_difficulty: Difficulty = Difficulty.STANDARD
var nanay_departure_cash_granted: bool = false
var talked_to_lola: bool = false
var house_tasks_unlocked: bool = false
var house_exploration_complete: bool = false
var ate_linda_discount_unlocked: bool = false
var grocery_donation_given: bool = false
var tindahan_smoke_break_taken: bool = false

#region Act Tracking
enum Act { ACT_1, ACT_2, ACT_3, ACT_4 }
var current_act: Act = Act.ACT_1

func advance_act() -> void:
	if current_act < Act.ACT_4:
		current_act += 1
		act_changed.emit(current_act)
#endregion

#region Act 1 State Machine
enum Act1State {
	WAKE_UP,
	TV_BROADCAST,
	FAMILY_BREAKFAST,
	FREE_EXPLORE,
	DEPARTURE
}

var act1_state: Act1State = Act1State.WAKE_UP

func set_act1_state(new_state: Act1State) -> void:
	if act1_state == new_state:
		return
	act1_state = new_state
	act1_state_changed.emit(new_state)
#endregion

#region Outcome Variables (read by EndingResolver)
var tarp_applied: bool = false
var plywood_applied: bool = false
var rope_applied: bool = false
var medicine_obtained: bool = false
var first_aid_available: bool = false
var tatay_called: bool = false
var time_of_last_departure: int = 0   # in game-minutes
var child_sheltered_pre_storm: bool = false
var child_rescued_during_storm: bool = false
var corruption_evidence_found: bool = false
var corruption_evidence_shared: bool = false
#endregion

#region Signals
signal act_changed(new_act: Act)
signal act1_state_changed(new_state: Act1State)
signal player_name_set(name: String)
signal cash_changed(new_balance: int)
signal guide_tasks_changed
#endregion

#region Public API
func add_cash(amount: int) -> void:
	cash_balance += amount
	cash_changed.emit(cash_balance)

func spend_cash(amount: int) -> bool:
	if cash_balance < amount:
		return false   # not enough money — caller handles feedback
	cash_balance -= amount
	cash_changed.emit(cash_balance)
	return true

func get_cash() -> int:
	return cash_balance

func set_difficulty(difficulty: Difficulty) -> void:
	selected_difficulty = difficulty
	if get_node_or_null("/root/GlobalTimer") != null:
		GlobalTimer.apply_difficulty_settings()

func get_difficulty_id() -> String:
	return DIFFICULTY_IDS.get(selected_difficulty, "standard")

func get_difficulty_label() -> String:
	return DIFFICULTY_LABELS.get(selected_difficulty, "Standard")

func get_seconds_per_game_minute() -> float:
	return float(DIFFICULTY_SECONDS_PER_MINUTE.get(selected_difficulty, 1.5))

func get_departure_cash() -> int:
	return int(DIFFICULTY_DEPARTURE_CASH.get(selected_difficulty, 700))

func get_difficulty_score_multiplier(difficulty_id: String = "") -> float:
	if difficulty_id.is_empty():
		return float(DIFFICULTY_SCORE_MULTIPLIERS.get(selected_difficulty, 1.0))
	for difficulty in DIFFICULTY_IDS.keys():
		if DIFFICULTY_IDS[difficulty] == difficulty_id:
			return float(DIFFICULTY_SCORE_MULTIPLIERS.get(difficulty, 1.0))
	return 1.0

func complete_nanay_intro() -> void:
	if house_tasks_unlocked:
		return
	house_tasks_unlocked = true
	nanay_departure_cash_granted = true
	guide_tasks_changed.emit()

func complete_lola_intro() -> void:
	if talked_to_lola:
		return
	talked_to_lola = true
	guide_tasks_changed.emit()

func complete_house_exploration() -> void:
	if house_exploration_complete:
		return
	house_exploration_complete = true
	guide_tasks_changed.emit()

func set_player_name(new_name: String, gender: String = "kuya") -> void:
	if new_name.strip_edges().is_empty():
		push_warning("GameState: set_player_name called with empty string.")
		return
	player_name = new_name.strip_edges()
	player_name_set.emit(player_name)

func get_display_name() -> String:
	return player_name

func is_act1_complete() -> bool:
	return act1_state == Act1State.DEPARTURE

func reset() -> void:
	player_name = ""
	current_act = Act.ACT_1
	act1_state = Act1State.WAKE_UP
	tarp_applied = false
	plywood_applied = false
	rope_applied = false
	medicine_obtained = false
	first_aid_available = false
	tatay_called = false
	time_of_last_departure = 0
	child_sheltered_pre_storm = false
	child_rescued_during_storm = false
	corruption_evidence_found = false
	corruption_evidence_shared = false
	cash_balance = STARTING_CASH
	nanay_departure_cash_granted = false
	talked_to_lola = false
	house_tasks_unlocked = false
	house_exploration_complete = false
	ate_linda_discount_unlocked = false
	grocery_donation_given = false
	tindahan_smoke_break_taken = false
	collected_world_items.clear()
#endregion

func mark_item_collected(item_id: String) -> void:
	if not collected_world_items.has(item_id):
		collected_world_items.append(item_id)

func is_item_collected(item_id: String) -> bool:
	return collected_world_items.has(item_id)
