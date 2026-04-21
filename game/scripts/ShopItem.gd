# ShopItem.gd
# A single entry in a ShopData catalogue.
# Attach an ItemData resource + set the price here.
# The price on ShopItem OVERRIDES item_data.item_price so each shop
# can sell the same item at a different (e.g. inflated) price.
class_name ShopItem
extends Resource

## The item being sold.
@export var item_data: ItemData

## Price displayed and charged in this shop.
## Set this to the inflated / standard price per location.
## If 0, the item is listed but cannot be purchased with cash
## (i.e. barter-only — show a lock icon in the UI).
@export var price: int = 0

## Optional: maximum number of times this item can be bought.
## -1 = unlimited.
@export var stock: int = -1

## Internal runtime stock counter (not exported — managed at runtime).
var _remaining_stock: int = -1

func _init() -> void:
	_remaining_stock = stock

## Returns true if the item is still available to buy.
func is_in_stock() -> bool:
	if stock == -1:
		return true
	return _remaining_stock > 0

## Call when a purchase succeeds. Decrements stock.
func consume_stock() -> void:
	if stock == -1:
		return
	_remaining_stock = maxi(_remaining_stock - 1, 0)

## Reset stock to initial value (call on game reset).
func reset_stock() -> void:
	_remaining_stock = stock
