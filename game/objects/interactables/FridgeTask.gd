extends TaskObject

func _get_required_item_counts() -> Dictionary:
	if InventoryManager.get_total_quantity("canned_goods") >= 4:
		return {"canned_goods": 4}
	if InventoryManager.get_total_quantity("whole_chicken") >= 1:
		return {"whole_chicken": 1}
	if InventoryManager.get_total_quantity("half_chicken") >= 2:
		return {"half_chicken": 2}
	return {"canned_goods": 4}
