extends Node

# Mouse mode is global: closing one UI must not capture it while another is open.
var _visible_owners: Dictionary = {}
var _gameplay_owners: Dictionary = {}
var _watched_owners: Dictionary = {}


func request_visible(owner: Node) -> void:
	if not is_instance_valid(owner):
		return
	var id := owner.get_instance_id()
	_watch(owner, id)
	_visible_owners[id] = true
	_refresh()


func release_visible(owner: Node) -> void:
	if not is_instance_valid(owner):
		return
	_visible_owners.erase(owner.get_instance_id())
	_refresh()


func is_requesting_visible(owner: Node) -> bool:
	return is_instance_valid(owner) and _visible_owners.has(owner.get_instance_id())


func register_gameplay(owner: Node) -> void:
	if not is_instance_valid(owner):
		return
	var id := owner.get_instance_id()
	_watch(owner, id)
	_gameplay_owners[id] = true
	_refresh()


func _watch(owner: Node, id: int) -> void:
	if _watched_owners.has(id):
		return
	_watched_owners[id] = true
	owner.tree_exiting.connect(_owner_exiting.bind(id), CONNECT_ONE_SHOT)


func _owner_exiting(id: int) -> void:
	_watched_owners.erase(id)
	_visible_owners.erase(id)
	_gameplay_owners.erase(id)
	_refresh()


func _refresh() -> void:
	var mode := Input.MOUSE_MODE_VISIBLE if not _visible_owners.is_empty() or _gameplay_owners.is_empty() else Input.MOUSE_MODE_CAPTURED
	if Input.get_mouse_mode() != mode:
		Input.set_mouse_mode(mode)
