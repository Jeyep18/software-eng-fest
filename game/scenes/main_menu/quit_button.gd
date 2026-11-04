extends Button

const UI_STYLE = preload("res://game/ui/theme/GameUIStyle.gd")

var _overlay: CanvasLayer
var _panel: PanelContainer
var _margin: MarginContainer
var _title: Label
var _message: Label
var _cancel: Button
var _confirm: Button
var _quitting: bool = false

func _ready() -> void:
	_build_confirmation()
	pressed.connect(_open_confirmation)

func is_confirmation_open() -> bool:
	return _overlay.visible

func _open_confirmation() -> void:
	_layout_confirmation()
	_overlay.show()
	_cancel.grab_focus()

func _cancel_confirmation() -> void:
	_overlay.hide()
	grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if is_confirmation_open() and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if not _quitting:
			UI_STYLE.SFX.ui_cancel()
			_cancel_confirmation()

func _build_confirmation() -> void:
	_overlay = CanvasLayer.new()
	_overlay.name = "QuitConfirmation"
	_overlay.layer = 40
	_overlay.hide()
	add_child(_overlay)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.02, 0.025, 0.03, 0.82)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)

	_panel = PanelContainer.new()
	UI_STYLE.apply_panel(_panel)
	center.add_child(_panel)

	_margin = MarginContainer.new()
	_panel.add_child(_margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	_margin.add_child(content)

	_title = Label.new()
	_title.text = "Exit the game?"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI_STYLE.apply_label(_title, false, true)
	content.add_child(_title)

	_message = Label.new()
	_message.text = "Exit Bagyong Bahay?"
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_STYLE.apply_label(_message)
	content.add_child(_message)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 14)
	content.add_child(actions)

	_cancel = Button.new()
	_cancel.name = "Cancel"
	_cancel.text = "Cancel quit"
	_cancel.pressed.connect(_cancel_confirmation)
	UI_STYLE.SFX.wire_button(_cancel, true)
	UI_STYLE.apply_button(_cancel)
	actions.add_child(_cancel)

	_confirm = Button.new()
	_confirm.name = "Confirm"
	_confirm.text = "Confirm quit"
	_confirm.pressed.connect(_quit_game)
	UI_STYLE.apply_button(_confirm)
	actions.add_child(_confirm)

	for button in [_cancel, _confirm]:
		var other: Button = _confirm if button == _cancel else _cancel
		button.focus_next = button.get_path_to(other)
		button.focus_previous = button.focus_next
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			button.set_focus_neighbor(side, button.focus_next)

	get_viewport().size_changed.connect(_layout_confirmation)
	VisualSettings.ui_scale_changed.connect(_on_scale_changed)

func _layout_confirmation() -> void:
	var scale_factor := VisualSettings.get_ui_scale()
	_panel.custom_minimum_size.x = minf(510 * scale_factor, get_viewport().get_visible_rect().size.x - 48)
	for side in ["left", "top", "right", "bottom"]:
		_margin.add_theme_constant_override("margin_" + side, roundi(18 * scale_factor))
	_title.add_theme_font_size_override("font_size", roundi(30 * scale_factor))
	_message.add_theme_font_size_override("font_size", roundi(17 * scale_factor))
	for button in [_cancel, _confirm]:
		button.custom_minimum_size = Vector2(100, 36) * scale_factor
		button.add_theme_font_size_override("font_size", roundi(17 * scale_factor))

func _on_scale_changed(_scale: float) -> void:
	_layout_confirmation()

func _quit_game() -> void:
	if _quitting:
		return
	_quitting = true
	disabled = true
	_confirm.disabled = true
	_cancel.disabled = true
	await TransitionOverlay.fade_to_black()
	get_tree().quit()
