extends CanvasLayer

const UI_STYLE = preload("res://game/ui/GameUIStyle.gd")
const SFX = preload("res://game/audio/Sfx.gd")
const PAGE_SIZE := Vector2(1920.0, 1080.0)
const PANEL_FADE_DURATION := 0.15

# Centers of the printed circles, measured within the 1152 × 600 map area.
const NODE_POSITIONS := {
	"home": Vector2(552, 228),
	"ate_linda": Vector2(229, 170),
	"hardware": Vector2(872, 228),
	"pharmacy": Vector2(744, 440),
	"grocery": Vector2(1001, 438),
}
const NODE_DISPLAY_NAMES := {
	"home": "Home",
	"ate_linda": "Ate Linda's",
	"hardware": "Hardware Store",
	"pharmacy": "Botika",
	"grocery": "Palengke",
}
const NODE_ICONS := {
	"home": preload("res://game/assets/map_ui/icon_home.png"),
	"ate_linda": preload("res://game/assets/map_ui/icon_ate_linda.png"),
	"hardware": preload("res://game/assets/map_ui/icon_hardware.png"),
	"pharmacy": preload("res://game/assets/map_ui/icon_botika.png"),
	"grocery": preload("res://game/assets/map_ui/icon_palengke.png"),
}

@onready var backdrop: ColorRect = $Backdrop
@onready var map_page: Control = $MapPage
@onready var panel: Control = $MapPage/Panel
@onready var nodes_container: Control = $MapPage/Panel/MapNodes
@onready var storm_overlay: Control = $MapPage/Panel/MapNodes/StormOverlay
@onready var confirm_panel: PanelContainer = $MapPage/Panel/ConfirmPanel
@onready var confirm_dest: Label = $MapPage/Panel/ConfirmPanel/MarginContainer/VBoxContainer/DestinationLabel
@onready var confirm_time: Label = $MapPage/Panel/ConfirmPanel/MarginContainer/VBoxContainer/TravelTimeLabel
@onready var confirm_button: Button = $MapPage/Panel/ConfirmPanel/MarginContainer/VBoxContainer/ButtonRow/ConfirmButton
@onready var cancel_button: Button = $MapPage/Panel/ConfirmPanel/MarginContainer/VBoxContainer/ButtonRow/CancelButton
@onready var end_day_panel: PanelContainer = $MapPage/Panel/EndDayPanel
@onready var end_day_title: Label = $MapPage/Panel/EndDayPanel/EndDayMargin/EndDayColumn/EndDayTitle
@onready var end_day_button: Button = $MapPage/Panel/EndDayPanel/EndDayMargin/EndDayColumn/EndDay
@onready var map_hint: Label = $MapPage/Panel/MapHint

var _selected_location := ""
var _selected_travel_cost := -1
var _node_buttons: Dictionary = {}
var _panel_tween: Tween
var _closing := false
var _transitioning := false
var _input_blocker: Control


func _ready() -> void:
	add_to_group("map_screen")
	hide()
	confirm_panel.hide()
	storm_overlay.node_positions = NODE_POSITIONS
	storm_overlay.set_process(false)
	_build_node_buttons()
	_connect_signals()
	LocalizationManager.language_changed.connect(_on_language_changed)
	confirm_button.pressed.connect(_on_confirm_travel)
	cancel_button.pressed.connect(_on_cancel_selection)
	_apply_map_style()
	_layout_map()
	_input_blocker = Control.new()
	_input_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_input_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_input_blocker)
	_input_blocker.hide()


func _input(event: InputEvent) -> void:
	if _transitioning or not event.is_action_pressed("open_map"):
		return
	if SceneManager.is_travelling:
		return
	if visible:
		close_map()
	else:
		open_map()


func open_map() -> void:
	if get_tree().get_first_node_in_group("lotto_ui") != null:
		return
	var was_visible := visible
	if _panel_tween != null and _panel_tween.is_valid():
		_panel_tween.kill()
	_closing = false
	_transitioning = true
	_input_blocker.show()
	CursorState.request_visible(self)
	_close_backpack_if_open()
	SFX.map_open()
	_on_cancel_selection()
	_refresh_all_nodes()
	storm_overlay.queue_redraw()
	storm_overlay.set_process(true)
	_layout_map()
	show()
	if not was_visible:
		map_page.modulate.a = 0.0
		backdrop.modulate.a = 0.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel_tween = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_panel_tween.tween_property(map_page, "modulate:a", 1.0, PANEL_FADE_DURATION)
	_panel_tween.tween_property(backdrop, "modulate:a", 1.0, PANEL_FADE_DURATION)
	_panel_tween.finished.connect(func() -> void:
		_transitioning = false
		_input_blocker.hide()
	)


func close_map() -> void:
	if not visible or _closing:
		return
	SFX.map_open()
	_closing = true
	_transitioning = true
	_input_blocker.show()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _panel_tween != null and _panel_tween.is_valid():
		_panel_tween.kill()
	_on_cancel_selection()
	_panel_tween = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_panel_tween.tween_property(map_page, "modulate:a", 0.0, PANEL_FADE_DURATION)
	_panel_tween.tween_property(backdrop, "modulate:a", 0.0, PANEL_FADE_DURATION)
	_panel_tween.finished.connect(func() -> void:
		hide()
		storm_overlay.set_process(false)
		_closing = false
		_transitioning = false
		_input_blocker.hide()
		CursorState.release_visible(self)
	)


