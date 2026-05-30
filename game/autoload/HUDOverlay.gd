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
@onready var controls_container: HBoxContainer = $VBoxContainer
@onready var controls_label: Label = $VBoxContainer/Label

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
	_setup_vignette_overlay()

	# Start hidden — show only when Act 2 begins
	top_bar.hide()

	# Connect to GlobalTimer for live updates
	GlobalTimer.time_updated.connect(_on_time_updated)
	GlobalTimer.encroachment_threshold_reached.connect(_on_encroachment)
	GlobalTimer.storm_arrived.connect(_on_storm_arrived)
	LocalizationManager.language_changed.connect(_on_language_changed)
	VisualSettings.ui_scale_changed.connect(_on_ui_scale_changed)

	# Connect to GameState to show/hide based on act
	GameState.act_changed.connect(_on_act_changed)

	_apply_ui_scale()
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
	eta_label.text = LocalizationManager.trf("%s remaining", [GlobalTimer.get_storm_eta_string()])

# ── Signal Handlers ───────────────────────────────────────────────────────────
func _on_time_updated(_minute: int) -> void:
	if top_bar.visible:
		_refresh_time()
		_refresh_eta()

func _on_encroachment(_zone_id: String) -> void:
	if top_bar.visible:
		_refresh_eta()

func _on_storm_arrived() -> void:
	eta_label.text = LocalizationManager.translate("STORM HAS ARRIVED")
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

func _on_language_changed(_language_id: String) -> void:
	if top_bar.visible:
		_refresh_all()

func _on_ui_scale_changed(_scale: float) -> void:
	_apply_ui_scale()

func _apply_ui_scale() -> void:
	var scale := VisualSettings.get_ui_scale()
	var viewport_width := get_viewport().get_visible_rect().size.x

	top_bar.offset_left = viewport_width - (300.0 * scale) - 36.0
	top_bar.offset_top = 24.0
	top_bar.offset_right = viewport_width - 24.0
	top_bar.offset_bottom = 24.0

	var top_bar_content := $TopBar/HBoxContainer as HBoxContainer
	top_bar_content.offset_left = -292.0 * scale
	top_bar_content.offset_bottom = 150.0 * scale
	($TopBar/HBoxContainer/VBox as VBoxContainer).custom_minimum_size = Vector2(0.0, 150.0 * scale)
	time_label.label_settings.font_size = int(roundi(70.0 * scale))
	eta_label.label_settings.font_size = int(roundi(25.0 * scale))

	controls_container.offset_top = -178.0 * scale
	controls_container.offset_right = 260.0 * scale
	($VBoxContainer/Control as Control).custom_minimum_size = Vector2(50.0 * scale, 0.0)
	controls_label.add_theme_font_size_override("font_size", int(roundi(16.0 * scale)))

func _setup_vignette_overlay() -> void:
	var existing := get_node_or_null("GameplayVignetteLayer") as CanvasLayer
	if existing != null:
		return
	var vignette_layer := CanvasLayer.new()
	vignette_layer.name = "GameplayVignetteLayer"
	vignette_layer.layer = 0
	add_child(vignette_layer)

	var vignette := ColorRect.new()
	vignette.name = "GameplayVignette"
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float strength = 0.58;
uniform float radius = 0.46;
uniform float softness = 0.32;
void fragment() {
	vec2 centered = UV - vec2(0.5);
	centered.x *= 1.22;
	float dist = length(centered);
	float alpha = smoothstep(radius, radius + softness, dist) * strength;
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	vignette.material = material
	vignette_layer.add_child(vignette)
