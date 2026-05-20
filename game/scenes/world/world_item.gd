# FILE: res://scripts/WorldItem.gd
# ATTACH TO: The root Area3D node of WorldItem.tscn
# PURPOSE: A reusable, pickupable world item that:
#   1. Displays any 3D model assigned in its ItemData resource
#   2. Shows a monologue when picked up (using the shared MonologueUI)
#   3. Adds itself to the InventoryManager
#   4. Removes itself from the scene

# WHY extends Interactable:
# Your player already knows how to talk to Interactable objects.
# It connects signals, calls interact(), shows prompts — all automatically.
# By extending Interactable, WorldItem gets ALL of that for free.
class_name WorldItem
extends Interactable

# --- CONFIGURATION (set these in the Inspector) ---

@export var world_item_id: String = ""

## The data blueprint for this item. Drag a .tres file here.
@export var item_data: ItemData

## The MonologueUI scene. Drag monologue_ui.tscn here.
## WHY: Same as the Fridge — we instantiate our own copy of the UI
## so each item is self-contained and doesn't conflict with others.
@export var monologue_ui_scene: PackedScene

# --- CONSTANTS ---
# The speaker name shown in the monologue box during pickup.
# "Player" matches your existing fridge setup convention.
const SPEAKER_NAME: String = "Player"

# --- INTERNAL STATE ---
# Reference to the MonologueUI instance we create at runtime.
var _ui: MonologueUI = null

# Tracks which line of the pickup_lines array we're currently showing.
var _current_line: int = 0

# Whether the monologue is currently on screen.
var _is_showing: bool = false

# Whether the typewriter effect is still typing out text.
var _is_typing: bool = false

# Reference to the active tween (for the typewriter animation).
var _tween: Tween = null
var _paused_timer: bool = false

# --- READY ---
func _ready() -> void:
	# Always call super._ready() when extending a class.
	# WHY: This runs Interactable's _ready(), which connects the
	# body_entered/body_exited signals to your player system.
	# If you skip this, the player will never trigger this item.
	super._ready()

	# Safety check: warn loudly if no data was assigned.
	if item_data == null:
		push_warning("WorldItem at " + str(global_position) + " has no ItemData assigned!")
		return
	
	if world_item_id != "" and GameState.is_item_collected(world_item_id):
		queue_free()
		return

	# Set the prompt text the player sees when nearby.
	# This uses the inherited 'prompt_label' variable from Interactable.
	prompt_label = "Press E to pick up " + item_data.item_name

	# Load the 3D model if one is assigned in the ItemData.
	_load_model()

	# Set up the MonologueUI if pickup lines exist.
	# WHY: If the item has no pickup_lines, we skip the monologue entirely
	# and just pick up silently. No crashes, no empty dialogue boxes.
	if item_data.pickup_lines.size() > 0:
		_setup_ui()

	# Listen for when the player walks away mid-dialogue.
	# This uses the inherited signal from Interactable.
	player_exited.connect(_on_player_left)


# --- MODEL LOADING ---
func _load_model() -> void:
	# If no model is assigned in ItemData, there's nothing to load.
	if item_data.item_model == null:
		push_warning("WorldItem '" + item_data.item_name + "' has no item_model assigned.")
		return

	# Instantiate the PackedScene (the .glb file) into an actual node.
	# WHY: A PackedScene is just a blueprint (like ItemData is a blueprint).
	# .instantiate() creates a real, living copy of it in the scene.
	var model_instance = item_data.item_model.instantiate()

	# Add the model as a child of this WorldItem node.
	add_child(model_instance)

	# Optional: print confirmation during development so you know it worked.
	print("WorldItem: Loaded model for '" + item_data.item_name + "'")


# --- UI SETUP ---
func _setup_ui() -> void:
	if monologue_ui_scene == null:
		push_error("WorldItem '" + item_data.item_name + "': monologue_ui_scene not assigned!")
		return

	# Create the UI — same pattern as the Fridge script.
	_ui = monologue_ui_scene.instantiate() as MonologueUI

	# We need a CanvasLayer to hold the UI.
	# WHY: CanvasLayer keeps UI drawn on top of the 3D world, fixed to screen.
	# Without it, the UI would exist in 3D space and look broken.
	var canvas = CanvasLayer.new()
	add_child(canvas)
	canvas.add_child(_ui)

	_ui.hide_ui()


# --- INTERACT (called by the player system automatically) ---
# This is the function Interactable defines and your player calls.
# The player presses E → player calls interact() on the current Interactable.
func interact() -> void:
	# CASE 1: No pickup lines defined — skip monologue, pick up immediately.
	if item_data.pickup_lines.size() == 0:
		_do_pickup()
		return

	# CASE 2: Monologue not started yet — show the first line.
	if not _is_showing:
		_current_line = 0
		_show_current_line()
		return

	# CASE 3: Typewriter is still typing — skip to end of current line.
	if _is_typing:
		_skip_to_line_end()
		return

	# CASE 4: Move to next line.
	_current_line += 1

	# CASE 5: No more lines — monologue is done, pick up the item.
	if _current_line >= item_data.pickup_lines.size():
		_hide_monologue()
		_do_pickup()  # ← THIS is when the item actually gets picked up.
		return

	# Otherwise show the next line.
	_show_current_line()


# --- MONOLOGUE HELPERS ---
# These mirror the Fridge script exactly, just using item_data.pickup_lines.

func _show_current_line() -> void:
	if not _paused_timer:
		GlobalTimer.pause_timer()
		_paused_timer = true
	is_showing = true  # inherited from Interactable
	_is_showing = true
	_is_typing = true

	var line: String = item_data.pickup_lines[_current_line]
	_ui.show_line(line, SPEAKER_NAME)
	_ui.set_prompt_visible(false)
	prompt_visibility_changed.emit(false)

	if _tween and _tween.is_valid():
		_tween.kill()

	_tween = _ui.run_typewriter(20.0)  # 20 characters per second
	_tween.finished.connect(_on_typewriter_finished, CONNECT_ONE_SHOT)


func _skip_to_line_end() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_ui.skip_to_end()
	_ui.set_prompt_visible(true)
	_is_typing = false


func _hide_monologue() -> void:
	is_showing = false
	if _tween and _tween.is_valid():
		_tween.kill()
	_ui.hide_ui()
	_is_showing = false
	_is_typing = false
	_current_line = 0
	if _paused_timer:
		GlobalTimer.resume_timer()
		_paused_timer = false
	prompt_visibility_changed.emit(true)


func _on_typewriter_finished() -> void:
	_is_typing = false
	_ui.set_prompt_visible(true)


func _on_player_left(_interactable: Interactable) -> void:
	# If the player walks away during the monologue, close it.
	# The item stays in the world — they didn't finish reading.
	if _is_showing:
		_hide_monologue()


# --- THE ACTUAL PICKUP ---
func _do_pickup() -> void:
	if item_data == null:
		return

	var success = InventoryManager.add_item(item_data)

	if success:
		# ↓ ADD THIS before queue_free
		if world_item_id != "":
			GameState.mark_item_collected(world_item_id)
		queue_free()
	else:
		print("Inventory full! Cannot pick up: " + item_data.item_name)
