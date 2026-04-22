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
@onready var top_bar:      Panel = $TopBar
@onready var time_label:   Label          = $TopBar/HBoxContainer/VBox/TimeBlock/TimeLabel
@onready var eta_label:    Label          = $TopBar/HBoxContainer/VBox/ETABlock/ETALabel

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
	_refresh_eta()

func _refresh_time() -> void:
	time_label.text = GlobalTimer.get_time_string()

func _refresh_eta() -> void:
	eta_label.text = GlobalTimer.get_storm_eta_string() + " remaining"

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

func _on_act_changed(new_act: GameState.Act) -> void:
	match new_act:
		GameState.Act.ACT_2:
			show_hud()
		GameState.Act.ACT_1:
			hide_hud()
		# ACT_3 and ACT_4: keep visible (storm resolution still shows time context)
		_:
			pass
