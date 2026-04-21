# HUDOverlay.gd — Autoload Singleton
# Persistent top-bar HUD. Always visible during Act 2 and beyond.
# Displays: current in-game time | current location | storm ETA
#
# SCENE TREE (HUDOverlay.tscn):
#   HUDOverlay (CanvasLayer, layer = 5)
#     └── TopBar (PanelContainer, anchored full-width at top)
#           └── HBoxContainer
#                 ├── TimeBlock (VBoxContainer)
#                 │     ├── TimeIcon  (Label — "🕐" or a TextureRect)
#                 │     └── TimeLabel (Label)
#                 ├── VSeparator
#                 ├── LocationBlock (VBoxContainer)
#                 │     ├── LocIcon   (Label — "📍")
#                 │     └── LocLabel  (Label)
#                 ├── VSeparator
#                 └── ETABlock (VBoxContainer)
#                       ├── ETAIcon   (Label — "⚠" or storm icon)
#                       └── ETALabel  (Label)
#
# Register in Project > Autoloads as "HUDOverlay"

extends CanvasLayer

# ── Node References ────────────────────────────────────────────────────────────
@onready var top_bar:      PanelContainer = $TopBar
@onready var time_label:   Label          = $TopBar/HBoxContainer/TimeBlock/TimeLabel
@onready var loc_label:    Label          = $TopBar/HBoxContainer/LocationBlock/LocLabel
@onready var eta_label:    Label          = $TopBar/HBoxContainer/ETABlock/ETALabel
@onready var eta_icon:     Label          = $TopBar/HBoxContainer/ETABlock/ETAIcon

# ── Display Name Map (mirrors MapScreen) ──────────────────────────────────────
const LOCATION_NAMES: Dictionary = {
	"home":          "Home",
	"mang_romy":     "Mang Romy's",
	"ate_linda":     "Ate Linda's",
	"hardware":      "Hardware Store",
	"pharmacy":      "Pharmacy",
	"barangay_hall": "Barangay Hall",
	"grocery":       "Grocery / Palengke",
}

# ── ETA color thresholds ───────────────────────────────────────────────────────
const COLOR_ETA_SAFE:   Color = Color(0.75, 0.90, 0.75)   # soft green
const COLOR_ETA_WARN:   Color = Color(0.99, 0.80, 0.40)   # amber
const COLOR_ETA_DANGER: Color = Color(0.90, 0.30, 0.30)   # red

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	layer = 5   # above world, below map (MapScreen uses higher layer if needed)

	# Start hidden — show only when Act 2 begins
	top_bar.hide()

	# Connect to GlobalTimer for live updates
	GlobalTimer.time_updated.connect(_on_time_updated)
	GlobalTimer.encroachment_threshold_reached.connect(_on_encroachment)
	GlobalTimer.storm_arrived.connect(_on_storm_arrived)

	# Connect to SceneManager to update location label on travel
	SceneManager.travel_completed.connect(_on_travel_completed)

	# Connect to GameState to show/hide based on act
	GameState.act_changed.connect(_on_act_changed)
	
	show_hud()

# ── Public API ─────────────────────────────────────────────────────────────────
func show_hud() -> void:
	top_bar.show()
	_refresh_all()

func hide_hud() -> void:
	top_bar.hide()

# ── Refresh ───────────────────────────────────────────────────────────────────
func _refresh_all() -> void:
	_refresh_time()
	_refresh_location()
	_refresh_eta()

func _refresh_time() -> void:
	time_label.text = GlobalTimer.get_time_string()

func _refresh_location() -> void:
	var loc_id: String = SceneManager.current_location
	loc_label.text = LOCATION_NAMES.get(loc_id, loc_id.capitalize())

func _refresh_eta() -> void:
	var progress: float = GlobalTimer.get_storm_progress()
	eta_label.text = GlobalTimer.get_storm_eta_string()

	# Color the ETA label based on urgency
	if progress < 0.50:
		eta_label.add_theme_color_override("font_color", COLOR_ETA_SAFE)
		eta_icon.text = "🌤"
	elif progress < 0.75:
		eta_label.add_theme_color_override("font_color", COLOR_ETA_WARN)
		eta_icon.text = "⛅"
	else:
		eta_label.add_theme_color_override("font_color", COLOR_ETA_DANGER)
		eta_icon.text = "🌀"

# ── Signal Handlers ───────────────────────────────────────────────────────────
func _on_time_updated(_minute: int) -> void:
	if top_bar.visible:
		_refresh_time()
		_refresh_eta()

func _on_encroachment(_zone_id: String) -> void:
	if top_bar.visible:
		_refresh_eta()

func _on_storm_arrived() -> void:
	eta_label.text = "STORM HAS ARRIVED"
	eta_label.add_theme_color_override("font_color", COLOR_ETA_DANGER)
	eta_icon.text = "🌀"

func _on_travel_completed(_location_id: String) -> void:
	_refresh_location()

func _on_act_changed(new_act: GameState.Act) -> void:
	match new_act:
		GameState.Act.ACT_2:
			show_hud()
		GameState.Act.ACT_1:
			hide_hud()
		# ACT_3 and ACT_4: keep visible (storm resolution still shows time context)
		_:
			pass
