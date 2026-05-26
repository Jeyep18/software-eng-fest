extends TaskObject

@export var required_items: Array[String] = [
	"tarp",
	"nails",
	"hammer",
]

func _ready() -> void:
	super._ready()
	prompt_label = interaction_prompt
	required_item_ids = required_items

func _play_completion_sfx() -> void:
	await _play_hammer_completion_sfx()
