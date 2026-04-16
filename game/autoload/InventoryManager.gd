# FILE: res://autoloads/InventoryManager.gd
# PURPOSE: The single source of truth for all inventory data.
# This script is loaded as an Autoload/Singleton. It manages the items
# array and emits signals so the UI knows when to redraw itself.
# HOW TO REGISTER: Go to Project > Project Settings > Autoload,
# click the folder icon, select this file, and name it "InventoryManager".

extends Node

# --- CONSTANTS ---
# The maximum number of items the player can carry in total.
const MAX_INVENTORY_SIZE: int = 8

# The number of slots shown in the hotbar (the quick-access bar).
# Hotbar items are always inventory[0] through inventory[HOTBAR_SIZE - 1].
const HOTBAR_SIZE: int = 8

# --- SIGNALS ---
# WHY SIGNALS? This is the key architectural decision.
# The InventoryManager should NOT know about the UI nodes directly.
# Instead, it "announces" that data changed, and the UI "listens."
# This decouples data from visuals — a core principle of good game architecture.
# When the inventory changes, we emit this signal. Any UI that connected
# to it will automatically receive the notification to redraw.
signal inventory_changed

# --- DATA ---
# The master array. Every item the player carries lives here.
# Index 0-4 = Hotbar slots (what HOTBAR_SIZE defines).
# Index 5+ = Backpack overflow slots.
# WHY a flat Array? Simple to implement for an MVP. Easy to iterate over.
var inventory: Array[ItemData] = []


# --- PUBLIC FUNCTIONS ---
# These are the functions other scripts will call.

## Attempts to add an item to the inventory.
## Returns TRUE if successful, FALSE if inventory is full.
func add_item(item: ItemData) -> bool:
	# Check capacity BEFORE adding anything.
	if inventory.size() >= MAX_INVENTORY_SIZE:
		print("InventoryManager: Inventory is full.")
		return false  # Signal to the WorldItem that pickup failed.

	# Add the ItemData resource to our array.
	inventory.append(item)
	print("InventoryManager: Added '" + item.item_name + "'. Total: " + str(inventory.size()))

	# Announce to all listeners (UI nodes) that the data has changed.
	# WHY: The UI didn't add the item — we did. So we must tell the UI.
	inventory_changed.emit()

	return true  # Signal to the WorldItem that pickup succeeded.


## Removes an item at a specific index.
## Returns the removed ItemData, or null if the index was invalid.
func remove_item(index: int) -> ItemData:
	if index < 0 or index >= inventory.size():
		push_error("InventoryManager: Tried to remove item at invalid index: " + str(index))
		return null

	var removed_item: ItemData = inventory[index]
	inventory.remove_at(index)

	print("InventoryManager: Removed '" + removed_item.item_name + "'.")
	inventory_changed.emit()  # Tell the UI to redraw.

	return removed_item


## Uses an item at a specific index (calls its use() function and removes it).
func use_item(index: int) -> void:
	if index < 0 or index >= inventory.size():
		return

	var item: ItemData = inventory[index]
	item.use()  # Call the item's custom use logic (currently a placeholder).
	remove_item(index)


# --- COMPUTED VIEWS ---
# These functions provide "views" of the same data array.
# WHY: The Hotbar UI only cares about the first 5 items. The Backpack
# UI cares about all items. Instead of two separate arrays (which would
# get out of sync), we use one array and slice it differently for each view.

## Returns only the hotbar items (first HOTBAR_SIZE items, or fewer).
func get_hotbar_items() -> Array[ItemData]:
	# The min() call prevents us from going out of bounds if we have fewer
	# than HOTBAR_SIZE items. e.g., if we have 2 items, min(2, 5) = 2.
	var hotbar_end: int = min(inventory.size(), HOTBAR_SIZE)
	return inventory.slice(0, hotbar_end)


## Returns ALL items (used by the Backpack UI for the full picture).
func get_all_items() -> Array[ItemData]:
	return inventory


## Returns the total count of items.
func get_item_count() -> int:
	return inventory.size()


## Checks if the inventory has room for more items.
func is_full() -> bool:
	return inventory.size() >= MAX_INVENTORY_SIZE
