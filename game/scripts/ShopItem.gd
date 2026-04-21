# res://game/scripts/ShopItem.gd
class_name ShopItem
extends Resource

@export var item_data: ItemData
@export var price: int = 0

## -1 = unlimited stock. Any positive number = limited.
@export var stock: int = -1

func is_in_stock() -> bool:
	if stock == -1:
		return true
	return stock > 0

func consume_stock() -> void:
	if stock == -1:
		return
	stock = maxi(stock - 1, 0)

func reset_stock() -> void:
	pass  # stock resets when the .tres reloads on game restart
