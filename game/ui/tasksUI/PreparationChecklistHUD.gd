extends CanvasLayer

func _ready() -> void:
	layer = 4
	_set_mouse_filter_recursive(self)

func _set_mouse_filter_recursive(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_filter_recursive(child)
