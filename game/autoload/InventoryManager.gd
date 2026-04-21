# FILE: res://autoloads/InventoryManager.gd
# PURPOSE: Single source of truth for all inventory data.
# Handles add, remove, use, and combine operations.
# HOW TO REGISTER: Project > Project Settings > Autoload > select this file > name "InventoryManager"

extends Node

# --- CONSTANTS ---
const MAX_INVENTORY_SIZE: int = 8
const HOTBAR_SIZE: int = 8  # Hotbar IS the full inventory for this game

# --- SIGNALS ---
signal inventory_changed
signal item_combined(result_item: ItemData)  # Emitted when a combine succeeds

# --- DATA ---
var inventory: Array[ItemData] = []

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
	if inventory.size() >= MAX_INVENTORY_SIZE:
		print("InventoryManager: Inventory is full.")
		return false
	inventory.append(item)
	inventory_changed.emit()
	return true

func remove_item(index: int) -> ItemData:
	if index < 0 or index >= inventory.size():
		push_error("InventoryManager: Invalid index: " + str(index))
		return null
	var removed = inventory[index]
	inventory.remove_at(index)
	inventory_changed.emit()
	return removed

func remove_item_by_id(item_id: String) -> bool:
	for i in range(inventory.size()):
		if inventory[i].item_id == item_id:
			inventory.remove_at(i)
			inventory_changed.emit()
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
	inventory.remove_at(higher)
	inventory.remove_at(lower)

	# Add the combined result
	inventory.append(result_item_data)

	inventory_changed.emit()
	item_combined.emit(result_item_data)
	print("InventoryManager: Combined → ", result_item_data.item_name)
	return true

# --- QUERIES ---

func get_all_items() -> Array[ItemData]:
	return inventory

func get_item_count() -> int:
	return inventory.size()

func is_full() -> bool:
	return inventory.size() >= MAX_INVENTORY_SIZE

func has_item_with_id(item_id: String) -> bool:
	for item in inventory:
		if item.item_id == item_id:
			return true
	return false