func _close_backpack_if_open() -> void:
	var backpack_ui = get_tree().get_first_node_in_group("backpack_ui")
	if backpack_ui and backpack_ui.has_method("close_backpack"):
		backpack_ui.close_backpack()


func _layout_map() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var fit := minf(viewport_size.x / PAGE_SIZE.x, viewport_size.y / PAGE_SIZE.y)
	map_page.scale = Vector2.ONE * fit
	map_page.position = (viewport_size - PAGE_SIZE * fit) * 0.5


func _build_node_buttons() -> void:
	var button_scene: PackedScene = preload("res://game/ui/map/MapNodeButton.tscn")
	for loc_id in NODE_POSITIONS.keys():
		var button: MapNodeButton = button_scene.instantiate()
		nodes_container.add_child(button)
		button.position = NODE_POSITIONS[loc_id] - MapNodeButton.ICON_CENTER
		button.setup(loc_id, NODE_DISPLAY_NAMES[loc_id], NODE_ICONS[loc_id])
		button.node_selected.connect(_on_node_selected)
		_node_buttons[loc_id] = button


func _refresh_all_nodes() -> void:
	for loc_id in _node_buttons.keys():
		_node_buttons[loc_id].refresh(
			SceneManager.get_location_state(loc_id),
			loc_id == SceneManager.current_location
		)


func _on_node_selected(loc_id: String) -> void:
	if loc_id == SceneManager.current_location:
		return
	var state: String = SceneManager.get_location_state(loc_id)
	if state == "closed" or state == "inaccessible":
		return
	_on_cancel_selection()
	_selected_location = loc_id
	_node_buttons[loc_id].set_selected(true)
	_show_confirm_panel(loc_id)


func _show_confirm_panel(loc_id: String) -> void:
	confirm_dest.text = LocalizationManager.translate(NODE_DISPLAY_NAMES[loc_id])
	_selected_travel_cost = TravelCalculator.get_travel_time(SceneManager.current_location, loc_id)
	confirm_time.text = LocalizationManager.trf("Travel cost: ~%d min", [_selected_travel_cost])
	var state: String = SceneManager.get_location_state(loc_id)
	if state == "danger":
		confirm_time.text += LocalizationManager.translate("  ⚠ Danger Zone")
		confirm_time.modulate = Color(0.95, 0.40, 0.30)
	elif loc_id == "grocery":
		confirm_time.text += LocalizationManager.translate("  Closes early")
		confirm_time.modulate = Color(1.0, 0.86, 0.42)
	else:
		confirm_time.modulate = Color.WHITE
	confirm_panel.show()


func _on_confirm_travel() -> void:
	if _selected_location.is_empty():
		return
	var destination := _selected_location
	var travel_cost := _selected_travel_cost
	close_map()
	SceneManager.travel_to(destination, "", travel_cost)


func _on_cancel_selection() -> void:
	if _node_buttons.has(_selected_location):
		_node_buttons[_selected_location].set_selected(false)
	confirm_panel.hide()
	_selected_location = ""
	_selected_travel_cost = -1


func _connect_signals() -> void:
	get_viewport().size_changed.connect(_layout_map)
	GlobalTimer.time_updated.connect(_on_time_updated)
	GlobalTimer.encroachment_threshold_reached.connect(_on_encroachment)
	StormEnroachment.location_state_changed.connect(_on_location_state_changed)
	SceneManager.travel_completed.connect(_on_travel_completed)


func _on_time_updated(_minute: int) -> void:
	if visible:
		storm_overlay.queue_redraw()


func _on_encroachment(_zone_id: String) -> void:
	if visible:
		_refresh_all_nodes()
		storm_overlay.queue_redraw()


func _on_location_state_changed(_location_id: String, _new_state: String) -> void:
	if visible:
		_refresh_all_nodes()
		if not _selected_location.is_empty() and SceneManager.get_location_state(_selected_location) == "closed":
			_on_cancel_selection()


func _on_travel_completed(_location_id: String) -> void:
	if visible:
		_refresh_all_nodes()


func _on_language_changed(_language_id: String) -> void:
	_refresh_static_text()
	if visible:
		_refresh_all_nodes()
		storm_overlay.queue_redraw()
		if not _selected_location.is_empty():
			_show_confirm_panel(_selected_location)


func _apply_map_style() -> void:
	UI_STYLE.apply_panel(confirm_panel)
	UI_STYLE.apply_panel(end_day_panel)
	UI_STYLE.apply_label(confirm_dest, false, true)
	UI_STYLE.apply_label(confirm_time)
	UI_STYLE.apply_label(end_day_title, false, true)
	UI_STYLE.apply_label(map_hint)
	map_hint.add_theme_font_override("font", UI_STYLE.FONT_HEADING)
	map_hint.add_theme_color_override("font_color", Color(0.14, 0.18, 0.17))
	UI_STYLE.apply_button(confirm_button)
	UI_STYLE.apply_button(cancel_button)
	UI_STYLE.apply_button(end_day_button)
	_refresh_static_text()


func _refresh_static_text() -> void:
	end_day_title.text = LocalizationManager.translate("Confident enough?")
	end_day_button.text = LocalizationManager.translate("END THE DAY")
	confirm_button.text = LocalizationManager.translate("Confirm")
	cancel_button.text = LocalizationManager.translate("Cancel")
	map_hint.text = LocalizationManager.translate("Press M to open or close map")
