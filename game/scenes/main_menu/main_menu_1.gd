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
@onready var start_button: Button = $VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/start_button
@onready var quit_button: Button = $VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/quit_button
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
const STORM_ACCENT: Color = Color(0.122, 0.486, 0.404)
const TITLE_TEXT: Color = Color(0.506, 0.776, 0.714)
const BUTTON_TEXT: Color = Color(0.886, 0.91, 0.941)
const BUTTON_MUTED: Color = Color(0.60, 0.68, 0.70)
const BUTTON_WIDTH: float = 244.0
const BUTTON_HEIGHT: float = 48.0
const DIFFICULTY_BUTTON_WIDTH: float = 280.0
const DIFFICULTY_BUTTON_HEIGHT: float = 56.0

var tutorial_button: Button
var replay_intro_button: Button
var settings_button: Button
var _settings_layer: CanvasLayer
var _settings_panel: AudioSettingsPanel
var _difficulty_layer: CanvasLayer
var _loading_layer: CanvasLayer
var _loading_label: Label
var _loading_tween: Tween
var _start_source_button: Button
var _lightning_active: bool = true
var _parallax_target: Vector2 = Vector2.ZERO
var _parallax_current: Vector2 = Vector2.ZERO
var _camera_base_position: Vector3
var _camera_base_rotation: Vector3

# MainMenu.gd
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_setup_left_gradient_overlay()
	_setup_lightning()
	_setup_settings_button()
	_setup_tutorial_button()
	_setup_replay_intro_button()
	_setup_settings_panel()
	_setup_difficulty_overlay()
	_setup_loading_layer()
	_setup_vignette_overlay()
	_reorder_menu_buttons()
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

func _setup_tutorial_button() -> void:
	tutorial_button = Button.new()
	tutorial_button.name = "tutorial_button"
	tutorial_button.text = "TUTORIAL"
	tutorial_button.pressed.connect(_on_tutorial_pressed)
	menu_buttons.add_child(tutorial_button)

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
	_settings_panel.custom_minimum_size = Vector2(620, 540)
	_settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	_settings_panel.offset_left = -310.0
	_settings_panel.offset_top = -270.0
	_settings_panel.offset_right = 310.0
	_settings_panel.offset_bottom = 270.0
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
	replay_intro_button.offset_left = 40.0
	replay_intro_button.offset_top = -88.0
	replay_intro_button.offset_right = 220.0
	replay_intro_button.offset_bottom = -46.0

func _setup_left_gradient_overlay() -> void:
	var overlay := TextureRect.new()
	overlay.name = "LeftGradientOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.stretch_mode = TextureRect.STRETCH_SCALE
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.0, 0.0, 0.0, 0.84))
	gradient.set_color(1, Color(0.0, 0.0, 0.0, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_LINEAR
	texture.fill_from = Vector2(0.0, 0.5)
	texture.fill_to = Vector2(0.72, 0.5)
	overlay.texture = texture
	add_child(overlay)
	move_child(overlay, 1)

func _setup_vignette_overlay() -> void:
	var viewport_container := get_node_or_null("SubViewportContainer") as SubViewportContainer
	if viewport_container == null:
		return
	var old_root_vignette := get_node_or_null("VignetteOverlay") as ColorRect
	if old_root_vignette != null:
		old_root_vignette.queue_free()
	var old_viewport_vignette := viewport_container.get_node_or_null("VignetteOverlay") as ColorRect
	if old_viewport_vignette != null:
		old_viewport_vignette.queue_free()
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float strength = 0.66;
uniform float radius = 0.44;
uniform float softness = 0.32;
void fragment() {
	vec2 centered = UV - vec2(0.5);
	centered.x *= 1.22;
	float dist = length(centered);
	float alpha = smoothstep(radius, radius + softness, dist) * strength;
	vec4 viewport_color = texture(TEXTURE, UV);
	COLOR = vec4(viewport_color.rgb * (1.0 - alpha), viewport_color.a);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	viewport_container.material = material

func _setup_difficulty_overlay() -> void:
	_difficulty_layer = CanvasLayer.new()
	_difficulty_layer.layer = 35
	_difficulty_layer.visible = false
	add_child(_difficulty_layer)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.68)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_difficulty_layer.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_difficulty_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 440)
	UI_STYLE.apply_panel(panel)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_bottom", 36)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	margin.add_child(box)

	var title := Label.new()
	title.text = "CHOOSE DIFFICULTY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UI_STYLE.FONT_SEMIBOLD)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", STORM_ACCENT)
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "The storm will not wait."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_override("font", UI_STYLE.FONT_REGULAR)
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", BUTTON_MUTED)
	box.add_child(subtitle)

	_add_difficulty_button(box, "STORY", GameState.Difficulty.STORY)
	_add_difficulty_button(box, "STANDARD", GameState.Difficulty.STANDARD)
	_add_difficulty_button(box, "CHALLENGE", GameState.Difficulty.CHALLENGE)

	var cancel := Button.new()
	cancel.text = "CANCEL"
	cancel.custom_minimum_size = Vector2(DIFFICULTY_BUTTON_WIDTH, 50)
	cancel.pressed.connect(_hide_difficulty_overlay)
	box.add_child(cancel)
	_apply_main_menu_button_style(cancel)
	cancel.add_theme_font_size_override("font_size", 24)

