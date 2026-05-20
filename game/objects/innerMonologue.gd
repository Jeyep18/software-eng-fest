class_name InnerMonologue
extends Interactable

@export var interaction_prompt: String = "Interact [E]"
@export var monologue_lines: Array[String] = [
	"This is a box...",
	"I wonder what I can do with this..",
	"Maybe I can ask Mom"
]
@export var auto_dismiss: bool = false
@export var chars_per_second: float = 20.0
@export var monologue_ui_scene: PackedScene

const PLAYER_NAME: String = "Player"

var _ui: MonologueUI = null
var _current_line: int = 0
var _is_showing: bool = false
var _is_typing: bool = false
var _tween: Tween = null
var _paused_timer: bool = false

func _ready() -> void:
	super._ready()
	prompt_label = interaction_prompt
	player_exited.connect(_on_player_left)
	_setup_ui()

func _setup_ui() -> void:
	if monologue_ui_scene == null:
		push_error("InnerMonologue: monologue_ui_scene not assigned on " + name)
		return
	_ui = monologue_ui_scene.instantiate() as MonologueUI
	%CanvasLayer.add_child(_ui)
	_ui.hide_ui()

func interact() -> void:
	if not _is_showing:
		_current_line = 0
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
	if not _paused_timer:
		GlobalTimer.pause_timer()
		_paused_timer = true
	get_tree().call_group("player", "set_movement_locked", true)
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
	get_tree().call_group("player", "set_movement_locked", false)
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
	if auto_dismiss and _current_line >= monologue_lines.size() - 1:
		_hide_monologue()

func _on_player_left(_interactable: Interactable) -> void:
	_hide_monologue()
