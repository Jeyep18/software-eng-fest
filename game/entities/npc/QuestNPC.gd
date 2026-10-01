class_name QuestNPC
extends NPC

const UI_STYLE = preload("res://game/ui/GameUIStyle.gd")

@export var quest_prompt: String = "Talk"

var _dialogue_completed: bool = false
var _choice_modal: Control = null
var _choice_body: Label = null
var _choice_accept_button: Button = null
var _choice_decline_button: Button = null
var _choice_paused_timer: bool = false
var _choice_source: String = ""
var _choice_values: Array = []
var _accept_source: String = "Accept"
var _decline_source: String = "Decline"

func _ready() -> void:
	super._ready()
	prompt_label = quest_prompt
	LocalizationManager.language_changed.connect(_refresh_choice_text)

func interact() -> void:
	if _choice_modal != null and _choice_modal.visible:
		return
	if _is_showing and not _is_typing and _current_sequence != null:
		_dialogue_completed = _current_line >= _current_sequence.lines.size() - 1
	super.interact()

func _hide_dialogue() -> void:
	super._hide_dialogue()
	if not _dialogue_completed:
		return
	_dialogue_completed = false
	_on_dialogue_completed()

func show_choice_prompt(body: String, accept_text: String = "Accept", decline_text: String = "Decline", values: Array = []) -> void:
	if _choice_modal == null:
		_build_choice_prompt()
	_choice_source = body
	_choice_values = values
	_accept_source = accept_text
	_decline_source = decline_text
	_refresh_choice_text()
	_choice_modal.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().call_group("hotbar_ui", "set_hotbar_visible", false)
	get_tree().call_group("player", "set_movement_locked", true)
	if not _choice_paused_timer:
		GlobalTimer.pause_timer(self)
		_choice_paused_timer = true

func _refresh_choice_text(_language_id: String = "") -> void:
	if _choice_body == null:
		return
	_choice_body.text = LocalizationManager.translate(_choice_source) if _choice_values.is_empty() else LocalizationManager.trf(_choice_source, _choice_values)
	_choice_accept_button.text = LocalizationManager.translate(_accept_source)
	_choice_decline_button.text = LocalizationManager.translate(_decline_source)

func _build_choice_prompt() -> void:
	_choice_modal = Control.new()
	_choice_modal.name = "ChoicePrompt"
	_choice_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_choice_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	%CanvasLayer.add_child(_choice_modal)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.02, 0.025, 0.03, 0.62)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_choice_modal.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_choice_modal.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 210)
	UI_STYLE.apply_panel(panel)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	margin.add_child(content)

	_choice_body = Label.new()
	_choice_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_choice_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI_STYLE.apply_label(_choice_body)
	content.add_child(_choice_body)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 14)
	content.add_child(actions)

	_choice_accept_button = Button.new()
	_choice_accept_button.custom_minimum_size = Vector2(140, 42)
	_choice_accept_button.pressed.connect(_accept_choice)
	UI_STYLE.apply_button(_choice_accept_button)
	actions.add_child(_choice_accept_button)

	_choice_decline_button = Button.new()
	_choice_decline_button.custom_minimum_size = Vector2(140, 42)
	_choice_decline_button.pressed.connect(_decline_choice)
	UI_STYLE.apply_button(_choice_decline_button)
	actions.add_child(_choice_decline_button)

	_choice_modal.hide()

func _close_choice_prompt() -> void:
	if _choice_modal != null:
		_choice_modal.hide()
	if _choice_paused_timer:
		GlobalTimer.resume_timer(self)
		_choice_paused_timer = false
	get_tree().call_group("hotbar_ui", "set_hotbar_visible", true)
	get_tree().call_group("player", "set_movement_locked", false)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _accept_choice() -> void:
	_close_choice_prompt()
	_on_choice_accepted()

func _decline_choice() -> void:
	_close_choice_prompt()
	_on_choice_declined()

func _on_dialogue_completed() -> void:
	pass

func _on_choice_accepted() -> void:
	pass

func _on_choice_declined() -> void:
	pass
