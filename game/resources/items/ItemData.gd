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

# --- PLACEHOLDER FUNCTION ---
# "func use()" is defined now but left empty intentionally.
# WHY: This is called "future-proofing." When you later want a banana
# to restore health, or a key to open a door, you override this function
# in a child Resource class. For the MVP, it does nothing.
func use() -> void:
	# Example future logic:
	# print(item_name + " was used!")
	pass
