# FILE: res://scripts/NarrativeObject.gd
# ATTACH TO: The Area3D of any non-task interactable.
# PURPOSE: Universal script for objects that only play monologue
# and optionally discover a need. Configure everything in the Inspector.
# Examples: fridge, TV, photos, gas stove, window inspect, roof inspect.

class_name NarrativeObject
extends Interactable

# --- INSPECTOR CONFIGURATION ---

## The prompt shown when the player is nearby.
@export var interaction_prompt: String = "Interact [E]"

## The monologue lines to show when the player interacts.
@export var monologue_lines: Array[String] = []

## Optional: which Need this object discovers in NeedsLog.
## Leave as the default value if this object has no task effect.
## WHY: Some narrative objects (fridge, roof inspect, window inspect)
## also activate a task. Others (photos, santo nino) are flavour only.
@export var need_to_discover: NeedsLog.Need = NeedsLog.Need.FOOD
@export var discovers_need: bool = false

## If true, the monologue closes itself after the last line.
@export var auto_dismiss: bool = false

## Typewriter speed in characters per second.
@export var chars_per_second: float = 20.0

## Drag monologue_ui.tscn here.
@export var monologue_ui_scene: PackedScene

# --- INTERNALS ---
const PLAYER_NAME: String = "Player"

var _ui: MonologueUI = null
var _current_line: int = 0
var _is_showing: bool = false
var _is_typing: bool = false
var _tween: Tween = null
# Tracks if we already discovered the need this session.
# WHY: We only want NeedsLog.discover() to fire on first interaction,
# not every time the player re-reads the object.
var _need_discovered: bool = false


func _ready() -> void:
	super._ready()
	prompt_label = interaction_prompt
	player_exited.connect(_on_player_left)
	_setup_ui()


func _setup_ui() -> void:
	if monologue_ui_scene == null:
		push_error("NarrativeObject '" + name + "': monologue_ui_scene not assigned.")
		return
	_ui = monologue_ui_scene.instantiate() as MonologueUI
	%CanvasLayer.add_child(_ui)
	_ui.hide_ui()


func interact() -> void:
	if not _is_showing:
		_current_line = 0
		# Discover the need on first interaction only.
		if discovers_need and not _need_discovered:
			NeedsLog.discover(need_to_discover)
			_need_discovered = true
		_show_current_line()
		return

	if _is_typing:
		_skip_to_line_end()
		return

	_current_line += 1
	if _current_line >= monologue_lines.size():
		_hide_monologue()
		return

	_show_current_line()


func _show_current_line() -> void:
	get_tree().call_group("hotbar_ui", "set_hotbar_visible", false)
	is_showing = true
	_is_showing = true
	_is_typing = true

	var line: String = monologue_lines[_current_line]
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
	get_tree().call_group("hotbar_ui", "set_hotbar_visible", true)
	is_showing = false
	if _tween and _tween.is_valid():
		_tween.kill()
	_ui.hide_ui()
	_is_showing = false
	_is_typing = false
	_current_line = 0
	prompt_visibility_changed.emit(true)


func _on_typewriter_finished() -> void:
	_is_typing = false
	_ui.set_prompt_visible(true)
	if auto_dismiss and _current_line >= monologue_lines.size() - 1:
		_hide_monologue()


func _on_player_left(_interactable: Interactable) -> void:
	if _is_showing:
		_hide_monologue()
