extends Node3D
## Reuse authored gameplay visuals without their interaction/UI/session scripts.

const HOUSE := preload("res://game/scenes/locations/house_inside.tscn")
const NORMAL_ENVIRONMENT := preload("res://game/resources/environments/house1_environment.tres")
const WRECKED_ENVIRONMENT := preload("res://game/resources/environments/storm_outdoor_environment.tres")
var environment: Environment = NORMAL_ENVIRONMENT
var state: StringName = &"normal"
var _npcs: Array[Node3D] = []
var _native: Node3D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_native = HOUSE.instantiate() as Node3D
	var alignment: Transform3D = _native.get_node("house_inside").transform
	# Keep the approved shot markers, and use the complete gameplay house for Normal.
	for child in $Normal.get_children():
		if child is Camera3D:
			child.current = false
			child.transform = alignment * child.transform
		else:
			child.free()
	$Wrecked.transform = alignment
	for child in $Wrecked.get_children():
		if str(child.name).begins_with("Context__"):
			child.free()
	_native.get_node("playerv2").free()
	_native.get_node("AmbientSounds").free()
	_native.get_node("CameraVolumes").free()
	for child in _native.get_children():
		if child is CSGShape3D:
			child.use_collision = false
			child.owner = null
			_native.remove_child(child)
			$CameraMasks.add_child(child)
		elif str(child.name).begins_with("Spawnpoint") or child is TaskCue3D:
			child.free()
	_native.get_node("Environment/WorldEnvironment").free()
	var sun := _native.get_node("Environment/DirectionalLight3D") as DirectionalLight3D
	sun.owner = null
	sun.get_parent().remove_child(sun)
	$Environment.add_child(sun)
	_strip_gameplay(_native)
	for npc_name in ["nanay", "Lola"]:
		var npc := _native.get_node(npc_name) as Node3D
		_native.remove_child(npc)
		$NPCs.add_child(npc)
		_npcs.append(npc)
	var rain := _native.get_node("Rain").duplicate() as StormRainController
	rain.name = "StormRain"
	rain.intensity_bias = 1.0
	rain.min_amount = 100
	rain.max_amount = 240
	rain.preprocess = 1.0
	rain.process_mode = Node.PROCESS_MODE_PAUSABLE
	$WreckedWeather.add_child(rain)
	for child in _native.get_children():
		if str(child.name) in ["house_inside", "Lights", "Environment", "Rain", "door", "Main_Door", "RoofTaskVisualCue"]:
			continue
		if child.find_children("*", "MeshInstance3D", true, false).is_empty():
			continue
		var prop := child.duplicate(0) as Node
		_strip_gameplay(prop)
		_remove_lights(prop)
		if child.name == &"Tv":
			var normal_stand := _native.get_node("house_inside").find_child("Chest_drawers_03*", true, false) as Node3D
			var wrecked_stand := $Wrecked.find_child("Wrecked__Chest_drawers_03*", true, false) as Node3D
			var support_before := alignment * normal_stand.transform
			var support_after: Transform3D = $Wrecked.transform * wrecked_stand.transform
			(prop as Node3D).transform = support_after * support_before.affine_inverse() * (prop as Node3D).transform
		$WreckedProps.add_child(prop)
	_native.name = "GameplayHouse"
	$Normal.add_child(_native)
	set_state(state)


func set_state(value: StringName) -> void:
	state = value
	environment = NORMAL_ENVIRONMENT if value == &"normal" else WRECKED_ENVIRONMENT
	$Normal.visible = value == &"normal"
	$Wrecked.visible = value == &"wrecked"
	$WreckedLights.visible = value == &"wrecked"
	$WreckedProps.visible = value == &"wrecked"
	$WreckedWeather.visible = value == &"wrecked"
	$NPCs.visible = value == &"normal"
	_native.process_mode = Node.PROCESS_MODE_INHERIT if value == &"normal" else Node.PROCESS_MODE_DISABLED
	$WreckedWeather.process_mode = Node.PROCESS_MODE_INHERIT if value == &"wrecked" else Node.PROCESS_MODE_DISABLED


func apply_visibility(settings: Dictionary) -> void:
	for npc in _npcs:
		npc.visible = not bool(settings[&"hide_npcs"])


func _strip_gameplay(node: Node) -> void:
	node.owner = null
	if not node is StormRainController:
		node.set_script(null)
	for group in node.get_groups():
		node.remove_from_group(group)
	if node is CollisionObject3D:
		node.collision_layer = 0
		node.collision_mask = 0
		if node is Area3D:
			node.monitoring = false
			node.monitorable = false
	for child in node.get_children():
		if child is CanvasLayer or child is Control or child is Camera3D or child is AudioStreamPlayer or child is AudioStreamPlayer3D or child is TaskCue3D or child is SpriteBase3D:
			child.free()
		else:
			_strip_gameplay(child)


func _remove_lights(node: Node) -> void:
	for child in node.get_children():
		if child is Light3D or child is VoxelGI:
			child.free()
		else:
			_remove_lights(child)


func reference_camera() -> Camera3D:
	return $Normal.find_child("ReviewCamera__01_living_dining*", true, false) as Camera3D
