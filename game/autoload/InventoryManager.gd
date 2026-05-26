# FILE: res://autoloads/InventoryManager.gd
# PURPOSE: Single source of truth for all inventory data.
# Handles add, remove, use, and combine operations.
# HOW TO REGISTER: Project > Project Settings > Autoload > select this file > name "InventoryManager"

extends Node

const DEBUG_LOGGING: bool = false

# --- CONSTANTS ---
const MAX_INVENTORY_SIZE: int = 7
const HOTBAR_SIZE: int = 7  # Hotbar IS the full inventory for this game

# --- SIGNALS ---
signal inventory_changed
signal item_combined(result_item: ItemData)  # Emitted when a combine succeeds
signal discard_changed

# --- DATA ---
var inventory: Array[ItemData] = []
var item_quantities: Array[int] = []
var discard_held_item: ItemData = null
var discard_held_quantity: int = 0

const STACKABLE_ITEM_IDS: Dictionary = {
	"canned_goods": 99,
	"nails": 99,
}

# --- COMBINE RECIPES ---
# Key format: "item_id_a+item_id_b" (always sorted alphabetically so order doesn't matter)
# Value: the item_id string of the result item
# WHY: Storing recipes here keeps all game logic in one place.
# The BackpackUI just asks "can these combine?" and gets a yes/no + result.
var _combine_recipes: Dictionary = {
	"batteries+dead_flashlight": "working_flashlight",
	"batteries+broken_radio": "working_radio",
}

# --- PUBLIC FUNCTIONS ---

func add_item(item: ItemData) -> bool:
	if item != null and _is_stackable(item.item_id):
		for i in range(inventory.size()):
			if inventory[i] != null and inventory[i].item_id == item.item_id:
				item_quantities[i] += 1
				inventory_changed.emit()
				return true

	if inventory.size() >= MAX_INVENTORY_SIZE:
		_debug_log("InventoryManager: Inventory is full.")
		return false
	inventory.append(item)
	item_quantities.append(1)
	inventory_changed.emit()
	return true

func remove_item(index: int) -> ItemData:
	if index < 0 or index >= inventory.size():
		push_error("InventoryManager: Invalid index: " + str(index))
		return null
	var removed = inventory[index]
	if item_quantities[index] > 1:
		item_quantities[index] -= 1
	else:
		inventory.remove_at(index)
		item_quantities.remove_at(index)
	inventory_changed.emit()
	return removed

func remove_item_quantity(index: int, amount: int) -> ItemData:
	if index < 0 or index >= inventory.size():
		push_error("InventoryManager: Invalid index: " + str(index))
		return null
	if amount <= 0:
		return inventory[index]
	var removed = inventory[index]
	item_quantities[index] -= amount
	if item_quantities[index] <= 0:
		inventory.remove_at(index)
		item_quantities.remove_at(index)
	inventory_changed.emit()
	return removed

func get_item_quantity(index: int) -> int:
	if index < 0 or index >= item_quantities.size():
		return 0
	return item_quantities[index]

func get_total_quantity(item_id: String) -> int:
	var total: int = 0
	for i in range(inventory.size()):
		if inventory[i] != null and inventory[i].item_id == item_id:
			total += item_quantities[i]
	return total

func _is_stackable(item_id: String) -> bool:
	return STACKABLE_ITEM_IDS.has(item_id)

func _remove_slot(index: int) -> ItemData:
	var removed = inventory[index]
	inventory.remove_at(index)
	item_quantities.remove_at(index)
	inventory_changed.emit()
	return removed

func move_item_to_discard(index: int) -> bool:
	if index < 0 or index >= inventory.size():
		push_error("InventoryManager: Invalid discard index: " + str(index))
		return false

	var incoming_item = inventory[index]
	var incoming_quantity = item_quantities[index]
	var discarded_item = discard_held_item
	inventory.remove_at(index)
	item_quantities.remove_at(index)
	discard_held_item = incoming_item
	discard_held_quantity = incoming_quantity

	inventory_changed.emit()
	discard_changed.emit()

	if discarded_item != null:
		_debug_log("InventoryManager: Discarded permanently: " + discarded_item.item_name)
	_debug_log("InventoryManager: Holding for discard: " + discard_held_item.item_name)
	return true

func restore_discard_item() -> bool:
	if discard_held_item == null:
		return false
	if inventory.size() >= MAX_INVENTORY_SIZE:
		_debug_log("InventoryManager: Inventory is full. Cannot restore discard item.")
		return false

	var restored_item = discard_held_item
	var restored_quantity = max(discard_held_quantity, 1)
	discard_held_item = null
	discard_held_quantity = 0
	inventory.append(restored_item)
	item_quantities.append(restored_quantity)

	inventory_changed.emit()
	discard_changed.emit()
	_debug_log("InventoryManager: Restored discard item: " + restored_item.item_name)
	return true

func remove_item_by_id(item_id: String) -> bool:
	for i in range(inventory.size()):
		if inventory[i].item_id == item_id:
			remove_item(i)
			return true
	return false

func use_item(index: int) -> void:
	if index < 0 or index >= inventory.size():
		return
	var item = inventory[index]
	item.use()
	remove_item(index)

# --- COMBINE SYSTEM ---

## Checks if two items (by index) can be combined.
## Returns the result item_id string, or "" if no recipe exists.
func get_combine_result(index_a: int, index_b: int) -> String:
	if index_a < 0 or index_a >= inventory.size():
		return ""
	if index_b < 0 or index_b >= inventory.size():
		return ""
	if index_a == index_b:
		return ""

	var id_a = inventory[index_a].item_id
	var id_b = inventory[index_b].item_id

	# Sort alphabetically so "batteries+dead_flashlight" == "dead_flashlight+batteries"
	var sorted_ids = [id_a, id_b]
	sorted_ids.sort()
	var key = sorted_ids[0] + "+" + sorted_ids[1]

	return _combine_recipes.get(key, "")

## Attempts to combine two items. Returns true if successful.
## The two source items are removed; the result item is added.
## result_item_data must be passed in (loaded by the UI from the .tres file).
func combine_items(index_a: int, index_b: int, result_item_data: ItemData) -> bool:
	if result_item_data == null:
		push_error("InventoryManager: combine_items called with null result data")
		return false

	# Remove higher index first to avoid shifting issues
	var higher = max(index_a, index_b)
	var lower  = min(index_a, index_b)
	_remove_slot(higher)
	_remove_slot(lower)

	# Add the combined result
	inventory.append(result_item_data)
	item_quantities.append(1)

	inventory_changed.emit()
	item_combined.emit(result_item_data)
	_debug_log("InventoryManager: Combined -> " + result_item_data.item_name)
	return true

# --- QUERIES ---

func get_all_items() -> Array[ItemData]:
	return inventory

func get_item_count() -> int:
	return inventory.size()

func is_full() -> bool:
	return inventory.size() >= MAX_INVENTORY_SIZE

func can_accept_item(item: ItemData) -> bool:
	if item == null:
		return false
	if _is_stackable(item.item_id):
		for inventory_item in inventory:
			if inventory_item != null and inventory_item.item_id == item.item_id:
				return true
	return not is_full()

func has_item_with_id(item_id: String) -> bool:
	for item in inventory:
		if item.item_id == item_id:
			return true
	return false

func reset() -> void:
	inventory.clear()
	item_quantities.clear()
	discard_held_item = null
	discard_held_quantity = 0
	inventory_changed.emit()
	discard_changed.emit()
	_debug_log("InventoryManager: Inventory cleared.")

func _debug_log(message: String) -> void:
	if DEBUG_LOGGING:
		print(message)
