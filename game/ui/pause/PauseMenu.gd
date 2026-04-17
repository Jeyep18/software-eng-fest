# PauseMenu.gd
extends CanvasLayer

# ── Panel references ────────────────────────────────────────────────────────
@onready var resume_panel:    Control = $Panel/ContentArea/ResumePanel
@onready var checklist_panel: Control = $Panel/ContentArea/ChecklistPanel
@onready var controls_panel:  Control = $Panel/ContentArea/ControlsPanel
@onready var settings_panel:  Control = $Panel/ContentArea/SettingsPanel

# ── Confirm overlay (for Restart / Quit) ────────────────────────────────────
@onready var confirm_overlay: Control = $Panel/ConfirmOverlay
@onready var confirm_title:   Label   = $Panel/ConfirmOverlay/Box/Title
@onready var confirm_sub:     Label   = $Panel/ConfirmOverlay/Box/Subtitle
@onready var confirm_yes:     Button  = $Panel/ConfirmOverlay/Box/Buttons/YesBtn
@onready var confirm_no:      Button  = $Panel/ConfirmOverlay/Box/Buttons/NoBtn

var _pending_action: String = ""
var _all_panels: Array[Control] = []

# ── Ready ────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_all_panels = [
		resume_panel,
		checklist_panel,
		controls_panel,
		settings_panel,
	]
	hide()
	confirm_overlay.hide()
	_show_panel(resume_panel)

# ── Input — ESC toggles pause ─────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			_close()
		else:
			_open()
		get_viewport().set_input_as_handled()

# ── Open / Close ─────────────────────────────────────────────────────────────
func _open() -> void:
	get_tree().paused = true
	_show_panel(resume_panel)
	confirm_overlay.hide()
	show()

func _close() -> void:
	hide()
	get_tree().paused = false

# ── Panel switching ───────────────────────────────────────────────────────────
func _show_panel(target: Control) -> void:
	for panel in _all_panels:
		panel.hide()
	target.show()

# ── Sidebar button signals ────────────────────────────────────────────────────
func _on_resume_btn_pressed() -> void:
	_close()

func _on_checklist_btn_pressed() -> void:
	_show_panel(checklist_panel)

func _on_controls_btn_pressed() -> void:
	_show_panel(controls_panel)

func _on_settings_btn_pressed() -> void:
	_show_panel(settings_panel)

func _on_restart_btn_pressed() -> void:
	_pending_action = "restart"
	confirm_title.text = "Restart run?"
	confirm_sub.text   = "Your progress will be lost. The storm does not wait."
	confirm_overlay.show()

func _on_quit_btn_pressed() -> void:
	_pending_action = "quit"
	confirm_title.text = "Return to title?"
	confirm_sub.text   = "Your current run will end."
	confirm_overlay.show()

# ── Confirm overlay buttons ───────────────────────────────────────────────────
func _on_yes_btn_pressed() -> void:
	confirm_overlay.hide()
	match _pending_action:
		"restart": _do_restart()
		"quit":    _do_quit()

func _on_no_btn_pressed() -> void:
	confirm_overlay.hide()
	_pending_action = ""

# ── Actions ───────────────────────────────────────────────────────────────────
func _do_restart() -> void:
	get_tree().paused = false
	await TransitionOverlay.fade_to_black()
	GameState.reset()
	GlobalTimer.reset()
	NeedsLog.reset()
	SceneManager.reset()
	queue_free()
	SceneManager.load_scene("title")

func _do_quit() -> void:
	get_tree().paused = false
	await TransitionOverlay.fade_to_black()
	GameState.reset()
	GlobalTimer.reset()
	NeedsLog.reset()
	SceneManager.reset()
	queue_free()
	SceneManager.load_scene("title")
