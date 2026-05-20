extends Node3D

@export_group("Lightning")
@export var lightning_min_delay: float = 4.0
@export var lightning_max_delay: float = 11.0
@export var lightning_flash_energy: float = 24.0
@export var lightning_flash_duration: float = 0.08
@export_range(0.0, 1.0) var lightning_double_flash_chance: float = 0.45
@export var lightning_double_flash_delay: float = 0.12
@export var lightning_double_flash_energy_scale: float = 0.65

@onready var leaderboards_button: Button = $VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/leaderboards_button
@onready var leaderboards_modal: CanvasLayer = $LeaderboardsModal
@onready var menu_buttons: VBoxContainer = $VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer
@onready var lightning: SpotLight3D = $Lights/Lightning

var difficulty_selector: OptionButton
var difficulty_label: Label
var _lightning_active: bool = true

# MainMenu.gd
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_setup_lightning()
	_setup_difficulty_selector()
	leaderboards_button.pressed.connect(_on_leaderboards_pressed)
	await TransitionOverlay.fade_from_black()
	AudioManager.play_ambience(preload("res://game/assets/sfx/u_7hpxkdroz2-storm-461601.mp3"))
	AudioManager.play_music(preload("res://game/assets/sfx/PhaseShift(chosic.com)-ScottBuckley.mp3"))
	_run_lightning_loop()

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

func _exit_tree() -> void:
	_lightning_active = false

func _setup_lightning() -> void:
	lightning.visible = false
	lightning.light_energy = 0.0
	lightning.light_color = Color(0.78, 0.86, 1.0)

func _run_lightning_loop() -> void:
	while _lightning_active:
		var delay := randf_range(lightning_min_delay, lightning_max_delay)
		await get_tree().create_timer(delay).timeout

		if not _lightning_active:
			return

		await _flash_lightning(lightning_flash_energy, lightning_flash_duration)

		if randf() <= lightning_double_flash_chance:
			await get_tree().create_timer(lightning_double_flash_delay).timeout

			if not _lightning_active:
				return

			await _flash_lightning(
				lightning_flash_energy * lightning_double_flash_energy_scale,
				lightning_flash_duration * 0.85
			)

func _flash_lightning(energy: float, duration: float) -> void:
	lightning.visible = true
	lightning.light_energy = energy
	lightning.light_indirect_energy = energy * 0.65
	lightning.light_volumetric_fog_energy = energy * 0.4

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(lightning, "light_energy", 0.0, duration)
	tween.parallel().tween_property(lightning, "light_indirect_energy", 0.0, duration)
	tween.parallel().tween_property(lightning, "light_volumetric_fog_energy", 0.0, duration)
	await tween.finished

	lightning.visible = false
