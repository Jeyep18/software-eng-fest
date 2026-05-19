# PauseMenu.gd
# Attach to the root CanvasLayer: PauseMenu

extends CanvasLayer

@onready var controls_panel:  Control = $ContentArea/ControlsPanel
@onready var settings_panel:  Control = $ContentArea/SettingsPanel

@onready var nav_resume:    Button = $Panel/HSplitContainer/Sidebar/ResumeBtn
@onready var nav_settings:  Button = $Panel/HSplitContainer/Sidebar/SettingsBtn
@onready var nav_restart:   Button = $Panel/HSplitContainer/Sidebar/RestartBtn
@onready var nav_quit:      Button = $Panel/HSplitContainer/Sidebar/QuitBtn

var _all_panels: Array[Control] = []

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	layer = 20
	$ContentArea.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$ContentArea.set_position(Vector2(229, 0))
	$ContentArea.set_size(Vector2(
		get_viewport().get_visible_rect().size.x - 229,
		get_viewport().get_visible_rect().size.y
	))
	var panel_size : Vector2 = $ContentArea.size
	controls_panel.set_size(panel_size)
	settings_panel.set_size(panel_size)
	controls_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	settings_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_all_panels = [
		controls_panel,
		settings_panel,
	]

	controls_panel.hide()
	settings_panel.hide()
	hide()

	# Sidebar nav buttons
	nav_resume.pressed.connect(_on_nav_resume)
	nav_settings.pressed.connect(_on_nav_settings)
	nav_restart.pressed.connect(_on_nav_restart)
	nav_quit.pressed.connect(_on_nav_quit)

# ── Input ─────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if visible:
		_close()
	else:
		_open()
	get_viewport().set_input_as_handled()

func _open() -> void:
	_close_gameplay_menus()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	show()

func _close() -> void:
	hide()
	var focused := get_viewport().gui_get_focus_owner()
	if focused:
		focused.release_focus()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false

# ── Panel switcher ────────────────────────────────────────────────────────────
func _show_panel(target: Control) -> void:
	for panel in _all_panels:
		panel.hide()
	target.show()

func _close_gameplay_menus() -> void:
	var map_screen = get_tree().get_first_node_in_group("map_screen")
	if map_screen and map_screen.has_method("close_map"):
		map_screen.close_map()

	var backpack_ui = get_tree().get_first_node_in_group("backpack_ui")
	if backpack_ui and backpack_ui.has_method("close_backpack"):
		backpack_ui.close_backpack()

# ── Nav handlers ──────────────────────────────────────────────────────────────
func _on_nav_resume() -> void:
	_close()

func _on_nav_controls() -> void:
	_show_panel(controls_panel)

func _on_nav_settings() -> void:
	_show_panel(settings_panel)

func _on_nav_restart() -> void:
	if not is_inside_tree():
		return
	_do_restart()

func _on_nav_quit() -> void:
	if not is_inside_tree():
		return
	_do_quit()

func _do_restart() -> void:
	# 1. Hide the menu and release focus immediately so the UI looks responsive
	hide()
	var focused := get_viewport().gui_get_focus_owner()
	if focused:
		focused.release_focus()

	# 2. UNPAUSE BEFORE AWAITING
	# The tree must be running for TransitionOverlay's tween/animation to process.
	# Awaiting while paused = the coroutine never resumes = permanent freeze.
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# 3. Fade out — now safe because the tree is unpaused
	await TransitionOverlay.fade_to_black()
	
	# 4. Reset all global state
	SceneManager.reset()
	NeedsLog.reset()
	ShopUi.reset()
	InventoryManager.reset()
	GameState.reset()
	
	# 5. Load home — SceneManager handles the fade-in
	SceneManager.load_scene("home")
	GlobalTimer.start_fresh()

func _do_quit() -> void:
	# Same pattern: hide → unpause → await → navigate
	hide()
	var focused := get_viewport().gui_get_focus_owner()
	if focused:
		focused.release_focus()

	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	await TransitionOverlay.fade_to_black()
	
	SceneManager.reset()
	NeedsLog.reset()
	ShopUi.reset()
	InventoryManager.reset()
	GameState.reset()

	# No game state reset needed — title screen will reinitialise everything
	SceneManager.load_scene("main_menu")

# ── Stubs intentionally left empty (panels have no special open logic yet) ────

func _on_resume_btn_pressed()    -> void: _on_nav_resume()
func _on_controls_btn_pressed()  -> void: _on_nav_controls()
func _on_settings_btn_pressed()  -> void: _on_nav_settings()
func _on_restart_btn_pressed()   -> void: _on_nav_restart()
func _on_quit_btn_pressed()      -> void: _on_nav_quit()
