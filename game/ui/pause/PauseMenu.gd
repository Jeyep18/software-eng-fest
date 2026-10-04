extends CanvasLayer

@onready var controls_panel: Control = $ContentArea/ControlsPanel
@onready var settings_panel: Control = $ContentArea/SettingsPanel

@onready var nav_resume: Button = $Panel/HSplitContainer/Sidebar/ResumeBtn
@onready var nav_settings: Button = $Panel/HSplitContainer/Sidebar/SettingsBtn
@onready var nav_tutorial: Button = $Panel/HSplitContainer/Sidebar/TutorialBtn
@onready var nav_restart: Button = $Panel/HSplitContainer/Sidebar/RestartBtn
@onready var nav_quit: Button = $Panel/HSplitContainer/Sidebar/QuitBtn

const SIDEBAR_WIDTH: float = 229.0
const TAB_OVERLAP: float = 12.0
const PANEL_FADE_DURATION: float = 0.15
const TUTORIAL_MODAL_SCENE: PackedScene = preload("res://game/ui/tutorial/TutorialModal.tscn")
const UI_STYLE = preload("res://game/ui/GameUIStyle.gd")

var _all_panels: Array[Control] = []
var _audio_settings_panel: AudioSettingsPanel
var _dev_nav: Button
var _dev_panel: DevModePanel
var _panel_tween: Tween
var _input_blocker: Control
var _transitioning: bool = false
var _active_panel: Control

func _ready() -> void:
	layer = 20
	_setup_content_area()
	_setup_panels()
	_setup_settings_panel()
	_setup_dev_panel()
	_connect_nav_buttons()
	_apply_pause_style()
	VisualSettings.ui_scale_changed.connect(_position_sidebar.call_deferred.unbind(1))
	_input_blocker = Control.new()
	_input_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_input_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_input_blocker)
	_input_blocker.hide()
	hide()

func _input(event: InputEvent) -> void:
	if _transitioning or not event.is_action_pressed("ui_cancel"):
		return
	for tutorial in get_tree().get_nodes_in_group("tutorial_modal"):
		if tutorial is TutorialModal and tutorial.visible:
			return
	var lotto_ui := get_tree().get_first_node_in_group("lotto_ui") as ScratchLottoUI
	if lotto_ui != null:
		lotto_ui.request_close()
		get_viewport().set_input_as_handled()
		return

	if visible:
		_close()
	else:
		_open()

	get_viewport().set_input_as_handled()

func _open() -> void:
	if SceneManager.storm_transition_pending:
		return
	_transitioning = true
	CursorState.request_visible(self)
	_close_gameplay_menus()
	get_tree().paused = true
	show()
	for panel in _all_panels:
		panel.hide()
	_active_panel = null
	_position_sidebar()
	$Panel.modulate.a = 0.0
	$ContentArea.modulate.a = 0.0
	_input_blocker.show()
	_panel_tween = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_panel_tween.tween_property($Panel, "modulate:a", 1.0, PANEL_FADE_DURATION)
	_panel_tween.tween_property($ContentArea, "modulate:a", 1.0, PANEL_FADE_DURATION)
	_panel_tween.finished.connect(func() -> void:
		_transitioning = false
		_input_blocker.hide()
	)

func _close() -> void:
	if _transitioning:
		return
	_transitioning = true
	_input_blocker.show()
	_panel_tween = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_panel_tween.tween_property($Panel, "modulate:a", 0.0, PANEL_FADE_DURATION)
	_panel_tween.tween_property($ContentArea, "modulate:a", 0.0, PANEL_FADE_DURATION)
	_panel_tween.finished.connect(func() -> void:
		hide()
		_transitioning = false
		_input_blocker.hide()
		_resume_gameplay_input()
	)

func _setup_content_area() -> void:
	var sidebar_container := $Panel/HSplitContainer as HSplitContainer
	sidebar_container.custom_minimum_size = Vector2(SIDEBAR_WIDTH, 0)
	sidebar_container.z_index = 1
	sidebar_container.offset_left = -SIDEBAR_WIDTH * 0.5
	sidebar_container.offset_right = SIDEBAR_WIDTH * 0.5
	sidebar_container.offset_top = 0.0
	sidebar_container.offset_bottom = 0.0
	var content_area: Control = $ContentArea
	content_area.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _position_sidebar() -> void:
	var sidebar_container := $Panel/HSplitContainer as HSplitContainer
	var left := -SIDEBAR_WIDTH * 0.5
	var card_rect := Rect2()
	if _active_panel == settings_panel and settings_panel.visible:
		card_rect = _audio_settings_panel.get_global_rect()
	elif _active_panel == _dev_panel and _dev_panel != null and _dev_panel.visible:
		card_rect = _dev_panel.get_card_rect()
	if card_rect.has_area():
		left = card_rect.position.x - get_viewport().get_visible_rect().size.x * 0.5 - SIDEBAR_WIDTH + TAB_OVERLAP
	sidebar_container.offset_left = left
	sidebar_container.offset_right = left + SIDEBAR_WIDTH

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
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	settings_panel.add_child(center)
	_audio_settings_panel = AudioSettingsPanel.new()
	_audio_settings_panel.show_close_button = true
	_audio_settings_panel.custom_minimum_size = Vector2(620, 580)
	_audio_settings_panel.close_requested.connect(func() -> void:
		settings_panel.hide()
		_active_panel = null
		_position_sidebar()
	)
	center.add_child(_audio_settings_panel)

func _setup_dev_panel() -> void:
	if not DevMode.is_available():
		return
	_dev_nav = Button.new()
	_dev_nav.text = "Dev Mode"
	_dev_nav.custom_minimum_size = Vector2(0, 60)
	var sidebar := $Panel/HSplitContainer/Sidebar as VBoxContainer
	sidebar.add_child(_dev_nav)
	sidebar.move_child(_dev_nav, nav_settings.get_index() + 1)
	_dev_nav.pressed.connect(_on_nav_dev)
	_dev_panel = DevModePanel.new()
	$ContentArea.add_child(_dev_panel)
	_dev_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dev_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_dev_panel.hide()
	_dev_panel.teleport_requested.connect(_on_dev_teleport_requested)
	_all_panels.append(_dev_panel)
	DevMode.enabled_changed.connect(_sync_dev_tab.unbind(1))
	_sync_dev_tab()

func _sync_dev_tab() -> void:
	if _dev_nav == null:
		return
	_dev_nav.visible = DevMode.is_available() and DevMode.enabled
	if not _dev_nav.visible and _dev_panel.visible:
		_show_panel(settings_panel)
	_position_sidebar.call_deferred()

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
	_active_panel = target
	_position_sidebar.call_deferred()

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
	CursorState.release_visible(self)
	get_tree().paused = false

func _prepare_scene_exit() -> void:
	if _panel_tween != null and _panel_tween.is_valid():
		_panel_tween.kill()
	_transitioning = false
	_input_blocker.hide()
	hide()
	_resume_gameplay_input()

func _reset_global_state() -> void:
	DevMode.end_run()
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

func _on_nav_dev() -> void:
	if DevMode.can_use():
		_show_panel(_dev_panel)

func _on_dev_teleport_requested(location_id: String) -> void:
	if not DevMode.can_use() or not DevMode.is_valid_destination(location_id):
		return
	_prepare_scene_exit()
	DevMode.teleport_to(location_id)

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
	DevMode.begin_run()

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
