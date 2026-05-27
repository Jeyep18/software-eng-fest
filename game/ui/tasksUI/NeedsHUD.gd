# FILE: res://scripts/NeedsHUD.gd
# ATTACH TO: The root CanvasLayer of NeedsHUD.tscn
# PURPOSE: Small always-visible corner list of active (unresolved) tasks.
# Redraws automatically when NeedsLog emits need_discovered or need_resolved.

extends CanvasLayer

# Reference to the VBoxContainer where task label nodes are added.
@onready var task_list: VBoxContainer = $Panel/TaskList


func _ready() -> void:
	# Connect to NeedsLog signals.
	# WHY: We never poll. NeedsLog tells US when something changes.
	# need_discovered fires when a new task is found.
	# need_resolved fires when a task is completed.
	NeedsLog.need_discovered.connect(_on_needs_changed)
	NeedsLog.need_resolved.connect(_on_needs_changed)
	LocalizationManager.language_changed.connect(_on_language_changed)

	# Draw once at start (will be empty, but ensures clean state).
	_redraw()


# Called when either signal fires. The argument is the Need enum value
# but we don't need it — we just redraw the whole list from scratch.
func _on_needs_changed(_need: NeedsLog.Need) -> void:
	_redraw()

func _on_language_changed(_language_id: String) -> void:
	_redraw()


func _redraw() -> void:
	# Clear existing labels.
	for child in task_list.get_children():
		child.queue_free()

	# Get all discovered but unresolved needs.
	var active_needs: Array = NeedsLog.get_unresolved_discovered()

	# Hide the whole panel if there are no active tasks.
	# WHY: No point showing an empty box on screen.
	visible = active_needs.size() > 0

	# Build one Label per active task.
	for need in active_needs:
		var label = Label.new()
		label.text = "- " + NeedsLog.get_need_label(need)
		label.add_theme_font_size_override("font_size", 13)
		task_list.add_child(label)
