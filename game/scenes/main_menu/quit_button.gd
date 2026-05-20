extends Button
@onready var _quit_button: Button = $"."

var _confirm_dialog: ConfirmationDialog

func _ready() -> void:
	pressed.connect(_on_pressed)
	_build_confirm_dialog()

func _on_pressed() -> void:
	_confirm_dialog.popup_centered()

func _build_confirm_dialog() -> void:
	_confirm_dialog = ConfirmationDialog.new()
	_confirm_dialog.title = "Quit Game?"
	_confirm_dialog.dialog_text = "Are you sure you want to quit?"
	_confirm_dialog.ok_button_text = "Quit"
	_confirm_dialog.cancel_button_text = "Cancel"
	add_child(_confirm_dialog)
	_confirm_dialog.confirmed.connect(_quit_game)

func _quit_game() -> void:
	_quit_button.disabled = true
	await TransitionOverlay.fade_to_black()
	get_tree().quit()
	
