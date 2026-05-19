extends TaskObject

@export var window_id: String = "window"
@export var required_items: Array[String] = [
	"plywood",
	"nails",
	"hammer"
]

func _ready() -> void:
	super._ready()
	prompt_label = interaction_prompt
	required_item_ids = required_items
	if not NeedsLog.window_boarded.is_connected(_on_window_boarded):
		NeedsLog.window_boarded.connect(_on_window_boarded)
	_sync_completion_state()

func interact() -> void:
	super.interact()

func _sync_completion_state() -> void:
	if not NeedsLog.is_window_boarded(window_id):
		return

	_is_completed = true
	if completion_visual_cue != null:
		completion_visual_cue.visible = true
	_update_task_cue()

func _apply_completion_state() -> void:
	if time_cost_minutes > 0:
		GlobalTimer.add_time(time_cost_minutes)

	NeedsLog.discover(need)
	NeedsLog.board_window(window_id)
	_update_task_cue()

	if completion_visual_cue != null:
		completion_visual_cue.visible = true

func _update_task_cue() -> void:
	if task_cue == null:
		return

	var should_show := GameState.house_tasks_unlocked and not NeedsLog.is_window_boarded(window_id)
	if show_cue_only_when_discovered:
		should_show = should_show and NeedsLog.is_discovered(need)

	if task_cue.has_method("set_active"):
		task_cue.set_active(should_show)
	else:
		task_cue.visible = should_show

func _on_window_boarded(boarded_window_id: String, _boarded_count: int) -> void:
	if boarded_window_id != window_id:
		return

	_is_completed = true
	_update_task_cue()
