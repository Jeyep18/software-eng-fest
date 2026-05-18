# ChecklistPanel.gd
class_name ChecklistPanel
extends Control

signal all_tasks_completed
signal critical_tasks_completed

# Completion state guards — prevent signals from firing repeatedly
var _critical_emitted: bool = false
var _all_emitted:      bool = false

@onready var _list: VBoxContainer = $VBoxContainer/ScrollContainer/ItemList

const _ITEMS: Array = [
	# [label,                  hint,                        priority,   Need enum         ]
	["Patch the roof",      "Tarp + nails + hammer",     "CRITICAL", NeedsLog.Need.ROOF      ],
	["Get Lola's medicine", "Pharmacy", "CRITICAL", NeedsLog.Need.MEDICINE  ],
	["Store food",          "4x canned goods",           "HIGH",     NeedsLog.Need.FOOD      ],
	["Fill water jugs",     "Home faucet",           "HIGH",     NeedsLog.Need.WATER     ],
	["Board windows",       "Plywood + nails + hammer",  "MED",      NeedsLog.Need.WINDOWS   ],
	["Assemble flashlight & Radio", "Flashlight + batteries & Radio + Batteries",    "MED",      NeedsLog.Need.FLASHLIGHT],
]

# ── Colours ───────────────────────────────────────────────────────────────────
const _COL_RESOLVED:    Color = Color(0.35, 0.78, 0.45)   # green
const _COL_DISCOVERED:  Color = Color(0.90, 0.40, 0.40)   # red
const _COL_UNDISCOVERED: Color = Color(0.55, 0.53, 0.50)  # grey

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	# No more dynamic ScrollContainer creation here!
	NeedsLog.need_resolved.connect(_on_need_resolved)
	NeedsLog.need_discovered.connect(_on_need_discovered)

	# Defer the first populate
	call_deferred("_populate")

# ── NeedsLog signal handlers ──────────────────────────────────────────────────
func _on_need_resolved(_need: NeedsLog.Need) -> void:
	# Repopulate the list silently — panel visibility is PauseMenu's responsibility
	_populate()
	_check_completion()

func _on_need_discovered(_need: NeedsLog.Need) -> void:
	_populate()

# ── Public API ────────────────────────────────────────────────────────────────
# Called by PauseMenu whenever it switches to this panel — ensures display is current
func refresh() -> void:
	_populate()
	_check_completion()

# ── Internal ──────────────────────────────────────────────────────────────────
func _populate() -> void:
	if not _list:
		return
	# Clear previous rows — remove_child takes them out of the tree immediately,
	# queue_free cleans up memory at end of frame. Safe to add new children right after.
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()

	for item: Array in _ITEMS:
		var need:     NeedsLog.Need = item[3]
		var resolved: bool          = NeedsLog.is_resolved(need)
		var discovered: bool        = NeedsLog.is_discovered(need)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		# Status icon
		var icon := Label.new()
		if resolved:
			icon.text = "✓"
			icon.add_theme_color_override("font_color", _COL_RESOLVED)
		elif discovered:
			icon.text = "!"
			icon.add_theme_color_override("font_color", _COL_DISCOVERED)
		else:
			icon.text = "○"
			icon.add_theme_color_override("font_color", _COL_UNDISCOVERED)
		row.add_child(icon)

		# Task label
		var lbl := Label.new()
		lbl.text = "%s — %s  [%s]" % [item[0], item[1], item[2]]
		lbl.add_theme_color_override("font_color",
			_COL_RESOLVED if resolved else Color.WHITE)
			
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(lbl)

		_list.add_child(row)

func _check_completion() -> void:
	var critical_done: bool = (
		NeedsLog.is_resolved(NeedsLog.Need.ROOF) and
		NeedsLog.is_resolved(NeedsLog.Need.MEDICINE)
	)
	var all_done: bool = (
		critical_done and
		NeedsLog.is_resolved(NeedsLog.Need.FOOD)       and
		NeedsLog.is_resolved(NeedsLog.Need.WATER)      and
		NeedsLog.is_resolved(NeedsLog.Need.WINDOWS)    and
		NeedsLog.is_resolved(NeedsLog.Need.FLASHLIGHT)
	)

	# Guard flags prevent the same signal from firing on every subsequent refresh
	if all_done and not _all_emitted:
		_all_emitted = true
		all_tasks_completed.emit()
	elif critical_done and not _critical_emitted:
		_critical_emitted = true
		critical_tasks_completed.emit()
