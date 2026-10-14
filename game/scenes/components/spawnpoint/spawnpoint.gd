class_name SpawnPoint 
extends Marker3D

@export var spawn_id: String = "default"

func _ready() -> void:
	var pending: String = SceneManager.get_pending_spawn_id()
	
	# Only activate if we match the requested spawn, or no spawn was requested
	# and we are the default
	if pending.is_empty() and spawn_id != "default":
		return
	if not pending.is_empty() and spawn_id != pending:
		return
		
	_place_player()
	SceneManager.clear_pending_spawn()

func _place_player() -> void:
	var player: Node3D = get_tree().get_first_node_in_group("player")
	if player == null:
		push_error("SpawnPoint: No node in group 'player' found in scene.")
		return
	player.global_position = global_position
	player.global_rotation.y = global_rotation.y
