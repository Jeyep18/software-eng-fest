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
	await _fade(1.0)


func fade_from_black() -> void:
	await _fade(0.0)

func _fade(alpha: float) -> void:
	if tween != null and tween.is_valid():
		tween.kill()
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var active_tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween = active_tween
	active_tween.tween_property(overlay, "color:a", alpha, 0.6).set_ease(
		Tween.EASE_IN if alpha == 1.0 else Tween.EASE_OUT)
	# Killed tweens never emit finished. Let superseded callers resume and cancel.
	while active_tween.is_valid() and active_tween.is_running():
		await get_tree().process_frame
	if tween == active_tween and alpha == 0.0:
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
