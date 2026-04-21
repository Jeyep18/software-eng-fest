# FILE: res://scripts/TaskObject.gd

class_name TaskObject
extends Interactable

@export var interaction_prompt: String = "Interact [E]"
@export var need: NeedsLog.Need = NeedsLog.Need.ROOF
@export var required_item_ids: Array[String] = []

@export var missing_lines: Array[String] = [
    "I need to get some supplies first."
]
@export var ready_lines: Array[String] = [
    "Alright, I have everything I need."
]

## Shown when the player interacts AFTER the task is already completed.
## Example: "Naayos na ang bubong. Okay na."
@export var completed_lines: Array[String] = [
    "It's already been fixed."
]

@export var chars_per_second: float = 20.0
@export var monologue_ui_scene: PackedScene

const PLAYER_NAME: String = "Player"

var _ui: MonologueUI = null
var _current_line: int = 0
var _is_showing: bool = false
var _is_typing: bool = false
var _tween: Tween = null
var _showing_ready_branch: bool = false

# Remembers if this task was completed this session.
# WHY: Once done, re-interacting should show completed_lines,
# not fall back into the missing branch.
var _is_completed: bool = false


func _ready() -> void:
	super._ready()
	prompt_label = interaction_prompt
	player_exited.connect(_on_player_left)
	_setup_ui()


func _setup_ui() -> void:
	if monologue_ui_scene == null:
		push_error("TaskObject: monologue_ui_scene not assigned on " + name)
		return
	_ui = monologue_ui_scene.instantiate() as MonologueUI
	%CanvasLayer.add_child(_ui)
	_ui.hide_ui()


func interact() -> void:
	if not _is_showing:
		_current_line = 0

		# CASE 1: Already completed — show the done dialogue.
		if _is_completed:
			_showing_ready_branch = false
			_show_line(completed_lines)
			return

		# CASE 2: Has all items — show ready branch.
		if _has_all_required_items():
			_showing_ready_branch = true
			_show_line(ready_lines)
			return

		# CASE 3: Missing items — discover need and show missing branch.
		_showing_ready_branch = false
		NeedsLog.discover(need)
		_show_line(missing_lines)
		return

	if _is_typing:
		_skip_to_line_end()
		return

	_current_line += 1

	# Pick the right line array based on current state.
	var lines: Array[String]
	if _is_completed:
		lines = completed_lines
	elif _showing_ready_branch:
		lines = ready_lines
	else:
		lines = missing_lines

	if _current_line >= lines.size():
		var was_ready_branch: bool = _showing_ready_branch
		_hide_monologue()
		if was_ready_branch:
			_complete_task()
		return

	_show_line(lines)


func _has_all_required_items() -> bool:
	for item_id in required_item_ids:
		if not _player_has_item(item_id):
			return false
	return true


func _player_has_item(item_id: String) -> bool:
	for item in InventoryManager.inventory:
		if item.item_id == item_id:
			return true
	return false


func _complete_task() -> void:
	for item_id in required_item_ids:
		for i in range(InventoryManager.inventory.size()):
			var item = InventoryManager.inventory[i]
			if item.item_id == item_id:
				if item.item_type == ItemData.ItemType.BRING_HOME \
				or item.item_type == ItemData.ItemType.USE_IN_PLACE \
				or item.item_type == ItemData.ItemType.COMBINE:
					InventoryManager.remove_item(i)
				break

	NeedsLog.resolve(need)
	# Mark as completed so future interactions show completed_lines.
	_is_completed = true
	print("TaskObject: Completed — ", NeedsLog.NEED_LABELS.get(need, str(need)))


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
