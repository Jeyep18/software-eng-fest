# FILE: res://scripts/WorldItem.gd
# ATTACH TO: The root Area3D node of WorldItem.tscn
# PURPOSE: 3D version of the world item pickup script.
# The logic is identical to the 2D version — only node types change.

extends Area3D  # ← CHANGED from Area2D

# --- CONFIGURATION ---
@export var item_data: ItemData

# --- INTERNAL STATE ---
var _player_in_range: bool = false

# --- READY ---
func _ready() -> void:
	if item_data == null:
		push_warning("WorldItem at " + str(global_position) + " has no ItemData assigned!")
		return

	# Set the visual. If using Sprite3D, assign the icon texture.
	# If using MeshInstance3D with a material, you'd set the albedo texture instead.
	var sprite = $MeshInstance3D  # ← CHANGED from $Sprite2D
	if sprite and item_data.item_icon:
		sprite.texture = item_data.item_icon

	# Connect Area3D's signals — same names, same behavior, just 3D bodies now.
	# WHY: Area3D emits "body_entered" when a PhysicsBody3D (your CharacterBody3D
	# player) overlaps its CollisionShape3D. Identical concept to Area2D.
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if has_node("InteractLabel"):
		$InteractLabel.visible = false


# --- INPUT ---
func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range and event.is_action_pressed("interact"):
		_pickup()


# --- SIGNAL HANDLERS ---
func _on_body_entered(body: Node3D) -> void:  # ← CHANGED: Node3D not Node2D
	if body.is_in_group("player"):
		_player_in_range = true
		if has_node("InteractLabel"):
			$InteractLabel.visible = true


func _on_body_exited(body: Node3D) -> void:   # ← CHANGED: Node3D not Node2D
	if body.is_in_group("player"):
		_player_in_range = false
		if has_node("InteractLabel"):
			$InteractLabel.visible = false


# --- PICKUP LOGIC ---
func _pickup() -> void:
	if item_data == null:
		return

	var success = InventoryManager.add_item(item_data)

	if success:
		queue_free()
	else:
		print("Inventory full! Cannot pick up: " + item_data.item_name)
