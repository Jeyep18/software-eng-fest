# FILE: res://resources/items/ItemData.gd
# PURPOSE: This is the "blueprint" for every item in the game.
# It is a Resource, meaning it holds pure DATA with no scene/node required.
# HOW TO USE: Create a new .tres file in the Inspector using this script,
# then fill in the item_name and icon in the Inspector panel.

@tool # Allows the icon preview to update live in the Godot editor
class_name ItemData
extends Resource

# --- EXPORTED PROPERTIES ---
# @export makes these fields visible and editable in the Godot Inspector.
# This is the "why": instead of hardcoding values in a script, a designer
# can just click a .tres file and change the icon or name visually.

## The display name of the item (e.g., "Banana", "Rusty Hammer")
@export var item_name: String = "Unnamed Item"

## The icon shown in the Hotbar and Backpack UI slots.
## Drag a .png or .svg from the FileSystem panel into this field.
@export var item_icon: Texture2D

## A short description, useful for tooltips later.
@export_multiline var item_description: String = ""

## Unique string ID used by EconomyManager and InventoryManager.
## Use snake_case. Must match GDD item IDs exactly.
## Examples: "tarp", "nails", "medicine", "canned_goods"
@export var item_id: String = ""

## Base purchase price in pesos (₱).
## Set to 0 if the item cannot be purchased with cash.
@export var item_price: int = 0

## If true, this item can be offered as a trade in barter events.
@export var can_barter: bool = false

## Item type — controls how it behaves in inventory and storm resolution.
enum ItemType {
	BRING_HOME,     # Carried home, used in storm resolution
	USE_IN_PLACE,   # Consumed at task site, slot freed immediately
	TOOL,           # Reusable, never consumed
	COMBINE,        # Must be combined with another item to be useful
	TRADE           # Exists only to be given away in a barter
}
@export var item_type: ItemType = ItemType.BRING_HOME

# --- PLACEHOLDER FUNCTION ---
# "func use()" is defined now but left empty intentionally.
# WHY: This is called "future-proofing." When you later want a banana
# to restore health, or a key to open a door, you override this function
# in a child Resource class. For the MVP, it does nothing.
func use() -> void:
	# Example future logic:
	# print(item_name + " was used!")
	pass
