extends Node

const SHOPS := {
	"ate_linda": "res://game/entities/npcs/shops/ate_linda_npc/ate_linda.tscn",
	"grocery": "res://game/entities/npcs/shops/grocery_girl/grocery_girl.tscn",
	"hardware": "res://game/entities/npcs/shops/hardware_girl/hardware_girl.tscn",
	"pharmacy": "res://game/entities/npcs/shops/pharmacist/pharma_dude.tscn",
}

var _checks := 0
var _failures := 0

func _ready() -> void:
	_run.call_deferred()

func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("SHOP DISCOVERY FAIL: " + description)

func _actor(shop_id: String) -> Node3D:
	var actor := load(SHOPS[shop_id]).instantiate() as Node3D
	add_child(actor)
	return actor

func _run() -> void:
	if OS.get_environment("BAGYONG_ISOLATED_SMOKE") != OS.get_user_data_dir():
		push_error("Shop discovery regression requires isolated user data.")
		get_tree().quit(1)
		return
	get_tree().current_scene = null
	for shop_id: String in SHOPS:
		GameState.reset()
		InventoryManager.reset()
		SceneManager.reset()
		GlobalTimer.start_fresh()
		var actor := _actor(shop_id)
		var npc := actor.get_node("Area3D") as NPC
		var cue := actor.get_node("ShopDiscoveryCue") as TaskCue3D
		_check(cue != null and cue.get("shop_id") == shop_id, "only the configured shop identity owns this cue: " + shop_id)
		_check(cue.get_node("Marker").no_depth_test, "shop geometry cannot obscure the discovery symbol: " + shop_id)
		_check(cue.visible and cue._particles.emitting and cue._pulse_tween != null and cue._pulse_tween.is_running(), "unintroduced shop starts with the existing glowing cue: " + shop_id)
		_check_head_clearance(actor, cue, shop_id)
		SceneManager.storm_transition_pending = true
		npc.interact()
		_check(not npc.is_showing and cue.visible and GameState.introduced_shop_npcs.is_empty(), "blocked interaction keeps the indicator: " + shop_id)
		SceneManager.storm_transition_pending = false
		var original_sequence: DialogueSequence = npc.get("sequence_tindahan_default")
		var original_no_hammer: DialogueSequence = null
		npc.set("sequence_tindahan_default", null)
		if shop_id == "ate_linda":
			original_no_hammer = npc.get("no_hammer_sequence")
			npc.set("no_hammer_sequence", null)
		npc.interact()
		_check(not npc.is_showing and cue.visible and GameState.introduced_shop_npcs.is_empty(), "empty dialogue does not consume discovery: " + shop_id)
		npc.set("sequence_tindahan_default", original_sequence)
		if shop_id == "ate_linda":
			npc.set("no_hammer_sequence", original_no_hammer)
		npc.interact()
		_check(npc.is_showing and not cue.visible and not cue._particles.emitting, "first actual dialogue removes the indicator immediately: " + shop_id)
		_check(GameState.introduced_shop_npcs == [shop_id] and cue._pulse_tween == null, "discovery is recorded once and its pulse stops: " + shop_id)
		npc._hide_dialogue()
		_check(not cue.visible and GameState.introduced_shop_npcs == [shop_id], "leaving the first conversation keeps discovery: " + shop_id)
		npc.interact()
		for step in 20:
			if not npc.is_showing:
				break
			npc.interact()
			await get_tree().process_frame
		_check(not npc.is_showing and ShopUi.is_open(), "repeat conversation still opens the normal shop: " + shop_id)
		_check(GameState.introduced_shop_npcs == [shop_id] and not cue.visible, "repeated lines do not duplicate or restore discovery: " + shop_id)
		ShopUi.close_shop(true)
		actor.free()
		await get_tree().process_frame
		actor = _actor(shop_id)
		cue = actor.get_node("ShopDiscoveryCue") as TaskCue3D
		_check(not cue.visible and not cue._particles.emitting, "travel-style unload/reload preserves dismissal: " + shop_id)
		actor.free()
		GameState.reset()
		actor = _actor(shop_id)
		cue = actor.get_node("ShopDiscoveryCue") as TaskCue3D
		_check(cue.visible and cue._particles.emitting and GameState.introduced_shop_npcs.is_empty(), "a fresh run restores the indicator: " + shop_id)
		actor.free()
	GameState.reset()
	var actors: Array[Node3D] = []
	for shop_id: String in SHOPS:
		actors.append(_actor(shop_id))
	actors[0].get_node("Area3D").interact()
	for index in actors.size():
		_check(actors[index].get_node("ShopDiscoveryCue").visible == (index != 0), "meeting one shop leaves other shops undiscovered: " + str(index))
	actors[0].get_node("Area3D")._hide_dialogue()
	for actor in actors:
		actor.free()
	var seller := preload("res://game/entities/npcs/shops/chooks_to_go/chooks_to_go_seller.tscn").instantiate()
	_check(seller.find_child("ShopDiscoveryCue", true, false) == null, "chicken seller remains unmarked")
	seller.free()
	GameState.reset()
	print("Shop discovery regression: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)

func _check_head_clearance(actor: Node3D, cue: TaskCue3D, shop_id: String) -> void:
	var top := 0.0
	for node in actor.get_node("visuals").find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var local_transform := actor.global_transform.affine_inverse() * mesh.global_transform
		for corner in 8:
			top = maxf(top, (local_transform * mesh.get_aabb().get_endpoint(corner)).y)
	_check(cue.position.y >= top + 0.1, "authored cue clears the visible model's head: " + shop_id)
