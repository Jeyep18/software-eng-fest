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
