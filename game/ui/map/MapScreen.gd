# MapScreen.gd — full replacement

extends CanvasLayer

@onready var panel:           Control = $Panel
@onready var nodes_container: Control = $Panel/MapNodes
@onready var road_layer:      Control = $Panel/MapNodes/RoadLayer
@onready var storm_overlay:   Control = $Panel/MapNodes/StormOverlay
@onready var confirm_panel:   Control = $Panel/ConfirmPanel
@onready var confirm_dest:    Label   = $Panel/ConfirmPanel/DestinationLabel
@onready var confirm_time:    Label   = $Panel/ConfirmPanel/TravelTimeLabel
@onready var confirm_button:  Button  = $Panel/ConfirmPanel/ConfirmButton
@onready var cancel_button:   Button  = $Panel/ConfirmPanel/CancelButton

# ── Beta scope: Mang Romy and Barangay Hall are CUT ──────────────────────────
# Layout reflects GDD v3 node diagram:
#
#   [Ate Linda's] ── [Home] ── [Hardware Store]
#                                /          \
#                         [Pharmacy]      [Grocery]
#
const NODE_POSITIONS: Dictionary = {
	"home":          Vector2(550, 260),
	"ate_linda":     Vector2(240, 200),
	"hardware":      Vector2(840, 240),
	"pharmacy":      Vector2(720, 450),
	"grocery":       Vector2(970, 450),
}

const NODE_DISPLAY_NAMES: Dictionary = {
	"home":          "Home",
	"ate_linda":     "Ate Linda's",
	"hardware":      "Hardware Store",
	"pharmacy":      "Botika",
	"grocery":       "Palengke",
}	

## Optional icon textures — assign in Inspector or leave null for text-only nodes
#@export var icon_home:          Texture2D = null
#@export var icon_ate_linda:     Texture2D = null
#@export var icon_hardware:      Texture2D = null
#@export var icon_pharmacy:      Texture2D = null
#@export var icon_grocery:       Texture2D = null

# ── Beta road connections ─────────────────────────────────────────────────────
const ROAD_CONNECTIONS: Array = [
	["home",     "ate_linda"],
	["home",     "hardware"],
	["hardware", "pharmacy"],
	["hardware", "grocery"],
]

var _selected_location: String = ""
var _node_buttons: Dictionary = {}

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("map_screen")
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

# ── Open / Close ──────────────────────────────────────────────────────────────
func open_map() -> void:
	_close_backpack_if_open()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_refresh_all_nodes()
	# Trigger redraws on both drawing nodes
	road_layer.queue_redraw()
	storm_overlay.queue_redraw()
	confirm_panel.hide()
	_selected_location = ""
	show()

func close_map() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hide()
	confirm_panel.hide()
	_selected_location = ""

func _close_backpack_if_open() -> void:
	var backpack_ui = get_tree().get_first_node_in_group("backpack_ui")
	if backpack_ui and backpack_ui.has_method("close_backpack"):
		backpack_ui.close_backpack()

# ── Road Layer — pass data before first draw ──────────────────────────────────
func _build_road_lines() -> void:
	# Populate the RoadLayer exports so its _draw() has data to work with
	road_layer.node_positions = NODE_POSITIONS
	road_layer.connections    = ROAD_CONNECTIONS
	storm_overlay.node_positions = NODE_POSITIONS
	road_layer.queue_redraw()
	storm_overlay.queue_redraw()

# ── Node Button Construction ──────────────────────────────────────────────────
func _build_node_buttons() -> void:
	var button_scene: PackedScene = preload("res://game/ui/map/MapNodeButton.tscn")

	## Map each location to its optional icon texture
	#var icon_map: Dictionary = {
		#"home":          icon_home,
		#"ate_linda":     icon_ate_linda,
		#"hardware":      icon_hardware,
		#"pharmacy":      icon_pharmacy,
		#"grocery":       icon_grocery,
	#}

	for loc_id in NODE_POSITIONS.keys():
		var btn: Control = button_scene.instantiate()
		nodes_container.add_child(btn)

		var pos: Vector2 = NODE_POSITIONS[loc_id]
		var new_size := Vector2(160, 100)
		btn.custom_minimum_size = new_size
		btn.size                = new_size
		
		btn.position = pos - (new_size / 2.0)
		
		btn.setup(
			loc_id,
			NODE_DISPLAY_NAMES.get(loc_id, loc_id)   # ← pass texture
		)
		btn.node_selected.connect(_on_node_selected)
		_node_buttons[loc_id] = btn

func _refresh_all_nodes() -> void:
	for loc_id in _node_buttons.keys():
		var state: String = _get_node_display_state(loc_id)
		
		# Get the raw time instead of the full "Travel to..." sentence
		var travel_time: int = TravelCalculator.get_travel_time(
			SceneManager.current_location, loc_id)
		
		var clean_label: String = "%d min" % travel_time
		# If it's the current location, we might want to hide the time
		if state == "current":
			clean_label = "Nandito ka" 
		
		_node_buttons[loc_id].refresh(state, clean_label)

func _get_node_display_state(loc_id: String) -> String:
	if loc_id == SceneManager.current_location:
		return "current"
	return SceneManager.get_location_state(loc_id)

# ── Node Selection → Confirm Panel ───────────────────────────────────────────
func _on_node_selected(loc_id: String) -> void:
	if loc_id == SceneManager.current_location:
		return
	var state: String = SceneManager.get_location_state(loc_id)
	if state == "closed" or state == "inaccessible":
		return
	_selected_location = loc_id
	_show_confirm_panel(loc_id)

func _show_confirm_panel(loc_id: String) -> void:
	# 1. Update Text & Info (Keep existing info logic)
	var display_name: String = NODE_DISPLAY_NAMES.get(loc_id, loc_id)
	var travel_cost: int = TravelCalculator.get_travel_time(
		SceneManager.current_location, loc_id)
	var state: String = SceneManager.get_location_state(loc_id)
	
	confirm_dest.text = display_name
	confirm_time.text = "Travel cost: ~%d min" % travel_cost
	
	if state == "danger":
		confirm_time.text += "  ⚠ Danger Zone"
		confirm_time.modulate = Color(0.95, 0.40, 0.30)
	elif loc_id == "grocery":
		confirm_time.text += "  Closes early"
		confirm_time.modulate = Color(1.0, 0.86, 0.42)
	else:
		confirm_time.modulate = Color.WHITE
	# 2. Position Anchored to the Right side of the screen
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	var panel_size: Vector2 = Vector2(220, 120) # Defined size for the pane
	var padding: float = 180.0 # Distance from the right and top/bottom edges
	
	# X position: Screen width minus panel width and padding
	var target_x: float = screen_size.x - panel_size.x - padding
	
	# Y position: Centered vertically (optional, or set to a specific height)
	var target_y: float = (screen_size.y - panel_size.y) / 2.0
	
	confirm_panel.position = Vector2(target_x, target_y)
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
		road_layer.queue_redraw()

func _on_location_state_changed(_location_id: String, _new_state: String) -> void:
	if visible:
		_refresh_all_nodes()
		storm_overlay.queue_redraw()

func _on_travel_completed(_location_id: String) -> void:
	if visible:
		_refresh_all_nodes()
