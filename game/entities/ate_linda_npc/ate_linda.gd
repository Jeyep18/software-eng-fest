class_name ShopPeople
extends NPC

@export var sequence_tindahan_default: DialogueSequence
@export var shop_path: String

var _dialogue_completed: bool = false

func _ready() -> void:
	super._ready()
	prompt_label = "Buy Materials"

func _pick_sequence() -> DialogueSequence:
	_dialogue_completed = false  # reset on each new conversation
	return sequence_tindahan_default

func interact() -> void:
	# Mark completion just before _hide_dialogue is called on last line
	if _is_showing and not _is_typing:
		var on_last_line: bool = (_current_line >= _current_sequence.lines.size() - 1)
		if on_last_line:
			_dialogue_completed = true
	super.interact()

func _hide_dialogue() -> void:
	super._hide_dialogue()
	if _dialogue_completed:
		_dialogue_completed = false
		var shop_resource = load(shop_path)
		ShopUi.open_shop(shop_resource)
