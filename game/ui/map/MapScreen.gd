# MapScreen.gd
# Attach to a CanvasLayer node named "MapScreen" in your scene tree.
# Open/close with M key (handled by the Player or a global input handler).
# Reads from: TravelCalculator, SceneManager, GlobalTimer
# Calls:      SceneManager.travel_to(location_id)

extends CanvasLayer

# ── Node References (assign in the Inspector or via @onready) ──────────────
@onready var panel:           Control = $Panel
#@onready var time_label:      Label   = $Panel/Header/TimeLabel
#@onready var eta_label:       Label   = $Panel/Header/ETALabel
#@onready var location_label:  Label   = $Panel/Header/LocationLabel
@onready var nodes_container: Control = $Panel/MapNodes
@onready var confirm_panel:   Control = $Panel/ConfirmPanel
@onready var confirm_dest:    Label   = $Panel/ConfirmPanel/DestinationLabel
@onready var confirm_time:    Label   = $Panel/ConfirmPanel/TravelTimeLabel
@onready var confirm_button:  Button  = $Panel/ConfirmPanel/ConfirmButton
@onready var cancel_button:   Button  = $Panel/ConfirmPanel/CancelButton
@onready var storm_overlay:   Control = $Panel/MapNodes/StormOverlay
@onready var close_hint: Label = $Panel/HBoxContainer/CloseHint

# ── Map Node Positions (screen coordinates within the MapNodes Control) ──────
# Based on v2.0 GDD node diagram. Adjust to match your art layout.
# Origin (0,0) is top-left of the MapNodes container.
const NODE_POSITIONS: Dictionary = {
	"home":          Vector2(577.0, 313.0),
	"ate_linda":     Vector2(916.0, 151.0),
	"hardware":      Vector2(218.0, 366.0),
	"pharmacy":      Vector2(931.0, 405.0),
	"grocery":       Vector2(871.0, 294.0),
}

# ── Display Names ─────────────────────────────────────────────────────────────
const NODE_DISPLAY_NAMES: Dictionary = {
	"home":          "Home",
	"mang_romy":     "Mang Romy's",
	"ate_linda":     "Ate Linda's",
	"hardware":      "Hardware Store",
	"pharmacy":      "Pharmacy",
	"barangay_hall": "Barangay Hall",
	"grocery":       "Grocery / Palengke",
}

# ── Road Connections for drawing road lines ───────────────────────────────────
# Each pair draws a line between two nodes.
const ROAD_CONNECTIONS: Array = [
	["home",      "mang_romy"],
	["home",      "ate_linda"],
	["home",      "hardware"],
	["ate_linda", "hardware"],
	["mang_romy", "ate_linda"],
	["hardware",  "pharmacy"],
	["hardware",  "barangay_hall"],
	["pharmacy",  "grocery"],
	["barangay_hall", "grocery"],
]

# ── Internal State ────────────────────────────────────────────────────────────
var _selected_location: String = ""
var _node_buttons: Dictionary = {}   # location_id → MapNodeButton

# ── Colors (theme constants — match your art style) ───────────────────────────
const COLOR_ROAD:           Color = Color(0.6, 0.55, 0.45, 0.7)
const COLOR_ROAD_SECONDARY: Color = Color(0.6, 0.55, 0.45, 0.4)
const COLOR_STORM_OVERLAY:  Color = Color(0.88, 0.29, 0.29, 0.08)

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	print("=== MAPSCREEN READY CALLED ===")
	hide()
	confirm_panel.hide()

	_build_road_lines()
	_build_node_buttons()
	_connect_signals()

	confirm_button.pressed.connect(_on_confirm_travel)
	cancel_button.pressed.connect(_on_cancel_selection)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_map"):
		if SceneManager.is_travelling:
			return
		if visible:
			close_map()
		else:
			open_map()
	
	# DEBUG - only log mouse clicks, not motion
	if event is InputEventMouseButton and event.pressed:
		print("Mouse click at: ", event.position, " visible: ", visible)
# ── Open / Close ──────────────────────────────────────────────────────────────
func open_map() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
#	_refresh_header()
	_refresh_all_nodes()
	_refresh_storm_overlay()
	confirm_panel.hide()
	_selected_location = ""
	show()

func close_map() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hide()
	confirm_panel.hide()
	_selected_location = ""

# ── Header Refresh ────────────────────────────────────────────────────────────
#func _refresh_header() -> void:
#	time_label.text    = GlobalTimer.get_time_string()
#	eta_label.text     = "Storm ETA: " + GlobalTimer.get_storm_eta_string()
#	location_label.text = "You are at: " + NODE_DISPLAY_NAMES.get(
#			SceneManager.current_location, SceneManager.current_location)

