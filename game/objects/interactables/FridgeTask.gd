extends TaskObject

@export var required_items: Array[String] = [
	"canned_goods",
	"canned_goods",
	"canned_goods",
	"canned_goods",
]

func _ready() -> void:
	super._ready()
	prompt_label = interaction_prompt
	required_item_ids = required_items
	player_exited.connect(_on_player_left)
	_setup_ui()
