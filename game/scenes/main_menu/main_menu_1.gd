extends Node3D

@export_group("Lightning")
@export var lightning_min_delay: float = 4.0
@export var lightning_max_delay: float = 11.0
@export var lightning_flash_energy: float = 24.0
@export var lightning_flash_duration: float = 0.08
@export_range(0.0, 1.0) var lightning_double_flash_chance: float = 0.45
@export var lightning_double_flash_delay: float = 0.12
@export var lightning_double_flash_energy_scale: float = 0.65
@export_group("Parallax")
@export var camera_yaw_limit: float = 0.035
@export var camera_pitch_limit: float = 0.022
@export var camera_roll_limit: float = 0.004
@export var parallax_smoothing: float = 5.0

@onready var leaderboards_button: Button = $VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/leaderboards_button
@onready var credits_button: Button = $VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/credits_button
@onready var leaderboards_modal: CanvasLayer = $LeaderboardsModal
@onready var credits_modal: CanvasLayer = $CreditsModal
@onready var menu_buttons: VBoxContainer = $VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer
@onready var lightning: SpotLight3D = $Lights/Lightning
@onready var title_label: Label = $VBoxContainer/VBoxContainer/RichTextLabel
@onready var subtitle_label: Label = $VBoxContainer/VBoxContainer/RichTextLabel2
@onready var menu_camera: Camera3D = $SubViewportContainer/SubViewport/Camera3D

const TUTORIAL_MODAL_SCENE: PackedScene = preload("res://game/ui/tutorial/TutorialModal.tscn")
const UI_STYLE = preload("res://game/ui/GameUIStyle.gd")
const SFX = preload("res://game/audio/Sfx.gd")

var difficulty_selector: OptionButton
var difficulty_label: Label
var tutorial_button: Button
var replay_intro_button: Button
var settings_button: Button
var _settings_layer: CanvasLayer
var _settings_panel: AudioSettingsPanel
var _lightning_active: bool = true
var _parallax_target: Vector2 = Vector2.ZERO
var _parallax_current: Vector2 = Vector2.ZERO
var _camera_base_position: Vector3
var _camera_base_rotation: Vector3

# MainMenu.gd
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_setup_lightning()
	_setup_difficulty_selector()
	_setup_settings_button()
	_setup_tutorial_button()
	_setup_replay_intro_button()
	_setup_settings_panel()
	_apply_menu_ui_style()
	_capture_camera_base()
	credits_button.pressed.connect(_on_credits_pressed)
	var credits_close := credits_modal.get_node_or_null("MarginContainer/CreditsModal/VBoxContainer/HBoxContainer/close_button") as Button
	if credits_close != null:
		credits_close.pressed.connect(func() -> void: credits_modal.visible = false)
	leaderboards_button.pressed.connect(_on_leaderboards_pressed)
	await TransitionOverlay.fade_from_black()
	AudioManager.play_ambience(preload("res://game/assets/sfx/u_7hpxkdroz2-storm-461601.mp3"))
	AudioManager.play_music(preload("res://game/assets/sfx/PhaseShift(chosic.com)-ScottBuckley.mp3"))
	_run_lightning_loop()

func _process(delta: float) -> void:
	_update_parallax_target()
	_parallax_current = _parallax_current.lerp(_parallax_target, 1.0 - exp(-parallax_smoothing * delta))
	_apply_parallax()

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

func _setup_tutorial_button() -> void:
	tutorial_button = Button.new()
	tutorial_button.name = "tutorial_button"
	tutorial_button.text = "TUTORIAL / CONTROLS"
	tutorial_button.pressed.connect(_on_tutorial_pressed)
	menu_buttons.add_child(tutorial_button)
	menu_buttons.move_child(tutorial_button, menu_buttons.get_child_count() - 2)

func _setup_settings_button() -> void:
	settings_button = Button.new()
	settings_button.name = "settings_button"
	settings_button.text = "SETTINGS"
	settings_button.pressed.connect(_on_settings_pressed)
	menu_buttons.add_child(settings_button)
	menu_buttons.move_child(settings_button, 3)

func _setup_settings_panel() -> void:
	_settings_layer = CanvasLayer.new()
	_settings_layer.layer = 30
	_settings_layer.visible = false
	add_child(_settings_layer)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.56)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_settings_layer.add_child(dim)

	_settings_panel = AudioSettingsPanel.new()
	_settings_panel.custom_minimum_size = Vector2(460, 340)
	_settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	_settings_panel.offset_left = -230.0
	_settings_panel.offset_top = -170.0
	_settings_panel.offset_right = 230.0
	_settings_panel.offset_bottom = 170.0
	_settings_panel.close_requested.connect(_on_settings_close_requested)
	_settings_layer.add_child(_settings_panel)

func _setup_replay_intro_button() -> void:
	replay_intro_button = Button.new()
	replay_intro_button.name = "replay_intro_button"
	replay_intro_button.text = "REPLAY INTRO"
	replay_intro_button.custom_minimum_size = Vector2(180, 42)
	replay_intro_button.pressed.connect(_on_replay_intro_pressed)
	add_child(replay_intro_button)
	replay_intro_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	replay_intro_button.offset_left = 32.0
	replay_intro_button.offset_top = -74.0
	replay_intro_button.offset_right = 212.0
	replay_intro_button.offset_bottom = -32.0

