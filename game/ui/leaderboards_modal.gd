extends CanvasLayer

const UI_STYLE = preload("res://game/ui/GameUIStyle.gd")
const TABLE_WIDTH: float = 900.0
const ROW_BG: Color = Color(1, 1, 1, 0.035)
const ROW_BG_ALT: Color = Color(1, 1, 1, 0.065)
const HEADER_BG: Color = Color(0.122, 0.486, 0.404, 0.18)

@onready var close_button: Button = $MarginContainer/LeaderboardsModal/VBoxContainer/Header/close_button
@onready var clear_button: Button = $MarginContainer/LeaderboardsModal/VBoxContainer/Header/clear_button
@onready var title_label: Label = $MarginContainer/LeaderboardsModal/VBoxContainer/Header/TitleLabel
@onready var rows_container: VBoxContainer = $MarginContainer/LeaderboardsModal/VBoxContainer/ScrollContainer/RowsContainer
@onready var empty_label: Label = $MarginContainer/LeaderboardsModal/VBoxContainer/ScrollContainer/RowsContainer/EmptyLabel

var _clear_armed: bool = false

func _ready() -> void:
	close_button.pressed.connect(close)
	clear_button.pressed.connect(_on_clear_pressed)
	rows_container.custom_minimum_size = Vector2(TABLE_WIDTH, 0)
	rows_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rows_container.add_theme_constant_override("separation", 7)
	empty_label.custom_minimum_size = Vector2(TABLE_WIDTH, 220)
	empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if not LeaderboardManager.entries_changed.is_connected(_refresh):
		LeaderboardManager.entries_changed.connect(_refresh)
	_apply_leaderboard_style()
	hide()

func open() -> void:
	_clear_armed = false
	_update_clear_button()
	_refresh()
	show()

func close() -> void:
	hide()

func _refresh() -> void:
	title_label.text = "LEADERBOARDS"
	for child in rows_container.get_children():
		if child != empty_label:
			rows_container.remove_child(child)
			child.queue_free()

	var entries: Array[Dictionary] = LeaderboardManager.get_ranked_entries()
	empty_label.visible = entries.is_empty()
	clear_button.disabled = entries.is_empty()

	if entries.is_empty():
		return

	_add_header_row()
	for i in range(entries.size()):
		_add_entry_row(i + 1, entries[i])

func _add_header_row() -> void:
	var row := _make_row(true)
	_add_cell(row, "Rank", 72, true)
	_add_cell(row, "Player", 220, true)
	_add_cell(row, "Difficulty", 180, true)
	_add_cell(row, "Score", 110, true)
	_add_cell(row, "Tasks", 100, true)
	_add_cell(row, "Time Left", 140, true)

func _add_entry_row(rank: int, entry: Dictionary) -> void:
	var row := _make_row(false, rank % 2 == 0)
	_add_cell(row, "#" + str(rank), 72, false)
	_add_cell(row, str(entry.get("player_name", "Player")), 220, false)
	_add_cell(row, _difficulty_label_with_multiplier(str(entry.get("difficulty", "standard"))), 180, false)
	_add_cell(row, "%d" % roundi(float(entry.get("score", 0.0))), 110, false)
	_add_cell(row, "%d / %d" % [int(entry.get("tasks_completed", 0)), NeedsLog.Need.size()], 100, false)
	_add_cell(row, _format_minutes(int(entry.get("remaining_minutes", 0))), 140, false)

func _make_row(is_header: bool = false, alternate: bool = false) -> HBoxContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(TABLE_WIDTH, 40 if is_header else 38)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var bg := HEADER_BG if is_header else (ROW_BG_ALT if alternate else ROW_BG)
	panel.add_theme_stylebox_override("panel", UI_STYLE.panel_style(bg, Color(1, 1, 1, 0.07), 6))
	rows_container.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)
	return row

func _add_cell(row: HBoxContainer, text: String, min_width: float, is_header: bool) -> void:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(min_width, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", UI_STYLE.FONT_SEMIBOLD if is_header else UI_STYLE.FONT_REGULAR)
	label.add_theme_font_size_override("font_size", 15 if is_header else 16)
	label.add_theme_color_override("font_color", UI_STYLE.ACCENT if is_header else Color(0.88, 0.87, 0.81))
	row.add_child(label)

func _format_minutes(minutes: int) -> String:
	var safe_minutes: int = max(minutes, 0)
	var hours: int = safe_minutes / 60
	var mins: int = safe_minutes % 60
	return "%dh %02dm" % [hours, mins]

func _on_clear_pressed() -> void:
	if not _clear_armed:
		_clear_armed = true
		_update_clear_button()
		return

	LeaderboardManager.clear_entries()
	_clear_armed = false
	_update_clear_button()

func _update_clear_button() -> void:
	clear_button.text = "CONFIRM CLEAR" if _clear_armed else "CLEAR"

func _difficulty_label(difficulty_id: String) -> String:
	match difficulty_id:
		"story":
			return "Story"
		"challenge":
			return "Challenge"
		_:
			return "Standard"

func _difficulty_label_with_multiplier(difficulty_id: String) -> String:
	return "%s x%.2f" % [_difficulty_label(difficulty_id), GameState.get_difficulty_score_multiplier(difficulty_id)]

func _apply_leaderboard_style() -> void:
	var panel := $MarginContainer/LeaderboardsModal as PanelContainer
	panel.add_theme_stylebox_override("panel", UI_STYLE.panel_style(Color(0.025, 0.028, 0.03, 0.94), UI_STYLE.BORDER, 8))
	UI_STYLE.apply_button(close_button)
	UI_STYLE.apply_button(clear_button)
	UI_STYLE.apply_label(title_label, false, true)
	UI_STYLE.apply_label(empty_label, true)
	title_label.add_theme_font_size_override("font_size", 24)
