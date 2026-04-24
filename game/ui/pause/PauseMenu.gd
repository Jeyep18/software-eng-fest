# PauseMenu.gd
# Attach to the root CanvasLayer: PauseMenu

extends CanvasLayer

@onready var resume_panel:    Control = $ContentArea/ResumePanel
@onready var checklist_panel: Control = $ContentArea/ChecklistPanel
@onready var controls_panel:  Control = $ContentArea/ControlsPanel
@onready var settings_panel:  Control = $ContentArea/SettingsPanel

@onready var time_value: Label = $ContentArea/ResumePanel/VBoxContainer/TimerRow/TimeCard/VBoxContainer/TimeValue
@onready var eta_value:  Label = $ContentArea/ResumePanel/VBoxContainer/TimerRow/ETACard/VBoxContainer/ETAValue

@onready var nav_resume:    Button = $Panel/HSplitContainer/Sidebar/ResumeBtn
@onready var nav_checklist: Button = $Panel/HSplitContainer/Sidebar/ChecklistBtn
@onready var nav_controls:  Button = $Panel/HSplitContainer/Sidebar/ControlsBtn
@onready var nav_settings:  Button = $Panel/HSplitContainer/Sidebar/SettingsBtn
@onready var nav_restart:   Button = $Panel/HSplitContainer/Sidebar/RestartBtn
@onready var nav_quit:      Button = $Panel/HSplitContainer/Sidebar/QuitBtn

# ── Resume panel quick-nav buttons ────────────────────────────────────────────
@onready var btn_resume:    Button = $ContentArea/ResumePanel/VBoxContainer/ResumeButton
@onready var btn_checklist: Button = $ContentArea/ResumePanel/VBoxContainer/GoChecklistButton
@onready var btn_controls:  Button = $ContentArea/ResumePanel/VBoxContainer/GoControlsButton

# ── Checklist script reference ────────────────────────────────────────────────
@onready var checklist_script: ChecklistPanel = $ContentArea/ChecklistPanel

var _all_panels: Array[Control] = []

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Force ContentArea to fill the screen minus the sidebar width
	$ContentArea.set_position(Vector2(229, 0))
	$ContentArea.set_size(Vector2(
		get_viewport().get_visible_rect().size.x - 229,
		get_viewport().get_visible_rect().size.y
	))
	var panel_size = $ContentArea.size
	resume_panel.set_size(panel_size)
	checklist_panel.set_size(panel_size)
	controls_panel.set_size(panel_size)
	settings_panel.set_size(panel_size)
	
	_all_panels = [
		resume_panel,
		checklist_panel,
		controls_panel,
		settings_panel,
	]
	# Hide all panels manually first
	checklist_panel.hide()
	controls_panel.hide()
	settings_panel.hide()
	# Show only resume by default
	resume_panel.show()
	hide()

	# Connect sidebar nav buttons
	nav_resume.pressed.connect(_on_nav_resume)
	nav_checklist.pressed.connect(_on_nav_checklist)
	nav_controls.pressed.connect(_on_nav_controls)
	nav_settings.pressed.connect(_on_nav_settings)
	nav_restart.pressed.connect(_on_nav_restart)
	nav_quit.pressed.connect(_on_nav_quit)

	# Connect resume panel shortcut buttons
	btn_resume.pressed.connect(_on_nav_resume)
	btn_checklist.pressed.connect(_on_nav_checklist)
	btn_controls.pressed.connect(_on_nav_controls)

# ── Input ─────────────────────────────────────────────────────────────────────
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
	_update_resume_panel()
	show()

func _close() -> void:
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false

# ── Panel switcher ────────────────────────────────────────────────────────────
func _show_panel(target: Control) -> void:
	print("_show_panel called with: ", target)
	for panel in _all_panels:
		print("hiding: ", panel)
		panel.hide()
	target.show()

# ── Nav handlers ──────────────────────────────────────────────────────────────
func _on_nav_resume() -> void:
	_close()

func _on_nav_checklist() -> void:
	print("checklist button pressed")
	print("checklist_panel is: ", checklist_panel)
	_show_panel(checklist_panel)
	if checklist_script:
		checklist_script.refresh()

func _on_nav_controls() -> void:
	_show_panel(controls_panel)

func _on_nav_settings() -> void:
	_show_panel(settings_panel)

func _on_nav_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_nav_quit() -> void:
	get_tree().paused = false
	SceneManager.load_scene("title")

# ── Resume panel data ─────────────────────────────────────────────────────────
func _update_resume_panel() -> void:
	if time_value:
		time_value.text = GlobalTimer.get_time_string()
	if eta_value:
		eta_value.text = GlobalTimer.get_storm_eta_string()


func _on_checklist_btn_pressed() -> void:
	pass # Replace with function body.


func _on_resume_btn_pressed() -> void:
	pass # Replace with function body.


func _on_controls_btn_pressed() -> void:
	pass # Replace with function body.


func _on_settings_btn_pressed() -> void:
	pass # Replace with function body.


func _on_restart_btn_pressed() -> void:
	pass # Replace with function body.


func _on_quit_btn_pressed() -> void:
	pass # Replace with function body.
