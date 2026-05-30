extends CanvasLayer

const UI_STYLE = preload("res://game/ui/GameUIStyle.gd")
const SFX = preload("res://game/audio/Sfx.gd")

@onready var cash_label: Label = $CashPanel/MarginContainer/CashLabel
@onready var checklist_panel: ChecklistPanel = $ChecklistPanel
@onready var checklist_background: Panel = $ChecklistPanel/Panel
@onready var checklist_title: Label = $ChecklistPanel/VBoxContainer/TitleLabel
@onready var checklist_items: VBoxContainer = $ChecklistPanel/VBoxContainer/ScrollContainer/ItemList
@onready var cash_gain_label: Label = $CashGainLabel
@onready var objective_box: VBoxContainer = $ChecklistPanel/VBoxContainer
@onready var objective_scroll: ScrollContainer = $ChecklistPanel/VBoxContainer/ScrollContainer

const PREPARATION_OBJECTIVES: Array[Dictionary] = [
	{ "need": NeedsLog.Need.ROOF, "label": "Patch the roof" },
	{ "need": NeedsLog.Need.MEDICINE, "label": "Get Lola's medicine" },
	{ "need": NeedsLog.Need.FOOD, "label": "Store food" },
	{ "need": NeedsLog.Need.WATER, "label": "Fill water jugs" },
	{ "need": NeedsLog.Need.WINDOWS, "label": "Board both windows" },
	{ "need": NeedsLog.Need.FLASHLIGHT, "label": "Assemble flashlight & radio" },
]

var _cash_gain_tween: Tween = null
var _objective_notice: Control = null
var _objective_notice_title: Label = null
var _objective_notice_body: Label = null
var _objective_notice_tween: Tween = null
var _objective_row_tweens: Dictionary = {}

func _ready() -> void:
	layer = 4
	_set_mouse_filter_recursive(self)
	add_to_group("preparation_checklist_hud")
	_disable_embedded_full_checklist_updates()
	if not GameState.cash_changed.is_connected(_on_cash_changed):
		GameState.cash_changed.connect(_on_cash_changed)
	if not NeedsLog.need_discovered.is_connected(_on_need_discovered):
		NeedsLog.need_discovered.connect(_on_need_discovered)
	if not NeedsLog.need_resolved.is_connected(_on_need_resolved):
		NeedsLog.need_resolved.connect(_on_need_resolved)
	if not GameState.guide_tasks_changed.is_connected(_on_guide_tasks_changed):
		GameState.guide_tasks_changed.connect(_on_guide_tasks_changed)
	if not SideQuestLog.side_objectives_changed.is_connected(_on_side_objectives_changed):
		SideQuestLog.side_objectives_changed.connect(_on_side_objectives_changed)
	if not SideQuestLog.side_objective_started.is_connected(_on_side_objective_started):
		SideQuestLog.side_objective_started.connect(_on_side_objective_started)
	LocalizationManager.language_changed.connect(_on_language_changed)
	VisualSettings.ui_scale_changed.connect(_on_ui_scale_changed)
	_on_cash_changed(GameState.get_cash())
	if cash_gain_label != null:
		cash_gain_label.hide()
	_apply_hud_style()
	_setup_checklist_shadow()
	_setup_compact_objectives()
	_setup_objective_notice()
	_apply_ui_scale()
	_refresh_compact_objectives(false)
	call_deferred("_refresh_compact_objectives", false)

