class_name NPC
extends Interactable

@export var dialogue_ui_scene: PackedScene
## Fallback if no condition matches.
@export var default_sequence: DialogueSequence
@export var chars_per_second: float = 20.0

var _ui: DialogueUI = null
var _current_sequence: DialogueSequence = null
var _current_line: int = 0
var _is_showing: bool = false
var _is_typing: bool = false
var _tween: Tween = null


#region Lifecycle
func _ready() -> void:
	super._ready()
	prompt_label = "Talk"
	player_exited.connect(_on_player_left)
	_setup_ui()


func _setup_ui() -> void:
	if dialogue_ui_scene == null:
		push_error("NPC: dialogue_ui_scene is not assigned on " + name)
		return
	
	_ui = dialogue_ui_scene.instantiate() as DialogueUI
	# Rendered on CanvasLayer so it draws on top of the 3D world.
	%CanvasLayer.add_child(_ui)
	_ui.hide_ui()
#endregion


#region Interact Override
func interact() -> void:
	if not _is_showing:
		_current_sequence = _pick_sequence()
		if _current_sequence == null or _current_sequence.lines.is_empty():
			return
		_current_line = 0
		_show_current_line()
		return
	
	if _is_typing:
		_skip_to_line_end()
		return
	
	_current_line += 1
	if _current_line >= _current_sequence.lines.size():
		_hide_dialogue()
		return
	
	_show_current_line()
#endregion


#region Display
func _show_current_line() -> void:
	get_tree().call_group("hotbar_ui", "set_hotbar_visible", false)
	is_showing = true
	var line: DialogueLine = _current_sequence.lines[_current_line]
	_ui.show_line(line)
	_ui.set_prompt_visible(false)
	
	_is_showing = true
	_is_typing = true
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


func _hide_dialogue() -> void:
	get_tree().call_group("hotbar_ui", "set_hotbar_visible", true)
	is_showing = false
	if _tween and _tween.is_valid():
		_tween.kill()
	_ui.hide_ui()
	_is_showing = false
	_is_typing = false
	_current_line = 0
	prompt_visibility_changed.emit(true)
#endregion


#region Sequence Selection
## Override in subclasses to implement conditional sequence picking.
func _pick_sequence() -> DialogueSequence:
	return default_sequence
#endregion


#region Signal Callbacks
func _on_typewriter_finished() -> void:
	_is_typing = false
	_ui.set_prompt_visible(true)


func _on_player_left(_interactable: Interactable) -> void:
	_hide_dialogue()
#endregion
