# SceneManager.gd — Autoload Singleton
extends Node

var current_location: String = "home"
var is_travelling: bool = false

const SCENE_PATHS: Dictionary = {
	"act1":          "res://game/scenes/act1/Act1.tscn",
	"home":          "res://game/scenes/locations/house_1.tscn",
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

func travel_to(target_location: String) -> void:
	if is_travelling:
		return
	if not SCENE_PATHS.has(target_location):
		push_error("SceneManager: Unknown location ID: " + target_location)
		return
	if closed_zones.has(target_location):
		push_warning("SceneManager: Location is closed: " + target_location)
		return

	var travel_cost: int = TravelCalculator.get_travel_time(current_location, target_location)
	is_travelling = true

	await TransitionOverlay.fade_to_black()
	GlobalTimer.add_time(travel_cost)
	get_tree().change_scene_to_file(SCENE_PATHS[target_location])
	await get_tree().create_timer(0.1).timeout
	await TransitionOverlay.fade_from_black()

	current_location = target_location
	is_travelling = false
	emit_signal("travel_completed", target_location)


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
	danger_zones.erase(location_id)
	if not closed_zones.has(location_id):
		closed_zones.append(location_id)
