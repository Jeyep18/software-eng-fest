extends TaskObject

@export var required_items: Array[String] = [
	"working_radio",
	"working_flashlight"
]

func _ready() -> void:
	super._ready()
	prompt_label = interaction_prompt
	required_item_ids = required_items
