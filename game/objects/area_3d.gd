class_name InnerMonologue
extends Interactable

@export_multiline var monologue_text: String = "Wala nang pagkain sa ref. Kailangan bumili bago mawala lahat sa tindahan."  # Set per object in Inspector
@export var auto_dismiss: bool = false             # Toggle in Inspector per object

# Tracks whether monologue is currently visible.
var _is_showing: bool = false


func _ready() -> void:
	# Call parent _ready() — critical, or body_entered/exited never connect.
	super._ready()

	# Listen to our own inherited signal for when player walks away.
	player_exited.connect(_on_player_left)

	# Connect RichTextLabel's finished signal for auto-dismiss mode.
	if auto_dismiss:
		%RichTextLabel.finished.connect(_hide_monologue)

	_hide_monologue()  # Always start hidden.


func interact() -> void:
	# If already showing — pressing interact again dismisses it.
	if _is_showing:
		_hide_monologue()
		return

	_show_monologue()


# Called when player walks out of the Area3D.
func _on_player_left(_interactable: Interactable) -> void:
	_hide_monologue()


func _show_monologue() -> void:
	%RichTextLabel.text = monologue_text

	# bbcode_enabled lets you use [pause], [wave], etc. in monologue_text.
	%RichTextLabel.bbcode_enabled = true

	# visible_ratio animates the text typing effect.
	# Setting to 0 then tweening to 1 gives the typewriter effect.
	%RichTextLabel.visible_ratio = 0.0

	var tween: Tween = create_tween()
	# Adjust the divisor to control typing speed (higher = faster).
	var duration: float = float(%RichTextLabel.text.length()) / 40.0
	tween.tween_property(%RichTextLabel, "visible_ratio", 1.0, duration)

	%BoxContainer.show()
	_is_showing = true


func _hide_monologue() -> void:
	%BoxContainer.hide()
	%RichTextLabel.visible_ratio = 0.0
	_is_showing = false
