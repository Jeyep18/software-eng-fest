# FILE: res://scripts/TaskObject.gd
class_name TaskObject
extends Interactable

@export var completion_visual_cue: Node = null
@export var interaction_prompt: String = ""
@export var need: NeedsLog.Need = NeedsLog.Need.ROOF
@export var required_item_ids: Array[String] = []

# ── TIME COST ─────────────────────────────────────────────────────────────────
# How many in-game minutes this task consumes on completion.
# Added as a burst via GlobalTimer.add_time() — same as travel costs.
# The passive tick also runs during the task animation (fade + wait),
# so the real total cost is time_cost_minutes + ~1–2 min of passive tick.
# That small bleed is intentional — tasks take real time.
#
# GDD reference values:
#   Repair / boarding task      → 10–20 min
#   Securing outdoor items      → 5–10 min
#   Fill water jugs             → 5 min
#   Inventory combine           → 2 min
@export var time_cost_minutes: int = 15

@export var missing_lines: Array[String] = [
	"Kailangan ko muna ng supplies."
]
@export var ready_lines: Array[String] = [
	"Pwede ko na to ayusin."
]
@export var completed_lines: Array[String] = [
	"Naayos ko na ito."
]
@export var chars_per_second: float = 40.0
@export var monologue_ui_scene: PackedScene

const PLAYER_NAME: String = "Player"

var _ui: MonologueUI = null
var _current_line: int = 0
var _is_showing: bool = false
var _is_typing: bool = false
var _tween: Tween = null
var _showing_ready_branch: bool = false
var _is_completed: bool = false

func _ready() -> void:
	super._ready()
	prompt_label = interaction_prompt
	player_exited.connect(_on_player_left)
	_setup_ui()
	
	# ── SYNC WITH GLOBAL STATE ────────────────────────────────────────────────
	# Check if this task's need was already resolved in a previous visit.
	# (Note: Replace 'is_resolved' with the actual method name your NeedsLog 
	# uses to check if a need is complete, e.g., is_need_met, check_status, etc.)
	if NeedsLog.is_resolved(need): 
		_is_completed = true
		if completion_visual_cue != null:
			completion_visual_cue.visible = true

func _setup_ui() -> void:
	if monologue_ui_scene == null:
		push_error("TaskObject: monologue_ui_scene not assigned on " + name)
		return
	_ui = monologue_ui_scene.instantiate() as MonologueUI
	%CanvasLayer.add_child(_ui)
	_ui.hide_ui()

func interact() -> void:
	if not _is_showing:
		_current_line = 0
		if _is_completed:
			_showing_ready_branch = false
			_show_line(completed_lines)
			return
		elif _has_all_required_items():
			_showing_ready_branch = true
			_show_line(ready_lines)
			return
		_showing_ready_branch = false
		NeedsLog.discover(need)
		_show_line(missing_lines)
		return

	if _is_typing:
		_skip_to_line_end()
		return

	_current_line += 1
	var lines: Array[String]
	if _is_completed:
		lines = completed_lines
	elif _showing_ready_branch:
		lines = ready_lines
	else:
		lines = missing_lines

	if _current_line >= lines.size():
		var was_ready_branch: bool = _showing_ready_branch
		_hide_monologue()
		if was_ready_branch:
			_complete_task()
		return

	_show_line(lines)

func _has_all_required_items() -> bool:
	var current_inv_ids = []
	for item in InventoryManager.inventory:
		if item != null:
			current_inv_ids.append(item.item_id)
	for req_id in required_item_ids:
		if req_id in current_inv_ids:
			current_inv_ids.erase(req_id)
		else:
			return false
	return true

func _complete_task() -> void:
	# ── FADE OUT ───────────────────────────────────────────────────────────────
	# Pause the tick during the black screen so the burst cost is the only
	# time deducted — not the fade duration on top of it.
	GlobalTimer.pause_timer()
	await TransitionOverlay.fade_to_black()

	# ── CONSUME REQUIRED ITEMS ─────────────────────────────────────────────────
	for item_id in required_item_ids:
		for i in range(InventoryManager.inventory.size()):
			var item = InventoryManager.inventory[i]
			if item and item.item_id == item_id:
				if item.item_type in [
					ItemData.ItemType.BRING_HOME,
					ItemData.ItemType.USE_IN_PLACE,
					ItemData.ItemType.COMBINE
				]:
					InventoryManager.remove_item(i)
					break

	# ── BURST TIME COST ────────────────────────────────────────────────────────
	# add_time() fires time_updated and encroachment checks automatically.
	# Clock is still paused here (black screen) — this is an instant burst,
	# not a tick. The passive tick resumes after fade_from_black().
	if time_cost_minutes > 0:
		GlobalTimer.add_time(time_cost_minutes)

	NeedsLog.resolve(need)
	
	if completion_visual_cue != null:
		completion_visual_cue.visible = true

	await get_tree().create_timer(0.5).timeout

	# ── FADE IN — resume tick ──────────────────────────────────────────────────
	await TransitionOverlay.fade_from_black()
	GlobalTimer.resume_timer()   # tick resumes now — player is back in world
	

	get_tree().call_group("hotbar_ui", "set_hotbar_visible", true)
	_is_completed = true
	print("TaskObject: Completed — ", NeedsLog.NEED_LABELS.get(need, str(need)),
		  " | Burst cost: %d min" % time_cost_minutes)

func _show_line(lines: Array[String]) -> void:
	# Pause tick while dialogue is on screen — reading text is free.
	get_tree().call_group("hotbar_ui", "set_hotbar_visible", false)
	is_showing    = true
	_is_showing   = true
	_is_typing    = true
	var line: String = lines[_current_line]
	_ui.show_line(line, PLAYER_NAME)
	_ui.set_prompt_visible(false)
	prompt_visibility_changed.emit(false)
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = _ui.run_typewriter(chars_per_second)
	_tween.finished.connect(_on_typewriter_finished, CONNECT_ONE_SHOT)

func _skip_to_line_end() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_ui.skip_to_end()
	_ui.set_prompt_visible(true)
	_is_typing = false

func _hide_monologue() -> void:
	# Resume tick — player dismissed dialogue, back in the world.
	get_tree().call_group("hotbar_ui", "set_hotbar_visible", true)
	is_showing  = false
	if _tween and _tween.is_valid():
		_tween.kill()
	_ui.hide_ui()
	_is_showing           = false
	_is_typing            = false
	_current_line         = 0
	_showing_ready_branch = false
	prompt_visibility_changed.emit(true)

func _on_typewriter_finished() -> void:
	_is_typing = false
	_ui.set_prompt_visible(true)

func _on_player_left(_interactable: Interactable) -> void:
	if _is_showing:
		_hide_monologue()
