extends TaskObject

const CHICKEN_READY_LINE := "This will do. There is enough for everyone."

func _get_active_lines() -> Array[String]:
	if not _is_completed and _showing_ready_branch and not _get_required_item_counts().has("canned_goods"):
		return [CHICKEN_READY_LINE]
	return super._get_active_lines()

func _get_required_item_counts() -> Dictionary:
	if InventoryManager.get_total_quantity("canned_goods") >= 4:
		return {"canned_goods": 4}
	if InventoryManager.get_total_quantity("whole_chicken") >= 1:
		return {"whole_chicken": 1}
	if InventoryManager.get_total_quantity("half_chicken") >= 2:
		return {"half_chicken": 2}
	return {"canned_goods": 4}
