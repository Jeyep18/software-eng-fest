# FILE: res://resources/items/ItemData.gd
@tool
class_name ItemData
extends Resource

@export var item_name: String = "Unnamed Item"
@export var item_icon: Texture2D
@export var item_description: String = ""
@export var item_id: String = ""
@export var item_price: int = 0
@export var can_barter: bool = false


@export var item_model: PackedScene


@export var pickup_lines: Array[String] = []

enum ItemType {
	BRING_HOME,
	USE_IN_PLACE,
	TOOL,
	COMBINE,
	TRADE
}
@export var item_type: ItemType = ItemType.BRING_HOME

func use() -> void:
	pass
