extends TaskObject

@export var required_items: Array[String] = [
	"medicine",
]

func _ready() -> void:
	super._ready()
	prompt_label = interaction_prompt
	required_item_ids = required_items

func interact() -> void:
	super.interact()
