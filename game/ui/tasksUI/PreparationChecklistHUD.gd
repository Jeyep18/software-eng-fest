extends CanvasLayer

@onready var cash_label: Label = $CashPanel/MarginContainer/CashLabel
@onready var checklist_panel: ChecklistPanel = $ChecklistPanel
@onready var checklist_background: Panel = $ChecklistPanel/Panel
@onready var checklist_title: Label = $ChecklistPanel/VBoxContainer/TitleLabel
@onready var checklist_items: VBoxContainer = $ChecklistPanel/VBoxContainer/ScrollContainer/ItemList
@onready var cash_gain_label: Label = $CashGainLabel

var _cash_gain_tween: Tween = null

func _ready() -> void:
	layer = 4
	_set_mouse_filter_recursive(self)
	add_to_group("preparation_checklist_hud")
	if not GameState.cash_changed.is_connected(_on_cash_changed):
		GameState.cash_changed.connect(_on_cash_changed)
	if checklist_panel != null and not checklist_panel.checklist_content_changed.is_connected(_on_checklist_content_changed):
		checklist_panel.checklist_content_changed.connect(_on_checklist_content_changed)
	_on_cash_changed(GameState.get_cash())
	if cash_gain_label != null:
		cash_gain_label.hide()
	call_deferred("_schedule_checklist_resize")

func _set_mouse_filter_recursive(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_filter_recursive(child)

func _on_cash_changed(new_balance: int) -> void:
	if cash_label != null:
		cash_label.text = "Pera: PHP %d" % new_balance

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
	var target_height: float = clampf(title_height + items_height + 32.0, 64.0, 310.0)
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
