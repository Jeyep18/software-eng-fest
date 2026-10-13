extends Node

var _checks: int = 0
var _failures: int = 0

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	if OS.get_environment("BAGYONG_ISOLATED_SMOKE") != OS.get_user_data_dir():
		push_error("Score regression requires explicit isolated userdata.")
		get_tree().quit(1)
		return
	LeaderboardManager.clear_entries()
	var ids: Array[String] = ["roof", "medicine", "food", "windows", "water", "flashlight"]
	var weights: Array[int] = [1, 2, 3, 1, 2, 1]
	_check(NeedsLog.TOTAL_WEIGHT == 10, "total preparation weight is ten")
	NeedsLog.reset()
	NeedsLog.resolve(NeedsLog.Need.FOOD)
	NeedsLog.resolve(NeedsLog.Need.WATER)
	_check(NeedsLog.get_resolved_need_ids() == ["food", "water"] and NeedsLog.get_weighted_progress() == 5, "live need state exposes stable IDs and weighted progress")
	NeedsLog.reset()
	for mask in range(64):
		var resolved: Array[String] = []
		var weight := 0
		for index in range(ids.size()):
			if mask & (1 << index):
				resolved.append(ids[index])
				weight += weights[index]
		for status in [SideQuestLog.STATE_NOT_STARTED, SideQuestLog.STATE_ACTIVE,
				SideQuestLog.STATE_READY_TO_TURN_IN, SideQuestLog.STATE_COMPLETED]:
			var bonus := 1000 if status == SideQuestLog.STATE_COMPLETED else 0
			var actual := LeaderboardManager.calculate_score(resolved, bonus > 0, 90, "challenge")
			var expected := float(weight * 2000 + bonus + 90) * GameState.get_difficulty_score_multiplier("challenge")
			_check(is_equal_approx(actual, expected), "weighted score for mask %d and %s" % [mask, status])
	_check(LeaderboardManager.calculate_score([], false, -20, "standard") == 0.0, "negative time is clamped")
	_check(LeaderboardManager.calculate_score(["roof"], false, 9999, "standard") == 2720.0, "remaining time is capped")
	_check(LeaderboardManager.calculate_score(["food", "food", "unknown"], false, 0, "standard") == 6000.0, "duplicate and unknown needs earn no points")
	var essentials: Array[String] = ["food", "medicine", "water", "windows"]
	var without_food: Array[String] = ["roof", "medicine", "windows", "water", "flashlight"]
	_check(LeaderboardManager.calculate_score(essentials, false, 501, "standard") == 16501.0, "R8 values essential preparation")
	_check(LeaderboardManager.calculate_score(without_food, false, 485, "standard") == 14485.0, "R10 cannot outrank R8 by skipping food")
	LeaderboardManager.record_run("R10", without_food, SideQuestLog.STATE_ACTIVE, 485, "standard")
	LeaderboardManager.record_run("R8", essentials, SideQuestLog.STATE_NOT_STARTED, 501, "standard")
	LeaderboardManager._load_entries()
	var entries := LeaderboardManager.get_ranked_entries()
	_check(entries.size() == 2 and entries[0]["player_name"] == "R8", "persisted rankings use weighted scores")
	_check(entries[0]["resolved_need_ids"] == ["medicine", "food", "windows", "water"] and entries[0]["weighted_preparation"] == 8, "saved entries preserve canonical need identities and weight")
	_check(entries[1]["nestor_status"] == SideQuestLog.STATE_ACTIVE, "saved entries preserve unfinished Nestor state")
	LeaderboardManager.record_run("Invalid", ["food", "food", "unknown"], "forged", 0, "standard")
	var sanitized := LeaderboardManager.get_entries().filter(func(entry: Dictionary) -> bool: return entry["player_name"] == "Invalid")
	_check(sanitized.size() == 1 and sanitized[0]["resolved_need_ids"] == ["food"] and sanitized[0]["nestor_status"] == SideQuestLog.STATE_NOT_STARTED, "invalid save inputs are normalized")
	SceneManager.reset()
	_check(SceneManager.get_visited_locations().is_empty(), "reset clears visit history")
	reparent(get_tree().root)
	SceneManager.load_scene("home")
	await _wait_for_visit("home")
	_check(SceneManager.get_visited_locations() == ["home"], "new run records home after arrival")
	SceneManager.travel_to("hardware", "", 0)
	await get_tree().create_timer(0.05).timeout
	SceneManager.reset()
	await get_tree().create_timer(0.7).timeout
	_check(SceneManager.get_visited_locations().is_empty(), "canceled travel cannot add a late visit")
	SceneManager.load_scene("home")
	await _wait_for_visit("home")
	SceneManager.travel_to("ate_linda", "", 0)
	await _wait_for_travel("ate_linda")
	_check(SceneManager.get_visited_locations() == ["home", "tindahan"], "successful Ate Linda arrival records canonical tindahan")
	SceneManager.travel_to("home", "", 0)
	await _wait_for_travel("home")
	SceneManager.travel_to("ate_linda", "", 0)
	await _wait_for_travel("ate_linda")
	_check(SceneManager.get_visited_locations().count("tindahan") == 1, "revisit is recorded once")
	print("Score regression: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(1 if _failures else 0)

func _wait_for_visit(location_id: String) -> bool:
	var deadline := Time.get_ticks_msec() + 10000
	while Time.get_ticks_msec() < deadline:
		if SceneManager.get_visited_locations().has(location_id):
			return true
		await get_tree().create_timer(0.05).timeout
	_check(false, "timed out waiting for visit " + location_id)
	return false

func _wait_for_travel(location_id: String) -> bool:
	var deadline := Time.get_ticks_msec() + 10000
	while Time.get_ticks_msec() < deadline:
		if not SceneManager.is_travelling and SceneManager.current_location == location_id:
			return true
		await get_tree().create_timer(0.05).timeout
	_check(false, "timed out waiting for travel " + location_id)
	return false

func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("Score regression: " + description)
