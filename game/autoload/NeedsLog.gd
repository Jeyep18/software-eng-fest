# NeedsLog.gd
extends Node

var discovered_needs: Array[String] = []

func log_need(need_id: String) -> void:
	if not discovered_needs.has(need_id):
		discovered_needs.append(need_id)

func is_need_discovered(need_id: String) -> bool:
	return discovered_needs.has(need_id)
