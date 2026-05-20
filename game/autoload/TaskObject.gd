class_name TaskObject
extends Interactable

@export var completion_visual_cue: Node = null
@export var task_cue: Node3D = null
@export var show_cue_only_when_discovered: bool = false
@export var discover_on_interact: bool = true
@export var interaction_prompt: String = ""
@export var need: NeedsLog.Need = NeedsLog.Need.ROOF
@export var required_item_ids: Array[String] = []
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
const CONSUMABLE_TASK_ITEM_TYPES: Array[int] = [
	ItemData.ItemType.BRING_HOME,
	ItemData.ItemType.USE_IN_PLACE,
	ItemData.ItemType.COMBINE,
]

var _ui: MonologueUI = null
var _current_line: int = 0
var _is_showing: bool = false
var _is_typing: bool = false
var _tween: Tween = null
var _showing_ready_branch: bool = false
var _is_completed: bool = false
var _paused_timer_for_dialogue: bool = false

func _ready() -> void:
	super._ready()
	prompt_label = interaction_prompt
	if not player_exited.is_connected(_on_player_left):
		player_exited.connect(_on_player_left)
	_setup_ui()
	_connect_needs_log()
	_sync_completion_state()
	_update_task_cue()

func interact() -> void:
	if not is_interaction_available():
		return

	if not _is_showing:
		_begin_dialogue()
		return

	if _is_typing:
		_skip_to_line_end()
		return

	_advance_dialogue()

func _connect_needs_log() -> void:
	if not NeedsLog.need_discovered.is_connected(_on_need_discovered):
		NeedsLog.need_discovered.connect(_on_need_discovered)
	if not NeedsLog.need_resolved.is_connected(_on_need_resolved):
		NeedsLog.need_resolved.connect(_on_need_resolved)
	if not GameState.guide_tasks_changed.is_connected(_on_guide_tasks_changed):
		GameState.guide_tasks_changed.connect(_on_guide_tasks_changed)

func _sync_completion_state() -> void:
	if not NeedsLog.is_resolved(need):
		return

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

func _begin_dialogue() -> void:
	_current_line = 0

	if _is_completed:
		_showing_ready_branch = false
	elif _has_all_required_items():
		_showing_ready_branch = true
		if discover_on_interact:
			NeedsLog.discover(need)
	else:
		_showing_ready_branch = false
		if discover_on_interact:
			NeedsLog.discover(need)

	_show_line(_get_active_lines())

func _advance_dialogue() -> void:
	_current_line += 1
	var lines: Array[String] = _get_active_lines()

	if _current_line >= lines.size():
		var was_ready_branch: bool = _showing_ready_branch
		_hide_monologue()
		if was_ready_branch:
			_complete_task()
		return

	_show_line(lines)

func _get_active_lines() -> Array[String]:
	if _is_completed:
		return completed_lines
	if _showing_ready_branch:
		return ready_lines
	return missing_lines

func _has_all_required_items() -> bool:
	var required_counts: Dictionary = {}
	for req_id in required_item_ids:
		required_counts[req_id] = int(required_counts.get(req_id, 0)) + 1

	for req_id in required_counts.keys():
		if InventoryManager.get_total_quantity(req_id) < int(required_counts[req_id]):
			return false

	return true

func _complete_task() -> void:
	GlobalTimer.pause_timer()
	await TransitionOverlay.fade_to_black()

	_consume_required_items()
	_apply_completion_state()

	await get_tree().create_timer(0.5).timeout
	await TransitionOverlay.fade_from_black()
	GlobalTimer.resume_timer()

	get_tree().call_group("hotbar_ui", "set_hotbar_visible", true)
	_is_completed = true
	print("TaskObject: Completed - ", NeedsLog.NEED_LABELS.get(need, str(need)),
			" | Burst cost: %d min" % time_cost_minutes)

func _consume_required_items() -> void:
	var required_counts: Dictionary = {}
	for item_id in required_item_ids:
		required_counts[item_id] = int(required_counts.get(item_id, 0)) + 1

	for item_id in required_counts.keys():
		var remaining: int = int(required_counts[item_id])
		for i in range(InventoryManager.inventory.size() - 1, -1, -1):
			var item = InventoryManager.inventory[i]
			if item and item.item_id == item_id and _can_consume_task_item(item):
				var available: int = InventoryManager.get_item_quantity(i)
				var to_remove: int = mini(available, remaining)
				InventoryManager.remove_item_quantity(i, to_remove)
				remaining -= to_remove
				if remaining <= 0:
					break

func _can_consume_task_item(item: ItemData) -> bool:
	return item.item_type in CONSUMABLE_TASK_ITEM_TYPES

func _apply_completion_state() -> void:
	if time_cost_minutes > 0:
		GlobalTimer.add_time(time_cost_minutes)

	NeedsLog.resolve(need)
	_update_task_cue()

	if completion_visual_cue != null:
		completion_visual_cue.visible = true

func _update_task_cue() -> void:
	if task_cue == null:
		return

	var should_show := GameState.house_tasks_unlocked and not NeedsLog.is_resolved(need)
	if show_cue_only_when_discovered:
		should_show = should_show and NeedsLog.is_discovered(need)

	if task_cue.has_method("set_active"):
		task_cue.set_active(should_show)
	else:
		task_cue.visible = should_show

func _show_line(lines: Array[String]) -> void:
	if lines.is_empty():
		push_warning("TaskObject: no dialogue lines configured on " + name)
		_hide_monologue()
		return

	get_tree().call_group("hotbar_ui", "set_hotbar_visible", false)
	get_tree().call_group("player", "set_movement_locked", true)
	if not _paused_timer_for_dialogue:
		GlobalTimer.pause_timer()
		_paused_timer_for_dialogue = true
	is_showing = true
	_is_showing = true
	_is_typing = true

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
	get_tree().call_group("hotbar_ui", "set_hotbar_visible", true)
	get_tree().call_group("player", "set_movement_locked", false)
	is_showing = false

	if _tween and _tween.is_valid():
		_tween.kill()
	_ui.hide_ui()

	_is_showing = false
	_is_typing = false
	_current_line = 0
	_showing_ready_branch = false
	if _paused_timer_for_dialogue:
		GlobalTimer.resume_timer()
		_paused_timer_for_dialogue = false
	prompt_visibility_changed.emit(true)

func _on_need_discovered(discovered_need: NeedsLog.Need) -> void:
	if discovered_need == need:
		_update_task_cue()

func _on_need_resolved(resolved_need: NeedsLog.Need) -> void:
	if resolved_need != need:
		return

	_is_completed = true
	_update_task_cue()

func is_interaction_available() -> bool:
	return GameState.house_tasks_unlocked or _is_completed

func _on_guide_tasks_changed() -> void:
	_update_task_cue()

func _on_typewriter_finished() -> void:
	_is_typing = false
	_ui.set_prompt_visible(true)

func _on_player_left(_interactable: Interactable) -> void:
	if _is_showing:
		_hide_monologue()
