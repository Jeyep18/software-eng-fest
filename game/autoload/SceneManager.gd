# SceneManager.gd — Autoload Singleton
extends Node

var has_played_opening: bool = false
var current_location: String = "home"
var is_travelling: bool = false

var _pending_spawn_id: String = ""

const LOCATION_ALIASES: Dictionary = {
	"bodega": "home",
	"act1":   "home",
}

const HOME_ROOMS: Array[String] = ["bodega", "home", "act1"]

const SCENE_PATHS: Dictionary = {
	"intro":         "res://game/scenes/intro/IntroSequence.tscn", 
	"main_menu":     "res://game/scenes/main_menu/Main_Menu1.tscn",
	"act1":          "res://game/scenes/act1/Inside_House_Act1.tscn",
	"home":          "res://game/scenes/locations/house_inside.tscn",
	"tindahan":      "res://game/scenes/locations/tindahan.tscn",
	"pharmacy":      "res://game/scenes/locations/pharmacy.tscn",
	"barangay_hall": "res://game/scenes/locations/barangay_hall.tscn",
	"grocery":       "res://game/scenes/locations/grocery.tscn",
	"mang_romy":     "res://game/scenes/locations/mang_romy.tscn",
	"ate_linda":     "res://game/scenes/locations/tindahan.tscn",
	"hardware":      "res://game/scenes/locations/hardware.tscn",
	"bodega":        "res://game/scenes/locations/bodega.tscn",
}

# Storm encroachment state — SceneManager reads these to block travel
var danger_zones: Array[String] = []
var closed_zones: Array[String] = []

signal travel_completed(location_id: String)


func _ready() -> void:
	# Listen for encroachment from GlobalTimer
	GlobalTimer.encroachment_threshold_reached.connect(_on_encroachment)
	GlobalTimer.storm_arrived.connect(_on_storm_arrived)


# ── Scene Loading (Act transitions — menu → act1, act1 → storm) ──────────────

func load_scene(scene_id: String) -> void:
	if not SCENE_PATHS.has(scene_id):
		push_error("SceneManager: Unknown scene ID: " + scene_id)
		return
	get_tree().change_scene_to_file(SCENE_PATHS[scene_id])
	await get_tree().create_timer(0.1).timeout
	await TransitionOverlay.fade_from_black()
	
# ── Location Travel (Act 2 preparation loop) ─────────────────────────────────

func travel_to(target_location: String, spawn_id: String = "") -> void:
	# Block travel to inaccessible locations
	if not StormEnroachment.can_travel_to(target_location):
		push_warning("SceneManager: '%s' is inaccessible — storm has closed it." % target_location)
		# TODO: show a HUD message to the player here ("Hindi na mapuntahan — masyadong mapanganib.")
		return
	
	StormEnroachment.apply_danger_penalty(target_location)
	
	if is_travelling:
		return

	if not SCENE_PATHS.has(target_location):
		print("Scene not yet built for: ", target_location)
		return

	if closed_zones.has(target_location):
		push_warning("SceneManager: Location is closed: " + target_location)
		return
		
	if target_location == "home" and spawn_id == "":
		spawn_id = "main_door"
	
	var travel_cost: int = TravelCalculator.get_travel_time(current_location, target_location)
	is_travelling = true
	
	_pending_spawn_id = spawn_id
	
	await TransitionOverlay.fade_to_black()
	GlobalTimer.add_time(travel_cost)
	get_tree().change_scene_to_file(SCENE_PATHS[target_location])
	await get_tree().create_timer(0.1).timeout
	await TransitionOverlay.fade_from_black()

	current_location = LOCATION_ALIASES.get(target_location, target_location)
	is_travelling = false
	emit_signal("travel_completed", target_location)

func clear_pending_spawn() -> void:
	_pending_spawn_id = ""

func get_pending_spawn_id() -> String:
	return _pending_spawn_id

# ── Zone State ────────────────────────────────────────────────────────────────

func get_location_state(location_id: String) -> String:
	if closed_zones.has(location_id):  return "closed"
	if danger_zones.has(location_id):  return "danger"
	return "open"


# ── Encroachment Handlers ─────────────────────────────────────────────────────

func _on_encroachment(zone_id: String) -> void:
	match zone_id:
		"outer_danger":
			_mark_danger("grocery")
		"outer_closed":
			_mark_closed("grocery")
			_mark_danger("barangay_hall")
		"inner_danger":
			_mark_danger("hardware")
			_mark_danger("pharmacy")


func _on_storm_arrived() -> void:
	# Lock all travel
	for loc in SCENE_PATHS.keys():
		_mark_closed(loc)


func _mark_danger(location_id: String) -> void:
	if not danger_zones.has(location_id):
		danger_zones.append(location_id)

func _mark_closed(location_id: String) -> void:
	if HOME_ROOMS.has(location_id):
		return
	danger_zones.erase(location_id)
	if not closed_zones.has(location_id):
		closed_zones.append(location_id)

# Add to SceneManager.gd
func reset() -> void:
	current_location  = "home"
	is_travelling     = false
	has_played_opening = false
	_pending_spawn_id = ""
	danger_zones.clear()
	closed_zones.clear()
