extends CanvasLayer

@onready var controls_panel: Control = $ContentArea/ControlsPanel
@onready var settings_panel: Control = $ContentArea/SettingsPanel

@onready var nav_resume: Button = $Panel/HSplitContainer/Sidebar/ResumeBtn
@onready var nav_settings: Button = $Panel/HSplitContainer/Sidebar/SettingsBtn
@onready var nav_tutorial: Button = $Panel/HSplitContainer/Sidebar/TutorialBtn
@onready var nav_restart: Button = $Panel/HSplitContainer/Sidebar/RestartBtn
@onready var nav_quit: Button = $Panel/HSplitContainer/Sidebar/QuitBtn

const SIDEBAR_WIDTH: float = 229.0
const TUTORIAL_MODAL_SCENE: PackedScene = preload("res://game/ui/tutorial/TutorialModal.tscn")
const UI_STYLE = preload("res://game/ui/GameUIStyle.gd")

var _all_panels: Array[Control] = []
var _audio_settings_panel: AudioSettingsPanel

func _ready() -> void:
	layer = 20
	_setup_content_area()
	_setup_panels()
	_setup_settings_panel()
	_connect_nav_buttons()
	_apply_pause_style()
	hide()

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
	for panel in _all_panels:
		panel.hide()

func _close() -> void:
	hide()
	_resume_gameplay_input()

func _setup_content_area() -> void:
	var content_area: Control = $ContentArea
	content_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_area.set_anchor_and_offset(SIDE_LEFT, 0.0, SIDEBAR_WIDTH)
	content_area.set_anchor_and_offset(SIDE_TOP, 0.0, 0.0)
	content_area.set_anchor_and_offset(SIDE_RIGHT, 1.0, 0.0)
	content_area.set_anchor_and_offset(SIDE_BOTTOM, 1.0, 0.0)

func _setup_panels() -> void:
	_all_panels = [
		controls_panel,
		settings_panel,
	]

	for panel in _all_panels:
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.hide()

func _setup_settings_panel() -> void:
	_audio_settings_panel = AudioSettingsPanel.new()
	_audio_settings_panel.show_close_button = true
	_audio_settings_panel.custom_minimum_size = Vector2(620, 540)
	_audio_settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	_audio_settings_panel.offset_left = -310.0
	_audio_settings_panel.offset_top = -270.0
	_audio_settings_panel.offset_right = 310.0
	_audio_settings_panel.offset_bottom = 270.0
	_audio_settings_panel.close_requested.connect(func() -> void: settings_panel.hide())
	settings_panel.add_child(_audio_settings_panel)

func _apply_pause_style() -> void:
	var overlay_panel := $Panel/Panel as Panel
	overlay_panel.modulate = Color(1, 1, 1, 1)
	overlay_panel.add_theme_stylebox_override("panel", UI_STYLE.panel_style(Color(0.02, 0.025, 0.03, 0.74), Color(1, 1, 1, 0.04), 0))
	UI_STYLE.apply_tree($Panel/HSplitContainer/Sidebar)
	var badge := $Panel/HSplitContainer/Sidebar/PauseBadge as PanelContainer
	UI_STYLE.apply_panel(badge)
	var pause_label := $Panel/HSplitContainer/Sidebar/PauseBadge/Label as Label
	UI_STYLE.apply_label(pause_label, false, true)

func _connect_nav_buttons() -> void:
	nav_resume.pressed.connect(_on_nav_resume)
	nav_settings.pressed.connect(_on_nav_settings)
	nav_tutorial.pressed.connect(_on_nav_tutorial)
	nav_restart.pressed.connect(_on_nav_restart)
	nav_quit.pressed.connect(_on_nav_quit)

func _show_panel(target: Control) -> void:
	for panel in _all_panels:
		panel.hide()
	target.show()

func _close_gameplay_menus() -> void:
	var map_screen := get_tree().get_first_node_in_group("map_screen")
	if map_screen and map_screen.has_method("close_map"):
		map_screen.close_map()

	var backpack_ui := get_tree().get_first_node_in_group("backpack_ui")
	if backpack_ui and backpack_ui.has_method("close_backpack"):
		backpack_ui.close_backpack()

func _release_focus() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused:
		focused.release_focus()

func _resume_gameplay_input() -> void:
	_release_focus()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false

func _prepare_scene_exit() -> void:
	hide()
	_resume_gameplay_input()

func _reset_global_state() -> void:
	SceneManager.reset()
	StormEnroachment.reset()
	GlobalTimer.reset()
	NeedsLog.reset()
	SideQuestLog.reset()
	ShopUi.reset()
	InventoryManager.reset()
	GameState.reset()

func _on_nav_resume() -> void:
	_close()

func _on_nav_controls() -> void:
	_show_panel(controls_panel)

func _on_nav_settings() -> void:
	_show_panel(settings_panel)

func _on_nav_tutorial() -> void:
	var tutorial := TUTORIAL_MODAL_SCENE.instantiate()
	add_child(tutorial)
	tutorial.open(false, false, func() -> void:
		tutorial.queue_free()
	)

func _on_nav_restart() -> void:
	if not is_inside_tree():
		return

	_do_restart()

func _on_nav_quit() -> void:
	if not is_inside_tree():
		return

	_do_quit()

func _do_restart() -> void:
	_prepare_scene_exit()
	await TransitionOverlay.fade_to_black()
	_reset_global_state()
	SceneManager.load_scene("home")
	GlobalTimer.start_fresh()

func _do_quit() -> void:
	_prepare_scene_exit()
	await TransitionOverlay.fade_to_black()
	_reset_global_state()
	SceneManager.load_scene("main_menu")

func _on_resume_btn_pressed() -> void:
	_on_nav_resume()

func _on_controls_btn_pressed() -> void:
	_on_nav_controls()

func _on_settings_btn_pressed() -> void:
	_on_nav_settings()

func _on_restart_btn_pressed() -> void:
	_on_nav_restart()

func _on_quit_btn_pressed() -> void:
	_on_nav_quit()