func _apply_menu_ui_style() -> void:
	for child in menu_buttons.get_children():
		if child is Button:
			_apply_main_menu_button_style(child)
			child.custom_minimum_size = Vector2(220, 44)
		elif child is HBoxContainer:
			for row_child in child.get_children():
				if row_child is Label:
					UI_STYLE.apply_label(row_child, false, true)
				elif row_child is OptionButton:
					_apply_main_menu_button_style(row_child)

	_apply_main_menu_button_style(replay_intro_button)
	if title_label.label_settings != null:
		title_label.label_settings.font_color = Color(1.0, 0.91, 0.66)
		title_label.label_settings.shadow_color = Color(0.08, 0.05, 0.025, 0.9)
	if subtitle_label.label_settings != null:
		subtitle_label.label_settings.font_color = Color(0.93, 0.80, 0.55)
		subtitle_label.label_settings.shadow_color = Color(0.08, 0.05, 0.025, 0.85)

func _apply_main_menu_button_style(button: Button) -> void:
	button.add_theme_font_override("font", UI_STYLE.FONT_SEMIBOLD)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(1, 1, 1, 0.78))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", UI_STYLE.ACCENT)
	button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.35))
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("focus", empty)
	button.add_theme_stylebox_override("disabled", empty)
	button.mouse_entered.connect(_on_menu_button_hovered.bind(button, true))
	button.mouse_exited.connect(_on_menu_button_hovered.bind(button, false))
	button.button_down.connect(_on_menu_button_pressed.bind(button))
	button.button_up.connect(_on_menu_button_released.bind(button))
	SFX.wire_button(button)
	_ensure_button_hover_fill(button)

func _ensure_button_hover_fill(button: Button) -> ColorRect:
	var fill := button.get_node_or_null("HoverFill") as ColorRect
	if fill == null:
		fill = ColorRect.new()
		fill.name = "HoverFill"
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fill.show_behind_parent = true
		fill.color = Color(0.98, 0.9, 0.62, 0.16)
		fill.set_anchors_preset(Control.PRESET_FULL_RECT)
		fill.offset_left = 0.0
		fill.offset_top = 0.0
		fill.offset_right = 0.0
		fill.offset_bottom = 0.0
		fill.scale.x = 0.0
		button.add_child(fill)
	button.clip_contents = true
	return fill

func _on_menu_button_hovered(button: Button, is_hovered: bool) -> void:
	var fill := _ensure_button_hover_fill(button)
	if not button.has_meta("menu_base_position_x"):
		button.set_meta("menu_base_position_x", button.position.x)
	var base_x := float(button.get_meta("menu_base_position_x"))
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(fill, "scale:x", 1.0 if is_hovered else 0.0, 0.18)
	tween.tween_property(button, "scale", Vector2(1.04, 1.04) if is_hovered else Vector2.ONE, 0.18)
	tween.tween_property(button, "position:x", base_x + (8.0 if is_hovered else 0.0), 0.18)

func _on_menu_button_pressed(button: Button) -> void:
	create_tween().tween_property(button, "scale", Vector2(0.98, 0.98), 0.08).set_trans(Tween.TRANS_QUAD)

func _on_menu_button_released(button: Button) -> void:
	var target := Vector2(1.04, 1.04) if button.is_hovered() else Vector2.ONE
	create_tween().tween_property(button, "scale", target, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _capture_camera_base() -> void:
	_camera_base_position = menu_camera.position
	_camera_base_rotation = menu_camera.rotation

func _update_parallax_target() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		_parallax_target = Vector2.ZERO
		return
	var mouse := get_viewport().get_mouse_position()
	var centered := (mouse / viewport_size) * 2.0 - Vector2.ONE
	_parallax_target = Vector2(clampf(centered.x, -1.0, 1.0), clampf(centered.y, -1.0, 1.0))

func _apply_parallax() -> void:
	var p := _parallax_current
	menu_camera.position = _camera_base_position
	menu_camera.rotation = _camera_base_rotation + Vector3(
		p.y * camera_pitch_limit,
		-p.x * camera_yaw_limit,
		p.x * camera_roll_limit
	)

func _on_difficulty_selected(index: int) -> void:
	var difficulty := difficulty_selector.get_item_id(index)
	GameState.set_difficulty(difficulty)

func _on_leaderboards_pressed() -> void:
	if leaderboards_modal.has_method("open"):
		leaderboards_modal.open()

func _on_credits_pressed() -> void:
	credits_modal.visible = true

func _on_settings_pressed() -> void:
	_settings_layer.visible = true

func _on_settings_close_requested() -> void:
	_settings_layer.visible = false

func _on_tutorial_pressed() -> void:
	var tutorial := TUTORIAL_MODAL_SCENE.instantiate()
	add_child(tutorial)
	tutorial.open(false, false, func() -> void:
		tutorial.queue_free()
	)

func _on_replay_intro_pressed() -> void:
	replay_intro_button.disabled = true
	await TransitionOverlay.fade_to_black()
	SceneManager.load_scene("intro")

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
