extends Node3D

@onready var leaderboards_button: Button = $VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/leaderboards_button
@onready var leaderboards_modal: CanvasLayer = $LeaderboardsModal
@onready var menu_buttons: VBoxContainer = $VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer

var difficulty_selector: OptionButton
var difficulty_label: Label

# MainMenu.gd
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_setup_difficulty_selector()
	leaderboards_button.pressed.connect(_on_leaderboards_pressed)
	await TransitionOverlay.fade_from_black()
	AudioManager.play_ambience(preload("res://game/assets/sfx/u_7hpxkdroz2-storm-461601.mp3"))
	AudioManager.play_music(preload("res://game/assets/sfx/PhaseShift(chosic.com)-ScottBuckley.mp3"))

func _setup_difficulty_selector() -> void:
	var difficulty_row := HBoxContainer.new()
	difficulty_row.name = "DifficultyRow"
	difficulty_row.add_theme_constant_override("separation", 8)

	difficulty_label = Label.new()
	difficulty_label.text = "Difficulty"
	difficulty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	difficulty_row.add_child(difficulty_label)

	difficulty_selector = OptionButton.new()
	difficulty_selector.name = "DifficultySelector"
	difficulty_selector.add_item("Story", GameState.Difficulty.STORY)
	difficulty_selector.add_item("Standard", GameState.Difficulty.STANDARD)
	difficulty_selector.add_item("Challenge", GameState.Difficulty.CHALLENGE)
	difficulty_selector.select(GameState.selected_difficulty)
	difficulty_selector.item_selected.connect(_on_difficulty_selected)
	difficulty_row.add_child(difficulty_selector)
	menu_buttons.add_child(difficulty_row)
	menu_buttons.move_child(difficulty_row, 1)

func _on_difficulty_selected(index: int) -> void:
	var difficulty := difficulty_selector.get_item_id(index)
	GameState.set_difficulty(difficulty)

func _on_leaderboards_pressed() -> void:
	if leaderboards_modal.has_method("open"):
		leaderboards_modal.open()
