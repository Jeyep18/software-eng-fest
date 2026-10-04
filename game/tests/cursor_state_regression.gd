extends Node

var _failures: int = 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_expect_mode(Input.MOUSE_MODE_VISIBLE, "menus without a player")

	var player := Node.new()
	add_child(player)
	CursorState.register_gameplay(player)
	CursorState.register_gameplay(player)
	_expect_mode(Input.MOUSE_MODE_CAPTURED, "gameplay captures")

	var map_ui := Node.new()
	var pause_ui := Node.new()
	add_child(map_ui)
	add_child(pause_ui)
	CursorState.request_visible(map_ui)
	CursorState.request_visible(pause_ui)
	CursorState.release_visible(map_ui)
	CursorState.release_visible(map_ui)
	_expect_mode(Input.MOUSE_MODE_VISIBLE, "closing map twice leaves pause visible")
	CursorState.release_visible(pause_ui)
	_expect_mode(Input.MOUSE_MODE_CAPTURED, "last UI closing restores gameplay")

	CursorState.request_visible(map_ui)
	CursorState.request_visible(pause_ui)
	CursorState.release_visible(pause_ui)
	_expect_mode(Input.MOUSE_MODE_VISIBLE, "closing pause leaves map visible")
	map_ui.queue_free()
	await get_tree().process_frame
	_expect_mode(Input.MOUSE_MODE_CAPTURED, "freed UI releases its request")

	player.queue_free()
	await get_tree().process_frame
	_expect_mode(Input.MOUSE_MODE_VISIBLE, "leaving gameplay shows menu cursor")
	get_tree().quit(1 if _failures else 0)


func _expect_mode(expected: int, context: String) -> void:
	if Input.get_mouse_mode() == expected:
		return
	_failures += 1
	push_error("CursorState: %s (got %d, expected %d)" % [context, Input.get_mouse_mode(), expected])
