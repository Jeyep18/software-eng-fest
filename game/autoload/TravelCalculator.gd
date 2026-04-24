# TravelCalculator.gd — Autoload Singleton
extends Node

const MAP_GRAPH: Dictionary = {
	"home": {
		"ate_linda":  12,   # unchanged — nearby, low pressure
		"hardware":   30,   # up from 28 — marginal increase
		"grocery":    55,   # up from 48 — grocery must feel far and risky
	},
	"ate_linda": {
		"home":       12,
		"hardware":   20,   # unchanged
		"pharmacy":   22,   # unchanged
	},
	"hardware": {
		"home":       30,   # matches above
		"ate_linda":  20,
		"pharmacy":   15,   # unchanged — close together, reward efficient routing
		"grocery":    25,   # unchanged
	},
	"pharmacy": {
		"home":       34,   # slightly up — pharmacy + hardware + home chain
		"ate_linda":  22,
		"hardware":   15,
		"grocery":    20,
	},
	"grocery": {
		"home":       55,   # matches above — far, closes early, creates urgency
		"hardware":   25,
		"pharmacy":   20,
	},
}

const VARIANCE_MIN: int = -2
const VARIANCE_MAX: int = 2


# ── Internal helpers first — GDScript requires functions to exist
# before they are called when using strict mode ────────────────────────────────

func _get_min_dist_node(unvisited: Array, dist: Dictionary) -> String:
	var min_dist: float = INF
	var min_node: String = ""
	for node in unvisited:
		if dist[node] < min_dist:
			min_dist = dist[node]
			min_node = node
	return min_node


func _reconstruct_path(prev: Dictionary, origin: String, target: String) -> Array:
	var path: Array = []
	var current: Variant = target
	while current != null:
		path.push_front(current)
		current = prev[current]
	if path.is_empty() or path[0] != origin:
		push_error("TravelCalculator: Could not reconstruct path from '%s' to '%s'" % [origin, target])
		return []
	return path


# ── Public API ────────────────────────────────────────────────────────────────

func get_travel_path(origin: String, target: String) -> Array:
	if not MAP_GRAPH.has(origin):
		push_error("TravelCalculator: Unknown origin node: " + origin)
		return []
	if not MAP_GRAPH.has(target):
		push_error("TravelCalculator: Unknown target node: " + target)
		return []

	var dist: Dictionary = {}
	var prev: Dictionary = {}
	var unvisited: Array = []

	for node in MAP_GRAPH.keys():
		dist[node] = INF
		prev[node] = null
		unvisited.append(node)
	dist[origin] = 0

	while not unvisited.is_empty():
		var current: String = _get_min_dist_node(unvisited, dist)
		if current == "":
			break
		if current == target:
			break
		unvisited.erase(current)
		for neighbor in MAP_GRAPH[current].keys():
			if not unvisited.has(neighbor):
				continue
			var new_dist: float = dist[current] + MAP_GRAPH[current][neighbor]
			if new_dist < dist[neighbor]:
				dist[neighbor] = new_dist
				prev[neighbor] = current

	return _reconstruct_path(prev, origin, target)


func get_travel_time(origin: String, target: String) -> int:
	if origin == target:
		return 0
	var path: Array = get_travel_path(origin, target)
	if path.is_empty():
		push_error("TravelCalculator: No path found from '%s' to '%s'" % [origin, target])
		return 0
	var total: int = 0
	for i in range(path.size() - 1):
		var base_cost: int = MAP_GRAPH[path[i]][path[i + 1]]
		var variance: int = randi_range(VARIANCE_MIN, VARIANCE_MAX)
		total += base_cost + variance
	return total


func get_travel_label(origin: String, target: String) -> String:
	if origin == target:
		return "You are here"
	var cost: int = get_travel_time(origin, target)
	var location_names: Dictionary = {
		"home":          "Home",
		"mang_romy":     "Mang Romy's",
		"ate_linda":     "Ate Linda's",
		"hardware":      "Hardware Store",
		"pharmacy":      "Pharmacy",
		"barangay_hall": "Barangay Hall",
		"grocery":       "Grocery / Palengke",
	}
	var label: String = location_names.get(target, target)
	return "Travel to %s: ~%d min" % [label, cost]
