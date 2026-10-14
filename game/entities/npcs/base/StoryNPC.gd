class_name StoryNPC
extends NPC

@export var story_prompt: String = "Talk"

func _ready() -> void:
	super._ready()
	prompt_label = story_prompt
