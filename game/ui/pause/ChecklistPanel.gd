# ChecklistPanel.gd
class_name ChecklistPanel
extends Control

signal all_tasks_completed
signal critical_tasks_completed

var _window: Window = null

func _ready() -> void:
	hide()
	# Listen for need resolution — auto-refresh when any task completes
	NeedsLog.need_resolved.connect(_on_need_resolved)
	NeedsLog.need_discovered.connect(_on_need_discovered)
	print("ChecklistPanel signals connected")

func _on_need_resolved(_need: NeedsLog.Need) -> void:
	print("need resolved signal received: ", _need)
	refresh()

func _on_need_discovered(_need: NeedsLog.Need) -> void:
	refresh()

func refresh() -> void:
	if _window == null:
		_build_window()    
	else:
		_rebuild_window()   
	_check_all_complete()

func _check_all_complete() -> void:
	var critical_done: bool = (
		NeedsLog.is_resolved(NeedsLog.Need.ROOF) and
		NeedsLog.is_resolved(NeedsLog.Need.MEDICINE)
	)
	var all_done: bool = (
		NeedsLog.is_resolved(NeedsLog.Need.ROOF)     and
		NeedsLog.is_resolved(NeedsLog.Need.MEDICINE) and
		NeedsLog.is_resolved(NeedsLog.Need.FOOD)     and
		NeedsLog.is_resolved(NeedsLog.Need.WATER)    and
		NeedsLog.is_resolved(NeedsLog.Need.WINDOWS)  and
		NeedsLog.is_resolved(NeedsLog.Need.FLASHLIGHT)
	)

	if all_done:
		print("ALL TASKS COMPLETE")
		all_tasks_completed.emit()
	elif critical_done:
		print("CRITICAL TASKS COMPLETE")
		critical_tasks_completed.emit()

func _build_window() -> void:
	_window = Window.new()
	_window.title = "Preparation Checklist"
	_window.size = Vector2(400, 500)
	_window.position = Vector2(200, 100)
	get_tree().root.add_child(_window)
	_window.close_requested.connect(func(): _window.hide())
	_rebuild_window()
	_window.show()

func _rebuild_window() -> void:
	for child in _window.get_children():
		_window.remove_child(child)
		child.queue_free()

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	_window.add_child(vbox)

	var items = [
		["Patch the roof",      "Tarp + nails + hammer",     "CRITICAL", NeedsLog.Need.ROOF],
		["Get Lola's medicine", "Pharmacy or Barangay Hall", "CRITICAL", NeedsLog.Need.MEDICINE],
		["Store food",          "4x canned goods",           "HIGH",     NeedsLog.Need.FOOD],
		["Fill water jugs",     "Home tap — free",           "HIGH",     NeedsLog.Need.WATER],
		["Board windows",       "Plywood + nails + hammer",  "MED",      NeedsLog.Need.WINDOWS],
		["Assemble flashlight", "Flashlight + batteries",    "MED",      NeedsLog.Need.FLASHLIGHT],
	]

	for item in items:
		var need: NeedsLog.Need = item[3]
		var row := HBoxContainer.new()

		var icon := Label.new()
		if NeedsLog.is_resolved(need):
			icon.text = "✓"
			icon.add_theme_color_override("font_color", Color(0.35, 0.78, 0.45))
		elif NeedsLog.is_discovered(need):
			icon.text = "!"
			icon.add_theme_color_override("font_color", Color(0.90, 0.40, 0.40))
		else:
			icon.text = "○"
			icon.add_theme_color_override("font_color", Color(0.55, 0.53, 0.50))
		row.add_child(icon)

		var lbl := Label.new()
		lbl.text = " " + item[0] + " — " + item[1] + " [" + item[2] + "]"
		if NeedsLog.is_resolved(need):
			lbl.add_theme_color_override("font_color", Color(0.35, 0.78, 0.45))
		row.add_child(lbl)

		vbox.add_child(row)

	_window.close_requested.connect(func(): _window.hide())
	_window.show()
