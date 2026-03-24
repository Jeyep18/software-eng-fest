class_name InnerMonologue
extends Interactable

@export var interaction_prompt: String = "PRESS E NGANI"

## Each entry is one "page" of inner monologue. Supports BBCode tags ([wave], etc.)
@export var monologue_lines: Array[String] = [
	"Hello, I'm a box.",
	"I'm newly implemented.",
	"Please handle me well.",
	"Bye...",
]

## If true: auto-dismisses after the last line finishes typing.
## If false: player must press interact once more to close the last line.
@export var auto_dismiss: bool = false

## Typing speed in characters per second.
@export var chars_per_second: float = 20.0

var _current_line: int = 0
var _is_showing: bool = false
var _is_typing: bool = false
var _tween: Tween = null


#region Lifecycle
func _ready() -> void:
	super._ready()
	prompt_label = interaction_prompt
	player_exited.connect(_on_player_left)
	_hide_monologue()
#endregion


#region Interact Override
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
#endregion


#region Display
func _show_current_line() -> void:
	is_showing = true
	var line: String = monologue_lines[_current_line]
	
	%RichTextLabel.bbcode_enabled = true
	%RichTextLabel.text = line
	%RichTextLabel.visible_ratio = 0.0
	
	_is_showing = true
	_is_typing = true
	%BoxContainer.show()
	
	_update_line_counter()
	prompt_visibility_changed.emit(false)
	_run_typewriter(line)


func _run_typewriter(line: String) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	
	var duration: float = float(line.length()) / chars_per_second
	_tween = create_tween()
	_tween.tween_property(%RichTextLabel, "visible_ratio", 1.0, duration)
	_tween.finished.connect(_on_typewriter_finished, CONNECT_ONE_SHOT)


func _skip_to_line_end() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	%RichTextLabel.visible_ratio = 1.0
	_is_typing = false


func _hide_monologue() -> void:
	is_showing = false
	if _tween and _tween.is_valid():
		_tween.kill()
	%BoxContainer.hide()
	%RichTextLabel.visible_ratio = 0.0
	_is_showing = false
	_is_typing = false
	_current_line = 0
	prompt_visibility_changed.emit(true)


func _update_line_counter() -> void:
	if not is_instance_valid(%LineCounter):
		return
	if monologue_lines.size() > 1:
		%LineCounter.text = "%d / %d" % [_current_line + 1, monologue_lines.size()]
		%LineCounter.show()
	else:
		%LineCounter.hide()
#endregion


#region Signal Callbacks
func _on_typewriter_finished() -> void:
	_is_typing = false
	if auto_dismiss and _current_line >= monologue_lines.size() - 1:
		_hide_monologue()


func _on_player_left(_interactable: Interactable) -> void:
	_hide_monologue()
#endregion
