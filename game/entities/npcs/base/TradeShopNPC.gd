class_name TradeShopNPC
extends NPC

@export var sequence_tindahan_default: DialogueSequence
@export var shop_path: String = ""
@export var discounted_shop_path: String = ""

func get_active_shop_path() -> String:
	return shop_path

func _pick_sequence() -> DialogueSequence:
	return sequence_tindahan_default

func open_active_shop() -> void:
	var active_path := get_active_shop_path()
	if active_path.strip_edges().is_empty():
		push_warning("TradeShopNPC: shop path is not assigned on " + name)
		return
	var shop_resource := load(active_path) as ShopData
	if shop_resource == null:
		push_error("TradeShopNPC: invalid ShopData path on %s: %s" % [name, active_path])
		return
	ShopUi.open_shop(shop_resource)
