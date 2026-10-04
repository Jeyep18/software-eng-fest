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
	var multiplier := GameState.get_difficulty_score_multiplier("challenge")
	var score := LeaderboardManager.calculate_score(3, 90, "challenge")
	_check(is_equal_approx(score, 3090.0 * multiplier), "score uses task, time and difficulty values")
	_check(LeaderboardManager.calculate_score(0, -20, "standard") == 0.0, "negative time is clamped")
	_check(is_equal_approx(LeaderboardManager.calculate_score(1, 9999, "standard"), 1720.0), "remaining time is capped")
	LeaderboardManager.record_run("UI check", 3, 90, "challenge")
	_check(is_equal_approx(float(LeaderboardManager.get_ranked_entries()[0]["score"]), score), "saved and displayed score use the same calculation")
	print("Score regression: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(1 if _failures else 0)

func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("Score regression: " + description)
