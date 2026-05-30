extends TradeShopNPC

@export var trade_offer_sequence: DialogueSequence
@export var trade_complete_sequence: DialogueSequence
@export var discounted_sequence: DialogueSequence
@export var no_hammer_sequence: DialogueSequence

var _should_complete_trade: bool = false
var _should_open_shop_after_dialogue: bool = true
var _dialogue_completed: bool = false

func _ready() -> void:
	super._ready()
	prompt_label = "Talk to Ate Linda"

func interact() -> void:
	if _is_showing and not _is_typing and _current_sequence != null:
		_dialogue_completed = _current_line >= _current_sequence.lines.size() - 1
	super.interact()

func _pick_sequence() -> DialogueSequence:
	_dialogue_completed = false
	_should_complete_trade = false
	_should_open_shop_after_dialogue = true

	if GameState.ate_linda_discount_unlocked:
		return discounted_sequence if discounted_sequence != null else sequence_tindahan_default

	if InventoryManager.has_item_with_id("hammer"):
		_should_complete_trade = true
		return trade_offer_sequence if trade_offer_sequence != null else sequence_tindahan_default

	_should_open_shop_after_dialogue = true
	return no_hammer_sequence if no_hammer_sequence != null else sequence_tindahan_default

func get_active_shop_path() -> String:
	if GameState.ate_linda_discount_unlocked and not discounted_shop_path.strip_edges().is_empty():
		return discounted_shop_path
	return shop_path

func _hide_dialogue() -> void:
	super._hide_dialogue()
	if not _dialogue_completed:
		return
	_dialogue_completed = false
	if _should_complete_trade:
		_complete_hammer_trade()
	if _should_open_shop_after_dialogue:
		open_active_shop()

func _complete_hammer_trade() -> void:
	if GameState.ate_linda_discount_unlocked:
		return
	if not InventoryManager.remove_item_by_id("hammer"):
		return
	GameState.ate_linda_discount_unlocked = true
