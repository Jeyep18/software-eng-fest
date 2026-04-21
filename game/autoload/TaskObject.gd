# FILE: res://scripts/TaskObject.gd
# ATTACH TO: The Area3D node of any fixable object (roof, windows, etc.)
# PURPOSE: An interactable object that requires specific items to "complete."
# It checks the inventory, plays different monologues based on what the
# player has, consumes items on completion, and updates NeedsLog.

class_name TaskObject
extends Interactable

# --- CONFIGURATION (set all of these in the Inspector) ---

## The prompt shown when player is nearby.
@export var interaction_prompt: String = "Interact [E]"

## The Need this object maps to in NeedsLog.
## Example: NeedsLog.Need.ROOF
@export var need: NeedsLog.Need = NeedsLog.Need.ROOF

## The item_id strings required to complete this task.
## Must match item_id fields in your .tres files exactly.
## Example: ["plywood", "nails"]
@export var required_item_ids: Array[String] = []

## Monologue shown when player does NOT have the required items yet.
## This also discovers the need in NeedsLog (adds it to the HUD).
@export var missing_lines: Array[String] = [
    "I need to get some supplies first."
]

## Monologue shown when player HAS all required items.
## After this finishes, items are consumed and the need is resolved.
@export var ready_lines: Array[String] = [
    "Alright, I have everything I need."
]

## Speed of the typewriter text effect.
@export var chars_per_second: float = 20.0

## Drag monologue_ui.tscn here in the Inspector.
@export var monologue_ui_scene: PackedScene

# --- INTERNAL STATE ---
const PLAYER_NAME: String = "Player"

var _ui: MonologueUI = null
var _current_line: int = 0
var _is_showing: bool = false
var _is_typing: bool = false
var _tween: Tween = null

# Tracks which branch we're currently showing.
# WHY: When the player presses E mid-monologue, we need to know
# whether we're in the "missing" branch or the "ready" branch
# so we know what to do when the last line finishes.
var _showing_ready_branch: bool = false


# --- READY ---
func _ready() -> void:
	super._ready()
	prompt_label = interaction_prompt
	player_exited.connect(_on_player_left)
	_setup_ui()


# --- UI SETUP ---
func _setup_ui() -> void:
	if monologue_ui_scene == null:
		push_error("TaskObject: monologue_ui_scene not assigned on " + name)
		return
	_ui = monologue_ui_scene.instantiate() as MonologueUI
	%CanvasLayer.add_child(_ui)
	_ui.hide_ui()


# --- INTERACT ---
# Called automatically by the player system when E is pressed.
func interact() -> void:
	# If monologue is not yet showing, decide which branch to start.
	if not _is_showing:
		_current_line = 0
		if _has_all_required_items():
			_showing_ready_branch = true
			_show_line(ready_lines)
		else:
			_showing_ready_branch = false
			# Discover the need — this adds it to the HUD task list.
			# WHY: We only call this on the "missing" branch. Once the
			# player has the items, the task is about to be resolved,
			# so there's no point discovering it again.
			NeedsLog.discover(need)
			_show_line(missing_lines)
		return

	# If typewriter is still typing, skip to end of current line.
	if _is_typing:
		_skip_to_line_end()
		return

	# Advance to next line.
	_current_line += 1

	# Determine which line array we're working with.
	var lines: Array[String] = ready_lines if _showing_ready_branch else missing_lines

	# If we've passed the last line, the monologue is done.
	if _current_line >= lines.size():
		_hide_monologue()
		# If we just finished the ready branch, complete the task.
		if _showing_ready_branch:
			_complete_task()
		return

	_show_line(lines)


# --- ITEM CHECKING ---
# Returns true only if the player has ALL required items.
func _has_all_required_items() -> bool:
	for item_id in required_item_ids:
		if not _player_has_item(item_id):
			return false
	return true


# Checks if a single item_id exists anywhere in the inventory.
func _player_has_item(item_id: String) -> bool:
	for item in InventoryManager.inventory:
		if item.item_id == item_id:
			return true
	return false


# --- TASK COMPLETION ---
func _complete_task() -> void:
	# Consume each required item if its ItemType is BRING_HOME.
	# TOOL items are reusable and are NOT consumed.
	# WHY: This uses your existing ItemType enum from ItemData.gd.
	for item_id in required_item_ids:
		for i in range(InventoryManager.inventory.size()):
			var item = InventoryManager.inventory[i]
			if item.item_id == item_id:
				if item.item_type == ItemData.ItemType.BRING_HOME \
				or item.item_type == ItemData.ItemType.USE_IN_PLACE \
				or item.item_type == ItemData.ItemType.COMBINE:
					InventoryManager.remove_item(i)
				# Stop after consuming the first match for this id.
				break

	# Mark the need as resolved in NeedsLog.
	# This emits need_resolved signal → HUD removes the task entry.
	NeedsLog.resolve(need)

	print("TaskObject: Completed task for need: ", NeedsLog.NEED_LABELS.get(need, str(need)))


# --- MONOLOGUE HELPERS ---
# These are identical to fridge.gd — same pattern, same behaviour.

func _show_line(lines: Array[String]) -> void:
	is_showing = true
	_is_showing = true
	_is_typing = true

	var line: String = lines[_current_line]
	_ui.show_line(line, PLAYER_NAME)
	_ui.set_prompt_visible(false)
	prompt_visibility_changed.emit(false)

	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = _ui.run_typewriter(chars_per_second)
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
	_showing_ready_branch = false
	prompt_visibility_changed.emit(true)


func _on_typewriter_finished() -> void:
	_is_typing = false
	_ui.set_prompt_visible(true)


func _on_player_left(_interactable: Interactable) -> void:
	if _is_showing:
		_hide_monologue()
