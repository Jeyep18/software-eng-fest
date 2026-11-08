class_name ShopDiscoveryCue
extends TaskCue3D

@export var shop_id: String = ""
@export var npc_path: NodePath = NodePath("../Area3D")

func _ready() -> void:
	var npc := get_node_or_null(npc_path) as NPC
	# Keep the discovery symbol readable under shop roofs and counter beams.
	$Marker.no_depth_test = true
	visible = npc != null and not shop_id.is_empty() and not GameState.introduced_shop_npcs.has(shop_id)
	super._ready()
	if npc == null or shop_id.is_empty():
		push_warning("ShopDiscoveryCue requires a shop ID and NPC dialogue target.")
		return
	npc.prompt_visibility_changed.connect(_on_prompt_visibility_changed.bind(npc))

func _on_prompt_visibility_changed(should_show: bool, npc: NPC) -> void:
	if should_show or not npc.is_showing:
		return
	if not GameState.introduced_shop_npcs.has(shop_id):
		GameState.introduced_shop_npcs.append(shop_id)
	set_active(false)
