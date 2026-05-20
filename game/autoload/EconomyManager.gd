# FILE: res://autoloads/EconomyManager.gd
# PURPOSE: Handles all cash purchases and barter trades.
# Register this as an Autoload singleton named "EconomyManager"
# Project > Project Settings > Autoload > add this file
extends Node

# --- SIGNALS ---
signal purchase_succeeded(item_id: String, price: int)
signal purchase_failed(item_id: String, reason: String)
signal barter_succeeded(given_id: String, received_id: String)
signal barter_failed(given_id: String, reason: String)

# --- BARTER STATE ---
# Tracks each NPC trade event: "available" / "completed" / "expired"
# Keys match NPC ids defined in the GDD
var _barter_states: Dictionary = {
	"mang_romy": "available",
	"ate_linda":  "available",
}

# --- PURCHASE ---
## Attempts to buy an item using the player's cash balance.
## item_data: the ItemData resource being purchased
## Returns true if purchase succeeded.
func purchase(item_data: ItemData) -> bool:
	# Guard: does item exist
	if item_data == null:
		push_error("EconomyManager: purchase() called with null ItemData.")
		return false

	# Guard: is item actually purchasable
	if item_data.item_price <= 0:
		purchase_failed.emit(item_data.item_id, "Item is not for sale.")
		print("EconomyManager: '%s' is not purchasable." % item_data.item_name)
		return false

	# Guard: can player afford it
	if not GameState.spend_cash(item_data.item_price):
		purchase_failed.emit(item_data.item_id, "Not enough cash.")
		print("EconomyManager: Not enough cash. Need ₱%d, have ₱%d" % [
			item_data.item_price, GameState.get_cash()])
		return false

	# Guard: is inventory full
	if not InventoryManager.can_accept_item(item_data):
		# Refund the cash — we already spent it above
		GameState.add_cash(item_data.item_price)
		purchase_failed.emit(item_data.item_id, "Inventory full.")
		print("EconomyManager: Inventory full. Refunding ₱%d." % item_data.item_price)
		return false

	# All checks passed — add item to inventory
	InventoryManager.add_item(item_data)
	purchase_succeeded.emit(item_data.item_id, item_data.item_price)
	print("EconomyManager: Purchased '%s' for ₱%d. Remaining cash: ₱%d" % [
		item_data.item_name, item_data.item_price, GameState.get_cash()])
	return true

# --- BARTER ---
## Attempts a barter trade with an NPC.
## npc_id:            String key matching _barter_states (e.g. "mang_romy")
## give_item_id:      item_id the player is giving away
## receive_item_data: ItemData the player will receive
## Returns true if barter succeeded.
func barter(npc_id: String, give_item_id: String, receive_item_data: ItemData) -> bool:
	# Guard: valid npc
	if not _barter_states.has(npc_id):
		push_error("EconomyManager: Unknown npc_id: " + npc_id)
		return false

	# Guard: trade already done or expired
	var state: String = _barter_states[npc_id]
	if state == "completed":
		barter_failed.emit(give_item_id, "Trade already completed.")
		print("EconomyManager: Barter with '%s' already completed." % npc_id)
		return false
	if state == "expired":
		barter_failed.emit(give_item_id, "Trade has expired.")
		print("EconomyManager: Barter with '%s' has expired." % npc_id)
		return false

	# Guard: does player have the item to give
	if not InventoryManager.has_item_with_id(give_item_id):
		barter_failed.emit(give_item_id, "Player does not have required item.")
		print("EconomyManager: Player missing required trade item: '%s'" % give_item_id)
		return false

	# Guard: inventory full for received item
	if InventoryManager.is_full():
		barter_failed.emit(give_item_id, "Inventory full.")
		print("EconomyManager: Inventory full. Cannot receive '%s'." % receive_item_data.item_name)
		return false

	# Guard: received item valid
	if receive_item_data == null:
		push_error("EconomyManager: barter() called with null receive_item_data.")
		return false

	# All checks passed — execute the trade
	InventoryManager.remove_item_by_id(give_item_id)
	InventoryManager.add_item(receive_item_data)
	_barter_states[npc_id] = "completed"

	barter_succeeded.emit(give_item_id, receive_item_data.item_id)
	print("EconomyManager: Barter complete with '%s'. Gave '%s', received '%s'." % [
		npc_id, give_item_id, receive_item_data.item_id])
	return true

# --- BARTER STATE QUERIES ---
## Returns "available" / "completed" / "expired" for a given NPC
func get_barter_state(npc_id: String) -> String:
	return _barter_states.get(npc_id, "unknown")

## Call this when storm encroachment expires a trade window
func expire_barter(npc_id: String) -> void:
	if _barter_states.has(npc_id):
		_barter_states[npc_id] = "expired"
		print("EconomyManager: Barter with '%s' has expired." % npc_id)

# --- RESET ---
func reset() -> void:
	_barter_states = {
		"mang_romy": "available",
		"ate_linda":  "available",
	}
