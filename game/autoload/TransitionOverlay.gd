# TransitionOverlay.gd — Autoload Singleton
extends CanvasLayer

var overlay: ColorRect
var tween: Tween

func _ready() -> void:
	layer = 10  # always on top of everything

	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)


func fade_to_black() -> void:
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	tween = create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.6)\
		 .set_ease(Tween.EASE_IN)
	await tween.finished


func fade_from_black() -> void:
	tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.0, 0.6)\
		 .set_ease(Tween.EASE_OUT)
	await tween.finished
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