# ── Node Button Construction ───────────────────────────────────────────────────
func _build_node_buttons() -> void:
	print("=== BUILD NODE BUTTONS CALLED ===")
	var button_scene: PackedScene = preload("res://game/ui/map/MapNodeButton.tscn")
	print("Button scene loaded: ", button_scene)

	for loc_id in NODE_POSITIONS.keys():
		var btn: Control = button_scene.instantiate()
		nodes_container.add_child(btn)

		var pos: Vector2 = NODE_POSITIONS[loc_id]
		btn.custom_minimum_size = Vector2(110, 52)
		btn.size = Vector2(110, 52)
		btn.position = pos - Vector2(55, 26)

		btn.setup(
			loc_id,
			NODE_DISPLAY_NAMES.get(loc_id, loc_id),
			TravelCalculator.get_travel_label(SceneManager.current_location, loc_id)
		)
		btn.node_selected.connect(_on_node_selected)
		_node_buttons[loc_id] = btn
		print("Created button: ", loc_id, " size: ", btn.size, " pos: ", btn.position)

func _refresh_all_nodes() -> void:
	for loc_id in _node_buttons.keys():
		var state: String = _get_node_display_state(loc_id)
		var travel_label: String = TravelCalculator.get_travel_label(
				SceneManager.current_location, loc_id)
		_node_buttons[loc_id].refresh(state, travel_label)

func _get_node_display_state(loc_id: String) -> String:
	if loc_id == SceneManager.current_location:
		return "current"
	return SceneManager.get_location_state(loc_id)  # "open" / "danger" / "closed"

# ── Road Line Drawing (uses a custom draw node) ──────────────────────────────
# Roads are drawn on a child Control node that overrides _draw().
# Create a child node "RoadLayer" (Control) with this script, or call
# queue_redraw() on it whenever the map opens.
func _build_road_lines() -> void:
	# The actual drawing happens in RoadLayer._draw() — see MapRoadLayer.gd
	# We just ensure it redraws when the map opens.
	pass   # hooked via open_map() → _refresh_all_nodes()

# ── Storm Overlay ─────────────────────────────────────────────────────────────
# StormOverlay is a Control whose _draw() paints a spreading red ellipse.
# Its coverage grows with GlobalTimer.get_storm_progress().
func _refresh_storm_overlay() -> void:
	storm_overlay.queue_redraw()

# ── Node Selection → Confirm Panel ───────────────────────────────────────────
func _on_node_selected(loc_id: String) -> void:
	if loc_id == SceneManager.current_location:
		return   # already here — do nothing

	var state: String = SceneManager.get_location_state(loc_id)
	if state == "closed":
		return   # closed nodes are not selectable (enforced in MapNodeButton too)

	_selected_location = loc_id
	_show_confirm_panel(loc_id)

func _show_confirm_panel(loc_id: String) -> void:
	var display_name: String = NODE_DISPLAY_NAMES.get(loc_id, loc_id)
	var travel_cost:  int    = TravelCalculator.get_travel_time(
			SceneManager.current_location, loc_id)
	var state:        String = SceneManager.get_location_state(loc_id)

	confirm_dest.text = display_name
	confirm_time.text = "Travel time: ~%d min" % travel_cost

	if state == "danger":
		confirm_time.text += "\n[!] Danger Zone"
		confirm_time.modulate = Color(0.88, 0.29, 0.29)
	else:
		confirm_time.modulate = Color.WHITE

	# Get the node's screen position
	var node_pos: Vector2 = NODE_POSITIONS.get(loc_id, Vector2(400, 300))
	var panel_size: Vector2 = Vector2(200, 130)
	var screen_size: Vector2 = get_viewport().get_visible_rect().size

	# Try to place panel to the RIGHT of the node first
	var target: Vector2 = node_pos + Vector2(70, -40)

	# If it goes off the right edge, place it to the LEFT instead
	if target.x + panel_size.x > screen_size.x - 20:
		target.x = node_pos.x - panel_size.x - 70

	# If it goes off the bottom, move it up
	if target.y + panel_size.y > screen_size.y - 20:
		target.y = screen_size.y - panel_size.y - 20

	# If it goes off the top, move it down
	if target.y < 20:
		target.y = 20

	confirm_panel.position = target
	confirm_panel.size = panel_size
	confirm_panel.show()

# ── Travel Confirmation ────────────────────────────────────────────────────────
func _on_confirm_travel() -> void:
	if _selected_location.is_empty():
		return
	var dest: String = _selected_location
	close_map()
	SceneManager.travel_to(dest)

func _on_cancel_selection() -> void:
	confirm_panel.hide()
	_selected_location = ""

# ── Signal Connections ────────────────────────────────────────────────────────
func _connect_signals() -> void:
	# Refresh header text on every timer tick while open
	GlobalTimer.time_updated.connect(_on_time_updated)
	# React to encroachment (nodes change state mid-session)
	GlobalTimer.encroachment_threshold_reached.connect(_on_encroachment)
	# Refresh travel times when the player arrives somewhere new
	SceneManager.travel_completed.connect(_on_travel_completed)

func _on_time_updated(_minute: int) -> void:
	pass
#		_refresh_header()

func _on_encroachment(_zone_id: String) -> void:
	if visible:
		_refresh_all_nodes()
		_refresh_storm_overlay()

func _on_travel_completed(_location_id: String) -> void:
	# Travel is done — map can be opened again (SceneManager.is_travelling is false)
	# Refresh node travel-time labels so they reflect the new origin.
	if visible:
		_refresh_all_nodes()