func _set_mouse_filter_recursive(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_filter_recursive(child)

func _disable_embedded_full_checklist_updates() -> void:
	if checklist_panel == null:
		return
	var signal_pairs: Array[Array] = [
		[NeedsLog.need_resolved, "_on_need_resolved"],
		[NeedsLog.need_discovered, "_on_need_discovered"],
		[GameState.guide_tasks_changed, "_on_guide_tasks_changed"],
		[LocalizationManager.language_changed, "_on_language_changed"],
	]
	for pair in signal_pairs:
		var signal_ref: Signal = pair[0]
		var method_name: StringName = StringName(pair[1])
		var callable := Callable(checklist_panel, method_name)
		if signal_ref.is_connected(callable):
			signal_ref.disconnect(callable)

func _on_cash_changed(new_balance: int) -> void:
	if cash_label != null:
		cash_label.text = LocalizationManager.trf("Pera: PHP %d", [new_balance])

func _apply_hud_style() -> void:
	UI_STYLE.apply_panel($CashPanel, true)
	UI_STYLE.apply_label(cash_label)
	UI_STYLE.apply_label(checklist_title, false, true)
	UI_STYLE.apply_label(cash_gain_label, false, true)
	if checklist_background != null:
		checklist_background.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	if cash_label != null:
		cash_label.add_theme_font_override("font", UI_STYLE.FONT_SEMIBOLD)
		cash_label.add_theme_font_size_override("font_size", 22)
		cash_label.add_theme_color_override("font_color", Color.WHITE)
	if checklist_title != null:
		checklist_title.text = "OBJECTIVES"
		checklist_title.add_theme_font_override("font", UI_STYLE.FONT_SEMIBOLD)
		checklist_title.add_theme_color_override("font_color", Color.WHITE)
		checklist_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
		checklist_title.add_theme_constant_override("shadow_offset_x", 2)
		checklist_title.add_theme_constant_override("shadow_offset_y", 2)

func _setup_checklist_shadow() -> void:
	if checklist_panel == null:
		return
	var existing := checklist_panel.get_node_or_null("ObjectiveShadow") as TextureRect
	if existing != null:
		return
	var shadow := TextureRect.new()
	shadow.name = "ObjectiveShadow"
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.set_anchors_preset(Control.PRESET_FULL_RECT)
	shadow.stretch_mode = TextureRect.STRETCH_SCALE
	shadow.texture = _make_horizontal_shadow_texture(0.28)
	checklist_panel.add_child(shadow)
	checklist_panel.move_child(shadow, 0)

func _setup_compact_objectives() -> void:
	if objective_scroll != null:
		objective_scroll.show()
		objective_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		objective_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

func _setup_objective_notice() -> void:
	_objective_notice = Control.new()
	_objective_notice.name = "ObjectiveNotice"
	_objective_notice.modulate.a = 0.0
	_objective_notice.visible = false
	_objective_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objective_notice.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_objective_notice.anchor_left = 0.335
	_objective_notice.anchor_right = 0.665
	_objective_notice.anchor_top = 0.25
	_objective_notice.anchor_bottom = 0.25
	_objective_notice.offset_left = 0.0
	_objective_notice.offset_top = -48.0
	_objective_notice.offset_right = 0.0
	_objective_notice.offset_bottom = 58.0
	add_child(_objective_notice)

	var shadow := TextureRect.new()
	shadow.name = "NoticeShadow"
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.set_anchors_preset(Control.PRESET_FULL_RECT)
	shadow.stretch_mode = TextureRect.STRETCH_SCALE
	shadow.texture = _make_horizontal_shadow_texture(0.62)
	_objective_notice.add_child(shadow)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_objective_notice.add_child(center)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	center.add_child(box)

	_objective_notice_title = Label.new()
	_objective_notice_title.text = "NEW OBJECTIVE"
	_objective_notice_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_notice_title.add_theme_font_override("font", UI_STYLE.FONT_SEMIBOLD)
	_objective_notice_title.add_theme_font_size_override("font_size", 30)
	_objective_notice_title.add_theme_color_override("font_color", UI_STYLE.ACCENT)
	_objective_notice_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_objective_notice_title.add_theme_constant_override("shadow_offset_x", 2)
	_objective_notice_title.add_theme_constant_override("shadow_offset_y", 2)
	box.add_child(_objective_notice_title)

	_objective_notice_body = Label.new()
	_objective_notice_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_notice_body.add_theme_font_override("font", UI_STYLE.FONT_REGULAR)
	_objective_notice_body.add_theme_font_size_override("font_size", 22)
	_objective_notice_body.add_theme_color_override("font_color", Color.WHITE)
	_objective_notice_body.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_objective_notice_body.add_theme_constant_override("shadow_offset_x", 2)
	_objective_notice_body.add_theme_constant_override("shadow_offset_y", 2)
	box.add_child(_objective_notice_body)

func _make_horizontal_shadow_texture(alpha: float) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.18, 0.82, 1.0])
	gradient.colors = PackedColorArray([
		Color(0, 0, 0, 0.0),
		Color(0, 0, 0, alpha),
		Color(0, 0, 0, alpha),
		Color(0, 0, 0, 0.0),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_LINEAR
	texture.fill_from = Vector2(0.0, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture

func _on_need_discovered(need: NeedsLog.Need) -> void:
	if _objective_notice == null or _objective_notice_body == null:
		return
	_objective_notice_body.text = NeedsLog.get_need_label(need)
	_objective_notice.visible = true
	_objective_notice.modulate.a = 0.0
	SFX.objective_notice()
	if _objective_notice_tween != null and _objective_notice_tween.is_valid():
		_objective_notice_tween.kill()
	_objective_notice_tween = create_tween()
	_objective_notice_tween.tween_property(_objective_notice, "modulate:a", 1.0, 0.28)
	_objective_notice_tween.tween_interval(2.0)
	_objective_notice_tween.tween_property(_objective_notice, "modulate:a", 0.0, 0.55)
	_objective_notice_tween.finished.connect(func() -> void:
		if _objective_notice != null:
			_objective_notice.visible = false
	)
	_refresh_compact_objectives(false)

func _on_need_resolved(_need: NeedsLog.Need) -> void:
	_refresh_compact_objectives(true)

func _on_checklist_content_changed() -> void:
	_refresh_compact_objectives(false)

func _on_guide_tasks_changed() -> void:
	_refresh_compact_objectives(true)

func _on_side_objectives_changed() -> void:
	_refresh_compact_objectives(true)

func _on_side_objective_started(label: String) -> void:
	if _objective_notice == null or _objective_notice_body == null:
		return
	_objective_notice_body.text = LocalizationManager.translate(label)
	_objective_notice.visible = true
	_objective_notice.modulate.a = 0.0
	SFX.objective_notice()
	if _objective_notice_tween != null and _objective_notice_tween.is_valid():
		_objective_notice_tween.kill()
	_objective_notice_tween = create_tween()
	_objective_notice_tween.tween_property(_objective_notice, "modulate:a", 1.0, 0.28)
	_objective_notice_tween.tween_interval(2.0)
	_objective_notice_tween.tween_property(_objective_notice, "modulate:a", 0.0, 0.55)
	_objective_notice_tween.finished.connect(func() -> void:
		if _objective_notice != null:
			_objective_notice.visible = false
	)
	_refresh_compact_objectives(false)

func _schedule_checklist_resize() -> void:
	await get_tree().process_frame
	_resize_checklist_card()

func _resize_checklist_card() -> void:
	if checklist_panel == null:
		return

	var title_height: float = checklist_title.get_combined_minimum_size().y if checklist_title != null else VisualSettings.scaled(18.0)
	var items_height: float = _get_items_content_height()
	var target_height: float = clampf(
		title_height + items_height + VisualSettings.scaled(28.0),
		VisualSettings.scaled(104.0),
		VisualSettings.scaled(240.0)
	)
	checklist_panel.offset_bottom = checklist_panel.offset_top + target_height

	if checklist_background != null:
		checklist_background.offset_bottom = 0.0

func _get_items_content_height() -> float:
	var total_height: float = 0.0
	var visible_rows: int = 0
	for child in checklist_items.get_children():
		if child is Control and child.visible:
			total_height += child.get_combined_minimum_size().y
			visible_rows += 1

	if visible_rows > 1:
		total_height += float(visible_rows - 1) * float(checklist_items.get_theme_constant("separation"))

	return total_height

func show_cash_gain(amount: int) -> void:
	if cash_gain_label == null or amount <= 0:
		return

	if _cash_gain_tween != null and _cash_gain_tween.is_valid():
		_cash_gain_tween.kill()

	cash_gain_label.text = "+%d PHP" % amount
	cash_gain_label.modulate = Color(0.45, 1.0, 0.48, 1.0)
	cash_gain_label.show()

	_cash_gain_tween = create_tween()
	_cash_gain_tween.tween_property(cash_gain_label, "modulate:a", 1.0, 0.2)
	_cash_gain_tween.tween_interval(1.6)
	_cash_gain_tween.tween_property(cash_gain_label, "modulate:a", 0.0, 0.6)
	_cash_gain_tween.finished.connect(func() -> void:
		if cash_gain_label != null:
			cash_gain_label.hide()
		_cash_gain_tween = null
	)

func _on_language_changed(_language_id: String) -> void:
	_on_cash_changed(GameState.get_cash())
	if checklist_title != null:
		checklist_title.text = "OBJECTIVES"
	_refresh_compact_objectives(false)

func _on_ui_scale_changed(_scale: float) -> void:
	_apply_ui_scale()
	_refresh_compact_objectives(false)
	call_deferred("_schedule_checklist_resize")

func _apply_ui_scale() -> void:
	var scale := VisualSettings.get_ui_scale()
	$CashPanel.offset_left = 16.0
	$CashPanel.offset_top = 24.0
	$CashPanel.offset_right = 16.0 + (344.0 * scale)
	$CashPanel.offset_bottom = 24.0 + (50.0 * scale)
	checklist_panel.offset_left = 16.0
	checklist_panel.offset_top = 86.0 * scale
	checklist_panel.offset_right = 16.0 + (292.0 * scale)
	cash_label.add_theme_font_size_override("font_size", int(roundi(22.0 * scale)))
	checklist_title.add_theme_font_size_override("font_size", int(roundi(18.0 * scale)))
	if objective_box != null:
		objective_box.add_theme_constant_override("separation", int(roundi(3.0 * scale)))
	checklist_items.add_theme_constant_override("separation", int(roundi(2.0 * scale)))
	cash_gain_label.add_theme_font_size_override("font_size", int(roundi(30.0 * scale)))
	cash_gain_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	cash_gain_label.anchor_left = 0.335
	cash_gain_label.anchor_right = 0.665
	cash_gain_label.anchor_top = 0.25
	cash_gain_label.anchor_bottom = 0.25
	cash_gain_label.offset_left = 0.0
	cash_gain_label.offset_top = -48.0 * scale
	cash_gain_label.offset_right = 0.0
	cash_gain_label.offset_bottom = 58.0 * scale
	for child in checklist_items.get_children():
		if child is HBoxContainer:
			_apply_objective_row_scale(child as HBoxContainer)

func _refresh_compact_objectives(animate_removed: bool) -> void:
	if checklist_items == null:
		return

	var desired := _get_active_objectives()
	var desired_keys: Array[String] = []
	for data in desired:
		desired_keys.append(str(data["key"]))

	for child in checklist_items.get_children():
		if not child.has_meta("objective_key"):
			child.queue_free()
			continue
		var key := str(child.get_meta("objective_key"))
		if not desired_keys.has(key):
			_remove_objective_row(child as Control, animate_removed)

	for data in desired:
		var key := str(data["key"])
		var row := _find_objective_row(key)
		if row == null:
			checklist_items.add_child(_make_objective_row(key, str(data["label"])))
		else:
			var label := row.get_node_or_null("Label") as Label
			if label != null:
				label.text = LocalizationManager.translate(str(data["label"]))

	call_deferred("_schedule_checklist_resize")

func _get_active_objectives() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not GameState.house_tasks_unlocked:
		result.append({ "key": "guide_nanay", "label": "Talk to Nanay" })
	if not GameState.talked_to_lola:
		result.append({ "key": "guide_lola", "label": "Talk to Lola" })
	if not GameState.house_exploration_complete:
		result.append({ "key": "guide_explore", "label": "Explore around the house" })

	for data in PREPARATION_OBJECTIVES:
		var need: NeedsLog.Need = data["need"]
		if NeedsLog.is_discovered(need) and not NeedsLog.is_resolved(need):
			result.append({ "key": "need_%d" % int(need), "label": str(data["label"]) })

	for data in SideQuestLog.get_active_objectives():
		result.append(data)

	if result.is_empty():
		result.append({ "key": "all_done", "label": "All discovered objectives complete" })
	return result

func _make_objective_row(key: String, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "ObjectiveRow"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_meta("objective_key", key)
	row.add_theme_constant_override("separation", int(roundi(5.0 * VisualSettings.get_ui_scale())))

	var icon := Label.new()
	icon.name = "Icon"
	icon.text = "!"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.add_theme_font_override("font", UI_STYLE.FONT_SEMIBOLD)
	icon.add_theme_color_override("font_color", UI_STYLE.ACCENT)
	icon.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	icon.add_theme_constant_override("shadow_offset_x", 1)
	icon.add_theme_constant_override("shadow_offset_y", 1)
	row.add_child(icon)

	var label := Label.new()
	label.name = "Label"
	label.text = LocalizationManager.translate(text)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_override("font", UI_STYLE.FONT_REGULAR)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	row.add_child(label)

	_apply_objective_row_scale(row)
	return row

func _apply_objective_row_scale(row: HBoxContainer) -> void:
	var scale := VisualSettings.get_ui_scale()
	row.add_theme_constant_override("separation", int(roundi(5.0 * scale)))
	var icon := row.get_node_or_null("Icon") as Label
	if icon != null:
		icon.custom_minimum_size = Vector2(15.0 * scale, 0.0)
		icon.add_theme_font_size_override("font_size", int(roundi(14.0 * scale)))
	var label := row.get_node_or_null("Label") as Label
	if label != null:
		label.add_theme_font_size_override("font_size", int(roundi(14.0 * scale)))

func _find_objective_row(key: String) -> HBoxContainer:
	for child in checklist_items.get_children():
		if child.has_meta("objective_key") and str(child.get_meta("objective_key")) == key:
			return child as HBoxContainer
	return null

func _remove_objective_row(row: Control, animate_removed: bool) -> void:
	if row == null or not is_instance_valid(row):
		return
	var key := str(row.get_meta("objective_key", ""))
	if _objective_row_tweens.has(key):
		return
	if not animate_removed:
		row.queue_free()
		return
	var tween := create_tween()
	_objective_row_tweens[key] = tween
	tween.tween_property(row, "modulate:a", 0.0, 1.2)
	tween.finished.connect(func() -> void:
		_objective_row_tweens.erase(key)
		if is_instance_valid(row):
			row.queue_free()
		call_deferred("_schedule_checklist_resize")
	)
