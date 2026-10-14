extends Node

var _checks := 0
var _failures := 0


func _ready() -> void:
	_run.call_deferred()


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print("ATE LINDA ", "PASS " if condition else "FAIL ", label)


func _finish_dialogue(linda: Node) -> void:
	linda.interact()
	for _step in range(12):
		if not linda.get("_is_showing"):
			break
		linda.interact()
		await get_tree().process_frame
	_check(not linda.get("_is_showing"), "dialogue completes")


func _run() -> void:
	if OS.get_environment("BAGYONG_ISOLATED_SMOKE") != OS.get_user_data_dir():
		push_error("Ate Linda regression requires isolated userdata")
		get_tree().quit(1)
		return
	GameState.reset()
	InventoryManager.reset()
	GlobalTimer.start_fresh()
	GameState.add_cash(500)
	_check(InventoryManager.add_item(load("res://game/resources/items/hammer.tres")), "hammer is available")
	var actor := preload("res://game/entities/npcs/shops/ate_linda_npc/ate_linda.tscn").instantiate()
	add_child(actor)
	var linda := actor.get_node("Area3D")
	await _finish_dialogue(linda)
	_check(linda.get("_choice_modal") != null and linda.get("_choice_modal").visible, "hammer triggers trade offer")
	LocalizationManager.set_language("tagalog")
	await get_tree().process_frame
	_check(linda.get("_choice_body").text == LocalizationManager.translate_key("ui.linda_trade_prompt"), "open trade prompt uses its Tagalog key without source overlap")
	LocalizationManager.set_language("english")
	await get_tree().process_frame
	_check(linda.get("_choice_body").text == "Give Ate Linda your hammer so she lowers her prices?", "open trade prompt restores English")
	linda._decline_trade()
	_check(ShopUi.is_open() and ShopUi._current_shop.items[0].price == 90, "declining opens regular-priced shop")
	_check(InventoryManager.has_item_with_id("hammer") and not GameState.ate_linda_discount_unlocked, "declining keeps hammer and prices unchanged")
	if ShopUi.is_open():
		var cash_before := GameState.get_cash()
		var canned_goods: ShopItem = ShopUi._current_shop.items[0]
		ShopUi._on_buy_pressed(canned_goods)
		_check(InventoryManager.has_item_with_id("canned_goods") and GameState.get_cash() == cash_before - 90, "regular-priced purchase still succeeds")
		_check(canned_goods.stock == 3, "regular purchase reduces Linda's finite stock")
	ShopUi.close_shop(true)
	await _finish_dialogue(linda)
	_check(linda.get("_choice_modal").visible, "declined offer returns on next interaction")
	linda._accept_trade()
	_check(GameState.ate_linda_discount_unlocked and not InventoryManager.has_item_with_id("hammer"), "accepted trade consumes hammer and unlocks discount")
	_check(ShopUi.is_open() and ShopUi._current_shop.items[0].price == 55, "accepted trade opens discounted shop")
	_check(ShopUi.is_open() and ShopUi._current_shop.items[0].stock == 3, "discount changes price without replenishing stock")
	_check((load("res://game/resources/shops/ate_linda_shop.tres") as ShopData).items[0].stock == 4 and (load("res://game/resources/shops/ate_linda_shop_discounted.tres") as ShopData).items[0].stock == 4, "trade leaves shared shop resources unchanged")
	ShopUi.close_shop(true)
	await _finish_dialogue(linda)
	_check(not linda.get("_choice_modal").visible and ShopUi.is_open(), "accepted trade is not offered again")
	ShopUi.close_shop(true)
	actor.queue_free()
	print("Ate Linda regression: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)
