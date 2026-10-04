extends CanvasLayer

const UI_STYLE = preload("res://game/ui/GameUIStyle.gd")
const TABLE_WIDTH: float = 900.0
const PANEL_FADE_DURATION: float = 0.15
const ROW_BG: Color = Color(1, 1, 1, 0.035)
const ROW_BG_ALT: Color = Color(1, 1, 1, 0.065)
const HEADER_BG: Color = Color(0.122, 0.486, 0.404, 0.18)

@onready var close_button: Button = $MarginContainer/LeaderboardsModal/VBoxContainer/Header/close_button
@onready var clear_button: Button = $MarginContainer/LeaderboardsModal/VBoxContainer/Header/clear_button
@onready var title_label: Label = $MarginContainer/LeaderboardsModal/VBoxContainer/Header/TitleLabel
@onready var rows_container: VBoxContainer = $MarginContainer/LeaderboardsModal/VBoxContainer/ScrollContainer/RowsContainer
@onready var empty_label: Label = $MarginContainer/LeaderboardsModal/VBoxContainer/ScrollContainer/RowsContainer/EmptyLabel
@onready var margin_container: MarginContainer = $MarginContainer

var _clear_armed: bool = false
var _panel_tween: Tween = null

func _ready() -> void:
	close_button.pressed.connect(close)
	clear_button.pressed.connect(_on_clear_pressed)
	rows_container.custom_minimum_size = Vector2(_table_width(), 0)
	rows_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows_container.add_theme_constant_override("separation", 7)
	empty_label.custom_minimum_size = Vector2(_table_width(), 220.0 * _table_scale())
	empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if not LeaderboardManager.entries_changed.is_connected(_refresh):
		LeaderboardManager.entries_changed.connect(_refresh)
	VisualSettings.ui_scale_changed.connect(_on_ui_scale_changed)
	get_viewport().size_changed.connect(_on_viewport_resized)
	_apply_leaderboard_style()
	hide()

func open() -> void:
	if _panel_tween != null and _panel_tween.is_valid():
		_panel_tween.kill()
	close_button.disabled = false
	_clear_armed = false
	_update_clear_button()
	_refresh()
	show()
	margin_container.modulate.a = 0.0
	_panel_tween = create_tween()
	_panel_tween.tween_property(margin_container, "modulate:a", 1.0, PANEL_FADE_DURATION)

func close() -> void:
	if not visible:
		return
	if _panel_tween != null and _panel_tween.is_valid():
		_panel_tween.kill()
	close_button.disabled = true
	clear_button.disabled = true
	_panel_tween = create_tween()
	_panel_tween.tween_property(margin_container, "modulate:a", 0.0, PANEL_FADE_DURATION)
	_panel_tween.finished.connect(func() -> void:
		hide()
		close_button.disabled = false
	)

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
	_add_cell(row, "Rank", 60 * _table_scale(), true)
	_add_cell(row, "Player", 0, true)
	_add_cell(row, "Difficulty", 160 * _table_scale(), true)
	_add_cell(row, "Score", 100 * _table_scale(), true)
	_add_cell(row, "Tasks", 90 * _table_scale(), true)
	_add_cell(row, "Time Left", 130 * _table_scale(), true)

func _add_entry_row(rank: int, entry: Dictionary) -> void:
	var row := _make_row(false, rank % 2 == 0)
	_add_cell(row, "#" + str(rank), 60 * _table_scale(), false)
	_add_cell(row, str(entry.get("player_name", "Player")), 0, false)
	_add_cell(row, _difficulty_label_with_multiplier(str(entry.get("difficulty", "standard"))), 160 * _table_scale(), false)
	_add_cell(row, "%d" % roundi(float(entry.get("score", 0.0))), 100 * _table_scale(), false)
	_add_cell(row, "%d / %d" % [int(entry.get("tasks_completed", 0)), NeedsLog.Need.size()], 90 * _table_scale(), false)
	_add_cell(row, _format_minutes(int(entry.get("remaining_minutes", 0))), 130 * _table_scale(), false)

func _make_row(is_header: bool = false, alternate: bool = false) -> HBoxContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(_table_width(), (40.0 if is_header else 38.0) * _table_scale())
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bg := HEADER_BG if is_header else (ROW_BG_ALT if alternate else ROW_BG)
	panel.add_theme_stylebox_override("panel", UI_STYLE.panel_style(bg, Color(1, 1, 1, 0.07), 6))
	rows_container.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", roundi(14.0 * _table_scale()))
	margin.add_theme_constant_override("margin_right", roundi(14.0 * _table_scale()))
	margin.add_theme_constant_override("margin_top", roundi(5.0 * _table_scale()))
	margin.add_theme_constant_override("margin_bottom", roundi(5.0 * _table_scale()))
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", roundi(10.0 * _table_scale()))
	margin.add_child(row)
	return row

func _add_cell(row: HBoxContainer, text: String, min_width: float, is_header: bool) -> void:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(min_width, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL if min_width == 0 else Control.SIZE_FILL
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", UI_STYLE.FONT_SEMIBOLD if is_header else UI_STYLE.FONT_REGULAR)
	label.add_theme_font_size_override("font_size", roundi((15.0 if is_header else 16.0) * _table_scale()))
	label.add_theme_color_override("font_color", UI_STYLE.ACCENT if is_header else Color(0.88, 0.87, 0.81))
	row.add_child(label)

func _format_minutes(minutes: int) -> String:
	var safe_minutes: int = max(minutes, 0)
	# Whole hours; the remaining minutes are formatted separately.
	@warning_ignore("integer_division")
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
	var ui_scale := _table_scale()
	var horizontal_margin := maxi(24, roundi((get_viewport().get_visible_rect().size.x - _table_width()) * 0.5))
	margin_container.add_theme_constant_override("margin_left", horizontal_margin)
	margin_container.add_theme_constant_override("margin_right", horizontal_margin)
	margin_container.add_theme_constant_override("margin_top", maxi(36, int(roundi(170.0 / ui_scale))))
	margin_container.add_theme_constant_override("margin_bottom", maxi(36, int(roundi(170.0 / ui_scale))))
	var panel := $MarginContainer/LeaderboardsModal as PanelContainer
	panel.add_theme_stylebox_override("panel", UI_STYLE.panel_style(Color(0.025, 0.028, 0.03, 0.94), UI_STYLE.BORDER, 8))
	UI_STYLE.apply_button(close_button)
	UI_STYLE.apply_button(clear_button)
	close_button.custom_minimum_size = Vector2(104, 44) * ui_scale
	clear_button.custom_minimum_size = Vector2(132, 44) * ui_scale
	UI_STYLE.apply_label(title_label, false, true)
	UI_STYLE.apply_label(empty_label, true)
	title_label.add_theme_font_size_override("font_size", int(roundi(24.0 * ui_scale)))

func _table_width() -> float:
	return TABLE_WIDTH * _table_scale()

func _table_scale() -> float:
	return minf(VisualSettings.get_ui_scale(), (get_viewport().get_visible_rect().size.x - 48.0) / TABLE_WIDTH)

func _on_ui_scale_changed(_scale: float) -> void:
	rows_container.custom_minimum_size = Vector2(_table_width(), 0)
	empty_label.custom_minimum_size = Vector2(_table_width(), 220.0 * _table_scale())
	_apply_leaderboard_style()
	if visible:
		_refresh()

func _on_viewport_resized() -> void:
	_on_ui_scale_changed(VisualSettings.get_ui_scale())
