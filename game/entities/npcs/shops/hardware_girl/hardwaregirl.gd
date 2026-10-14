extends ShopPeople
@export var path: String

func _ready() -> void:
	super._ready()
	shop_path = path
	prompt_label = "Buy from Hardware"

func interact() -> void:
	super.interact()
