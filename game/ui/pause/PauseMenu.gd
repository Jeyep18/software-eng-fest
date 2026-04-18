# PauseMenu.gd
extends CanvasLayer

@onready var resume_panel:    Control = $Panel/ContentArea/ResumePanel
@onready var checklist_panel: Control = $Panel/ContentArea/ChecklistPanel
@onready var controls_panel:  Control = $Panel/ContentArea/ControlsPanel
@onready var settings_panel:  Control = $Panel/ContentArea/SettingsPanel

var _pending_action: String = ""
var _all_panels: Array[Control] = []

func _ready() -> void:
	_all_panels = [
		resume_panel,
		checklist_panel,
		controls_panel,
		settings_panel,
	]
	hide()
	_show_panel(resume_panel)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			_close()
		else:
			_open()
		get_viewport().set_input_as_handled()

func _open() -> void:
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_show_panel(resume_panel)
	show()

func _close() -> void:
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false

func _show_panel(target: Control) -> void:
	for panel in _all_panels:
		panel.hide()
	target.show()

func _on_resume_btn_pressed() -> void:
	_close()

func _on_checklist_btn_pressed() -> void:
	_show_panel(checklist_panel)

func _on_controls_btn_pressed() -> void:
	_show_panel(controls_panel)

func _on_settings_btn_pressed() -> void:
	_show_panel(settings_panel)

func _on_restart_btn_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_btn_pressed() -> void:
	get_tree().paused = false
	SceneManager.load_scene("title")
