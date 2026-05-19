extends CanvasLayer

@onready var cash_label: Label = $CashPanel/MarginContainer/CashLabel

func _ready() -> void:
	layer = 4
	_set_mouse_filter_recursive(self)
	if not GameState.cash_changed.is_connected(_on_cash_changed):
		GameState.cash_changed.connect(_on_cash_changed)
	_on_cash_changed(GameState.get_cash())

func _set_mouse_filter_recursive(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_filter_recursive(child)

func _on_cash_changed(new_balance: int) -> void:
	if cash_label != null:
		cash_label.text = "Pera: PHP %d" % new_balance
