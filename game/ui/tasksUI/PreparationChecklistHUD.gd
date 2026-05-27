extends CanvasLayer

const UI_STYLE = preload("res://game/ui/GameUIStyle.gd")
const SFX = preload("res://game/audio/Sfx.gd")

@onready var cash_label: Label = $CashPanel/MarginContainer/CashLabel
@onready var checklist_panel: ChecklistPanel = $ChecklistPanel
@onready var checklist_background: Panel = $ChecklistPanel/Panel
@onready var checklist_title: Label = $ChecklistPanel/VBoxContainer/TitleLabel
@onready var checklist_items: VBoxContainer = $ChecklistPanel/VBoxContainer/ScrollContainer/ItemList
@onready var cash_gain_label: Label = $CashGainLabel

var _cash_gain_tween: Tween = null
var _objective_notice: Control = null
var _objective_notice_title: Label = null
var _objective_notice_body: Label = null
var _objective_notice_tween: Tween = null

func _ready() -> void:
	layer = 4
	_set_mouse_filter_recursive(self)
	add_to_group("preparation_checklist_hud")
	if not GameState.cash_changed.is_connected(_on_cash_changed):
		GameState.cash_changed.connect(_on_cash_changed)
	if checklist_panel != null and not checklist_panel.checklist_content_changed.is_connected(_on_checklist_content_changed):
		checklist_panel.checklist_content_changed.connect(_on_checklist_content_changed)
	if not NeedsLog.need_discovered.is_connected(_on_need_discovered):
		NeedsLog.need_discovered.connect(_on_need_discovered)
	LocalizationManager.language_changed.connect(_on_language_changed)
	_on_cash_changed(GameState.get_cash())
	if cash_gain_label != null:
		cash_gain_label.hide()
	_apply_hud_style()
	_setup_checklist_shadow()
	_setup_objective_notice()
	call_deferred("_schedule_checklist_resize")

func _set_mouse_filter_recursive(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_filter_recursive(child)

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
		checklist_title.add_theme_font_size_override("font_size", 22)
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
	shadow.texture = _make_horizontal_shadow_texture(0.46)
	checklist_panel.add_child(shadow)
	checklist_panel.move_child(shadow, 0)

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

func _on_checklist_content_changed() -> void:
	call_deferred("_schedule_checklist_resize")

func _schedule_checklist_resize() -> void:
	await get_tree().process_frame
	_resize_checklist_card()

func _resize_checklist_card() -> void:
	if checklist_panel == null or checklist_items == null:
		return

	var title_height: float = checklist_title.get_combined_minimum_size().y if checklist_title != null else 18.0
	var items_height: float = _get_items_content_height()
	var target_height: float = clampf(title_height + items_height + 42.0, 92.0, 360.0)
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
	if checklist_panel != null:
		checklist_panel.refresh()
