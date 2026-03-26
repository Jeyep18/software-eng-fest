# GlobalTimer.gd
extends Node

signal time_updated(current_min: int)

var current_minutes: int = 0
var is_paused: bool = true  # starts paused — clock only runs after breakfast

func pause_timer() -> void:
	is_paused = true

func resume_timer() -> void:
	is_paused = false

func advance_time(minutes: int) -> void:
	current_minutes += minutes
	emit_signal("time_updated", current_minutes)