func _setup_loading_layer() -> void:
	_loading_layer = CanvasLayer.new()
	_loading_layer.layer = 80
	_loading_layer.visible = false
	add_child(_loading_layer)

	_loading_label = Label.new()
	_loading_label.text = "LOADING"
	_loading_label.modulate.a = 0.0
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_loading_label.add_theme_font_override("font", UI_STYLE.FONT_SEMIBOLD)
	_loading_label.add_theme_font_size_override("font_size", 22)
	_loading_label.add_theme_color_override("font_color", BUTTON_TEXT)
	_loading_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_loading_label.add_theme_constant_override("shadow_offset_x", 2)
	_loading_label.add_theme_constant_override("shadow_offset_y", 2)
	_loading_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_loading_label.offset_left = -210.0
	_loading_label.offset_top = -72.0
	_loading_label.offset_right = -36.0
	_loading_label.offset_bottom = -34.0
	_loading_layer.add_child(_loading_label)

func _show_loading_hint() -> void:
	_loading_layer.visible = true
	if _loading_tween != null and _loading_tween.is_valid():
		_loading_tween.kill()
	_loading_tween = create_tween()
	_loading_tween.set_loops()
	_loading_tween.tween_property(_loading_label, "modulate:a", 1.0, 0.42).set_ease(Tween.EASE_IN_OUT)
	_loading_tween.tween_property(_loading_label, "modulate:a", 0.24, 0.48).set_ease(Tween.EASE_IN_OUT)

func _add_difficulty_button(parent: VBoxContainer, label: String, difficulty: GameState.Difficulty) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(DIFFICULTY_BUTTON_WIDTH, DIFFICULTY_BUTTON_HEIGHT)
	button.pressed.connect(_on_difficulty_confirmed.bind(difficulty))
	parent.add_child(button)
	_apply_main_menu_button_style(button)
	button.add_theme_font_size_override("font_size", 24)

func _reorder_menu_buttons() -> void:
	var order: Array[Control] = [
		start_button,
		tutorial_button,
		leaderboards_button,
		settings_button,
		credits_button,
		quit_button,
	]
	for i in range(order.size()):
		menu_buttons.move_child(order[i], i + 1)

func _apply_menu_ui_style() -> void:
	for child in menu_buttons.get_children():
		if child is Button:
			_apply_main_menu_button_style(child)
			child.custom_minimum_size = Vector2(BUTTON_WIDTH, BUTTON_HEIGHT)

	_apply_main_menu_button_style(replay_intro_button)
	if title_label.label_settings != null:
		title_label.label_settings.font_color = TITLE_TEXT
		title_label.label_settings.outline_size = 5
		title_label.label_settings.outline_color = STORM_ACCENT
		title_label.label_settings.shadow_color = Color(0.0, 0.04, 0.035, 0.68)
	if subtitle_label.label_settings != null:
		subtitle_label.label_settings.font_color = TITLE_TEXT
		subtitle_label.label_settings.font_size = 30
		subtitle_label.label_settings.outline_size = 3
		subtitle_label.label_settings.outline_color = STORM_ACCENT
		subtitle_label.label_settings.shadow_color = Color(0.0, 0.04, 0.035, 0.68)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.custom_minimum_size = Vector2(420, 34)

func _apply_main_menu_button_style(button: Button) -> void:
	button.add_theme_font_override("font", UI_STYLE.FONT_SEMIBOLD)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", BUTTON_TEXT)
	button.add_theme_color_override("font_hover_color", BUTTON_TEXT)
	button.add_theme_color_override("font_pressed_color", BUTTON_TEXT)
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
		fill.color = Color(STORM_ACCENT.r, STORM_ACCENT.g, STORM_ACCENT.b, 0.22)
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

func request_start_game(source_button: Button) -> void:
	_start_source_button = source_button
	if _start_source_button != null:
		_start_source_button.disabled = true
	_difficulty_layer.visible = true

func _hide_difficulty_overlay() -> void:
	_difficulty_layer.visible = false
	if _start_source_button != null:
		_start_source_button.disabled = false

func _on_difficulty_confirmed(difficulty: GameState.Difficulty) -> void:
	_difficulty_layer.visible = false
	_show_loading_hint()
	AudioManager.stop_music(true)
	await TransitionOverlay.fade_to_black()
	await get_tree().create_timer(4.0).timeout
	SceneManager.reset()
	StormEnroachment.reset()
	NeedsLog.reset()
	ShopUi.reset()
	InventoryManager.reset()
	GameState.reset()
	GameState.set_difficulty(difficulty)
	SceneManager.load_scene("home")
	GlobalTimer.start_fresh()

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
