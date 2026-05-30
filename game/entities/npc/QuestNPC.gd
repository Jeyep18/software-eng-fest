class_name QuestNPC
extends NPC

@export var quest_prompt: String = "Talk"

var _dialogue_completed: bool = false

func _ready() -> void:
	super._ready()
	prompt_label = quest_prompt

func interact() -> void:
	if _is_showing and not _is_typing and _current_sequence != null:
		_dialogue_completed = _current_line >= _current_sequence.lines.size() - 1
	super.interact()

func _hide_dialogue() -> void:
	super._hide_dialogue()
	if not _dialogue_completed:
		return
	_dialogue_completed = false
	_on_dialogue_completed()

func _on_dialogue_completed() -> void:
	pass
