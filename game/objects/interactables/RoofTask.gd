extends TaskObject

@export var required_items: Array[String] = [
	"nails",
	"tarp",
	"hammer"
]

func _ready() -> void:
	super._ready()
	prompt_label = interaction_prompt
	required_item_ids = required_items
	_setup_ui()
