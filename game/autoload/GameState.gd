# GameState.gd
# Autoload singleton — add to Project > Autoloads as "GameState"
extends Node

var collected_world_items: Array[String] = []
var player_name: String = ""
var cash_balance: int = 600

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
	cash_balance = 400
#endregion

func _ready() -> void:
	print("Starting cash: ₱", GameState.get_cash())

func mark_item_collected(item_id: String) -> void:
	if not collected_world_items.has(item_id):
		collected_world_items.append(item_id)

func is_item_collected(item_id: String) -> bool:
	return collected_world_items.has(item_id)
