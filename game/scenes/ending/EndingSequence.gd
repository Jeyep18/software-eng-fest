# EndingSequence.gd
# Attach to the root node of res://game/scenes/ending/EndingSequence.tscn
#
# ── HOW VISUAL CUES WORK ──────────────────────────────────────────────────────
# Each beat has a "visual_cue_path" — the NodePath to a Node3D that holds the
# "task completed" version of the prop (planks on window, tarp on roof, etc.).
#
# Before each beat fades in, the script does:
#   visual_cue_node.visible = is_done
#
# So if the player DID the task → the cue is shown (planks visible).
# If the player SKIPPED it     → the cue is hidden (bare window, no tarp, etc.).
# All cue nodes start hidden by default — the script controls them entirely.
#
# ── HOW TO SET CAMERA ANGLES ─────────────────────────────────────────────────
# Each beat uses an anchor Node3D (e.g. $World3D/WindowArea).
# In the Godot editor:
#   1. Position your editor viewport camera exactly how you want the shot.
#   2. Select the anchor Node3D in the scene tree.
#   3. In the 3D viewport menu: Perspective → Align Transform with View.
#   4. The anchor now matches your editor camera — the script tweens to it.
# Repeat for each of the 6 anchors.
#
# ── SCENE TREE ────────────────────────────────────────────────────────────────
#   EndingSequence (Node)
#     ├── World3D  (Node3D)
#     │     ├── WindowArea      (Node3D) ← camera anchor
#     │     │     └── WindowTaskVisualCue   (Node3D) ← planks model
#     │     ├── RoofArea        (Node3D) ← camera anchor
#     │     │     └── RoofTaskVisualCue     (Node3D) ← tarp model
#     │     ├── BedroomArea     (Node3D) ← camera anchor
#     │     │     └── MedicineTaskVisualCue (Node3D) ← medicine model
#     │     ├── KitchenArea     (Node3D) ← camera anchor
#     │     │     └── FoodTaskVisualCue     (Node3D) ← canned goods model
#     │     ├── WaterArea       (Node3D) ← camera anchor
#     │     │     └── WaterTaskVisualCue    (Node3D) ← filled jugs model
#     │     └── RadioArea       (Node3D) ← camera anchor
#     │           └── RadioTaskVisualCue    (Node3D) ← radio/flashlight model
#     ├── EndingCamera (Camera3D)
#     ├── StormLight   (DirectionalLight3D)
#     ├── CanvasLayer  (layer = 10)
#     │     ├── FadeOverlay  (ColorRect — full rect, black)
#     │     ├── SlideLabel   (Label — centered)
#     │     └── ResultPanel  (PanelContainer — hidden at start)
#     │           └── VBoxContainer
#     │                 ├── TitleLabel  (Label)
#     │                 ├── SubLabel    (Label)
#     │                 ├── HSeparator
#     │                 ├── ItemList    (VBoxContainer)
#     │                 ├── HSeparator
#     │                 └── FooterLabel (Label)
#     └── AudioStreamPlayer

extends Node

const UI_STYLE = preload("res://game/ui/GameUIStyle.gd")
const SFX = preload("res://game/audio/Sfx.gd")
const ENDING_STORM: AudioStream = preload("res://game/assets/sfx/soundreality-rain-thunder-sfx-525011.mp3")

# ── Node References ────────────────────────────────────────────────────────────
@onready var ending_camera: Camera3D          = $EndingCamera
@onready var fade_overlay:  ColorRect         = $CanvasLayer/FadeOverlay
@onready var slide_label:   Label             = $CanvasLayer/VBoxContainer/SlideLabel
@onready var result_panel:  Control           = $CanvasLayer/ResultPanel
@onready var lightning:     SpotLight3D       = $Lights/Lightning

@onready var anchor_windows:  Node3D = $World3D/WindowArea
@onready var anchor_roof:     Node3D = $World3D/RoofArea
@onready var anchor_medicine: Node3D = $World3D/BedroomArea
@onready var anchor_food:     Node3D = $World3D/KitchenArea
@onready var anchor_water:    Node3D = $World3D/WaterArea
@onready var anchor_radio:    Node3D = $World3D/RadioArea

# ── Timing ─────────────────────────────────────────────────────────────────────
const FADE_DURATION:        float = 0.65
const CAMERA_MOVE_DURATION: float = 1.4
const SLIDE_HOLD_DURATION:  float = 2.6
const LABEL_FADE_IN:        float = 0.35
const LABEL_FADE_OUT:       float = 0.35
const RESULT_HOLD_DURATION: float = 12.0
const RESULT_TITLE_DELAY: float = 0.6
const RESULT_SUBTITLE_DELAY: float = 2.0
const RESULT_BODY_DELAY: float = 3.6
const RESULT_CREDIT_DELAY: float = 7.2
const RESULT_TEXT_FADE_IN: float = 1.8
const LIGHTNING_MIN_DELAY: float = 3.5
const LIGHTNING_MAX_DELAY: float = 8.5
const LIGHTNING_FLASH_ENERGY: float = 18.0
const LIGHTNING_FLASH_DURATION: float = 0.08
const LIGHTNING_DOUBLE_FLASH_CHANCE: float = 0.45
const LIGHTNING_DOUBLE_FLASH_DELAY: float = 0.12
const WIND_GUST_MIN_INTERVAL: float = 8.0
const WIND_GUST_CHANCE_DONE: float = 0.12
const WIND_GUST_CHANCE_FAILED: float = 0.28

var SLIDES: Array = []
var _leaderboard_score_saved: bool = false
var _lightning_active: bool = true
var _next_wind_gust_time: float = 0.0
var _credit_label: Label = null

func _ready() -> void:
	AudioManager.play_ambience(ENDING_STORM)
	AudioManager.play_music(preload("res://game/assets/sfx/samuelfjohanns-extreme-sad-cinema-12299-SamuelFJohannsPixabay.mp3"))
	SLIDES = [
		{
			"need":            NeedsLog.Need.WINDOWS,
			"gamestate_flag":  "",
			"anchor":          anchor_windows,
			"visual_cue_path": "World3D/WindowArea/WindowTaskVisualCue",
			"label_done":      "Matatag ang harang sa bintana, naligtas kami sa malalakas na hangin.",
			"label_skip":      "Hindi natakpan ang dalawang bintana, kaya pinasok ng hangin at ulan ang bahay.",
		},
		{
			"need":            NeedsLog.Need.ROOF,
			"gamestate_flag":  "",
			"anchor":          anchor_roof,
			"visual_cue_path": "World3D/RoofArea/RoofTaskVisualCue",
			"label_done":      "Natakpan ang bubong sa oras, tuyo ang sahig at sala.",
			"label_skip":      "Hindi natakpan ang bubong, nabasa ang loob ng bahay.",
		},
		{
			"need":            NeedsLog.Need.MEDICINE,
			"gamestate_flag":  "",
			"anchor":          anchor_medicine,
			"visual_cue_path": "World3D/BedroomArea/MedicineTaskVisualCue",
			"label_done":      "Mahimbing ang tulog ni Lola, sapat ang kanyang gamot.",
			"label_skip":      "Hirap huminga si Lola, wala kaming naibigay na lunas.",
		},
		{
			"need":            NeedsLog.Need.FOOD,
			"gamestate_flag":  "",
			"anchor":          anchor_food,
			"visual_cue_path": "World3D/KitchenArea/FoodTaskVisualCue",
			"label_done":      "May laman ang aming sikmura, may lakas kaming lumaban.",
			"label_skip":      "Wala kaming nakain sa dumating na bagyo.",
		},
		{
			"need":            NeedsLog.Need.WATER,
			"gamestate_flag":  "",
			"anchor":          anchor_water,
			"visual_cue_path": "World3D/WaterArea/WaterTaskVisualCue",
			"label_done":      "May malinis kaming maiinom, ligtas kami sa uhaw.",
			"label_skip":      "Tuyo ang lalamunan, madumi ang tubig sa paligid.",
		},
		{
			"need":            NeedsLog.Need.FLASHLIGHT,
			"gamestate_flag":  "",
			"anchor":          anchor_radio,
			"visual_cue_path": "World3D/RadioArea/RadioTaskVisualCue",
			"label_done":      "May liwanag at balita, alam namin ang nangyayari.",
			"label_skip":      "Nabalot kami ng dilim, bingi kami sa labas ng mundo.",
		},
	]

	get_tree().paused = false
	GlobalTimer.pause_timer()

	# Hide ALL visual cues before anything fades in.
	_hide_all_visual_cues()

	fade_overlay.color     = Color(0, 0, 0, 1)
	slide_label.modulate.a = 0.0
	lightning.visible = false
	lightning.light_energy = 0.0
	_apply_result_ui_style()
	result_panel.hide()
	
	_run_lightning_loop()
	_start.call_deferred()

func _exit_tree() -> void:
	_lightning_active = false


# ── Deferred Start ────────────────────────────────────────────────────────────
# Called via call_deferred from _ready() so that all nodes are fully inside
# the scene tree and global_transform assignments actually take effect.
func _start() -> void:
	# Now that we are in the tree, make the camera current.
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	TransitionOverlay.fade_from_black()
	
	var active_cam: Camera3D = get_viewport().get_camera_3d()
	if active_cam != null and active_cam != ending_camera:
		push_warning("EndingSequence: demoting leftover camera: " + active_cam.name)
		active_cam.current = false
		
	ending_camera.make_current()

	# Snap to the first anchor — global_transform is valid here.
	_snap_camera_to(SLIDES[0]["anchor"])
	_run_sequence()


# ── Main Sequence ──────────────────────────────────────────────────────────────
func _run_sequence() -> void:
	await get_tree().create_timer(0.3).timeout

	for i in range(SLIDES.size()):
		var slide:   Dictionary = SLIDES[i]
		var is_done: bool       = _check_slide_done(slide)

		# Toggle the visual cue WHILE the screen is still black.
		# The player never sees a pop — the prop is just there when revealed.
		_apply_visual_cue(slide, is_done)

		# Reveal the room.
		_play_slide_sfx(slide, is_done)
		await _fade(0.0)

		# Cinematic camera move (skip on first beat — already snapped).
		if i > 0:
			await _move_camera_to(slide["anchor"])
		else:
			await get_tree().create_timer(0.15).timeout

		# Show the status label (non-blocking fade-in).
		_start_label(LocalizationManager.translate(slide["label_done"] if is_done else slide["label_skip"]), is_done)
		if not is_done:
			_flash_lightning(14.0, 0.12)
		elif randf() < 0.35:
			_flash_lightning(8.0, 0.09)

		# Hold on the room.
		await get_tree().create_timer(SLIDE_HOLD_DURATION).timeout

		# Fade label out, then fade room to black.
		await _fade_out_label()
		await _fade(1.0)

		# Snap to next anchor while black.
		if i + 1 < SLIDES.size():
			_snap_camera_to(SLIDES[i + 1]["anchor"])

		await get_tree().create_timer(0.15).timeout

	await _show_result_panel()


# ── Visual Cue System ──────────────────────────────────────────────────────────
func _hide_all_visual_cues() -> void:
	for slide in SLIDES:
		var path: String = slide.get("visual_cue_path", "")
		if path == "":
			continue
		var node: Node3D = get_node_or_null(path)
		if node:
			node.visible = false
		else:
			push_warning("EndingSequence: visual_cue_path not found: " + path)

func _apply_visual_cue(slide: Dictionary, is_done: bool) -> void:
	var path: String = slide.get("visual_cue_path", "")
	if path == "":
		return
	var node: Node3D = get_node_or_null(path)
	if node == null:
		push_warning("EndingSequence: visual_cue_path not found: " + path)
		return
	# Done   → show the completed prop (planks, tarp, medicine, etc.)
	# Skipped → hide it (bare window, hole in ceiling, empty shelf, etc.)
	node.visible = is_done


# ── Slide State Check ──────────────────────────────────────────────────────────
func _check_slide_done(slide: Dictionary) -> bool:
	var flag: String = slide.get("gamestate_flag", "")
	if flag != "":
		return GameState.get(flag) == true
	var need = slide.get("need")
	if need != null:
		return NeedsLog.is_resolved(need)
	return false


# ── Camera ─────────────────────────────────────────────────────────────────────
func _snap_camera_to(anchor: Node3D) -> void:
	ending_camera.global_transform = anchor.global_transform

func _move_camera_to(anchor: Node3D) -> void:
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(ending_camera, "global_transform",
			anchor.global_transform, CAMERA_MOVE_DURATION)
	await tween.finished


# ── Fade ───────────────────────────────────────────────────────────────────────
func _fade(target_alpha: float) -> void:
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade_overlay, "color:a", target_alpha, FADE_DURATION)
	await tween.finished


# ── Label ──────────────────────────────────────────────────────────────────────
func _start_label(text: String, is_done: bool) -> void:
	slide_label.text = text
	slide_label.add_theme_color_override("font_color",
			Color(0.55, 0.92, 0.60) if is_done else Color(0.92, 0.38, 0.38))
	slide_label.modulate.a = 0.0
	var t: Tween = create_tween()
	t.tween_property(slide_label, "modulate:a", 1.0, LABEL_FADE_IN)

func _fade_out_label() -> void:
	if slide_label.modulate.a <= 0.0:
		return
	var t: Tween = create_tween()
	t.tween_property(slide_label, "modulate:a", 0.0, LABEL_FADE_OUT)
	await t.finished


# ── Result Panel ───────────────────────────────────────────────────────────────
func _show_result_panel() -> void:
	_populate_result_panel()
	fade_overlay.color.a = 1.0
	result_panel.show()
	result_panel.modulate.a = 1.0
	await _reveal_result_message()
	var music_remaining := AudioManager.get_music_time_remaining()
	var final_hold := RESULT_HOLD_DURATION if music_remaining < 0.0 else maxf(music_remaining - FADE_DURATION, 0.0)
	await get_tree().create_timer(final_hold).timeout
	await _fade(1.0)
	result_panel.hide()
	await _submit_leaderboard_score()
	SceneManager.reset()
	StormEnroachment.reset()
	GameState.reset()
	GlobalTimer.reset()
	NeedsLog.reset()
	EconomyManager.reset()
	InventoryManager.reset()
	await TransitionOverlay.fade_to_black()
	SceneManager.load_scene("main_menu")

func _submit_leaderboard_score() -> void:
	if _leaderboard_score_saved:
		return

	var tasks_completed: int = NeedsLog.get_all_resolved().size()
	var remaining_minutes: int = LeaderboardManager.consume_remaining_time_snapshot()
	var prompt_layer := _create_leaderboard_prompt(tasks_completed, remaining_minutes)
	var name_input: LineEdit = prompt_layer.get_node("Panel/MarginContainer/VBoxContainer/NameInput")
	var submit_button: Button = prompt_layer.get_node("Panel/MarginContainer/VBoxContainer/ButtonRow/SubmitButton")

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	name_input.text_changed.connect(func(new_text: String) -> void:
		submit_button.disabled = new_text.strip_edges().is_empty()
	)
	name_input.text_submitted.connect(func(_new_text: String) -> void:
		if not submit_button.disabled:
			submit_button.pressed.emit()
	)

	add_child(prompt_layer)
	name_input.call_deferred("grab_focus")
	await submit_button.pressed

	var player_name: String = name_input.text.strip_edges()
	if player_name.is_empty():
		player_name = "Player"

	LeaderboardManager.record_run(player_name, tasks_completed, remaining_minutes, GameState.get_difficulty_id())
	SFX.ui_click()
	_leaderboard_score_saved = true
	prompt_layer.queue_free()

func _create_leaderboard_prompt(tasks_completed: int, remaining_minutes: int) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.name = "LeaderboardNamePrompt"
	layer.layer = 50

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(520, 260)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -260
	panel.offset_top = -130
	panel.offset_right = 260
	panel.offset_bottom = 130
	layer.add_child(panel)
	UI_STYLE.apply_panel(panel)

	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.name = "VBoxContainer"
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var title := Label.new()
	title.text = LocalizationManager.translate("SAVE YOUR RUN")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)
	UI_STYLE.apply_label(title, false, true)

	var summary := Label.new()
	summary.text = LocalizationManager.trf("Mode: %s    Tasks: %d / %d    Time left: %s", [
		GameState.get_difficulty_label(),
		tasks_completed,
		NeedsLog.Need.size(),
		_format_minutes(remaining_minutes),
	])
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_theme_font_size_override("font_size", 18)
	box.add_child(summary)
	UI_STYLE.apply_label(summary, true)

	var name_input := LineEdit.new()
	name_input.name = "NameInput"
	name_input.placeholder_text = LocalizationManager.translate("Enter player name")
	name_input.max_length = 24
	name_input.custom_minimum_size = Vector2(0, 42)
	name_input.add_theme_color_override("font_color", UI_STYLE.TEXT)
	name_input.add_theme_color_override("font_placeholder_color", UI_STYLE.TEXT_MUTED)
	name_input.add_theme_stylebox_override("normal", UI_STYLE.button_style(Color(0.08, 0.09, 0.10, 0.95)))
	name_input.add_theme_stylebox_override("focus", UI_STYLE.button_style(Color(0.10, 0.11, 0.12, 0.98), UI_STYLE.BORDER))
	box.add_child(name_input)

	var button_row := HBoxContainer.new()
	button_row.name = "ButtonRow"
	button_row.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(button_row)

	var submit_button := Button.new()
	submit_button.name = "SubmitButton"
	submit_button.text = "SAVE"
	submit_button.disabled = true
	submit_button.custom_minimum_size = Vector2(130, 42)
	button_row.add_child(submit_button)
	UI_STYLE.apply_button(submit_button)

	return layer

func _format_minutes(minutes: int) -> String:
	var safe_minutes: int = max(minutes, 0)
	var hours: int = safe_minutes / 60
	var mins: int = safe_minutes % 60
	return "%dh %02dm" % [hours, mins]

func _populate_result_panel() -> void:
	var title_lbl:  Label         = result_panel.get_node("VBoxContainer/TitleLabel")
	var sub_lbl:    Label         = result_panel.get_node("VBoxContainer/SubLabel")
	var item_list:  VBoxContainer = result_panel.get_node("VBoxContainer/ItemList")
	var footer_lbl: Label         = result_panel.get_node("VBoxContainer/FooterLabel")
	var box := result_panel.get_node("VBoxContainer") as VBoxContainer

	var final_completed_count: int = 0
	for slide in SLIDES:
		if _check_slide_done(slide):
			final_completed_count += 1

	title_lbl.text = LocalizationManager.translate("Dumating ang Bagyo.")
	title_lbl.modulate.a = 0.0

	if final_completed_count == SLIDES.size():
		sub_lbl.text = LocalizationManager.translate("Nakaligtas kami lahat.")
		sub_lbl.add_theme_color_override("font_color", Color(0.70, 0.86, 0.68))
	elif final_completed_count >= 4:
		sub_lbl.text = LocalizationManager.translate("Nandito pa rin kami. Sugatan, pero buhay.")
		sub_lbl.add_theme_color_override("font_color", Color(0.86, 0.74, 0.52))
	elif final_completed_count >= 2:
		sub_lbl.text = LocalizationManager.translate("Mahirap ang gabi. Pero hindi kami sumuko.")
		sub_lbl.add_theme_color_override("font_color", Color(0.82, 0.66, 0.48))
	else:
		sub_lbl.text = LocalizationManager.translate("Hindi lahat ay naihanda. Hindi lahat ay napigilan.")
		sub_lbl.add_theme_color_override("font_color", Color(0.82, 0.44, 0.42))
	sub_lbl.modulate.a = 0.0

	for child in item_list.get_children():
		child.queue_free()
	item_list.hide()

	footer_lbl.text = (
		LocalizationManager.translate("Every year, an average of 20 typhoons test our resilience. But while \"flood control projects\" remain sturdy only on paper and political tarpaulins, ordinary citizens are left to swim for their lives.")
		+ "\n\n"
		+ LocalizationManager.translate("Safety is not a privilege to be earned. It is a basic accountability of those in power.")
	)
	footer_lbl.modulate.a = 0
	footer_lbl.add_theme_font_override("font", UI_STYLE.FONT_REGULAR)
	footer_lbl.add_theme_color_override("font_color", Color(0.82, 0.80, 0.72))
	footer_lbl.add_theme_font_size_override("font_size", 28)
	footer_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer_lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	footer_lbl.custom_minimum_size = Vector2(720, 0)
	footer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	footer_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	if _credit_label == null:
		_credit_label = Label.new()
		_credit_label.name = "CreditLabel"
		_credit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_credit_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(_credit_label)

	_credit_label.text = "3 Netherite Ingots - Ateneo de Naga University Software Festival 2026"
	_credit_label.modulate.a = 0.0
	_credit_label.add_theme_font_override("font", UI_STYLE.FONT_REGULAR)
	_credit_label.add_theme_font_size_override("font_size", 20)
	_credit_label.add_theme_color_override("font_color", Color(0.58, 0.58, 0.53))

func _apply_result_ui_style() -> void:
	UI_STYLE.apply_tree(result_panel)
	result_panel.custom_minimum_size = Vector2(760, 470)
	result_panel.set_anchors_preset(Control.PRESET_CENTER)
	result_panel.offset_left = -380.0
	result_panel.offset_top = -235.0
	result_panel.offset_right = 380.0
	result_panel.offset_bottom = 235.0
	result_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	var box := result_panel.get_node("VBoxContainer") as VBoxContainer
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)

	var title_lbl := result_panel.get_node("VBoxContainer/TitleLabel") as Label
	title_lbl.add_theme_font_override("font", UI_STYLE.FONT_SEMIBOLD)
	title_lbl.add_theme_font_size_override("font_size", 34)
	title_lbl.add_theme_color_override("font_color", Color(0.94, 0.94, 0.90))

	var sub_lbl := result_panel.get_node("VBoxContainer/SubLabel") as Label
	sub_lbl.add_theme_font_override("font", UI_STYLE.FONT_SEMIBOLD)
	sub_lbl.add_theme_font_size_override("font_size", 20)

	var item_list := result_panel.get_node("VBoxContainer/ItemList") as VBoxContainer
	item_list.add_theme_constant_override("separation", 8)
	item_list.hide()

	var separator := result_panel.get_node_or_null("VBoxContainer/HSeparator") as HSeparator
	if separator != null:
		separator.hide()

	var separator_2 := result_panel.get_node_or_null("VBoxContainer/HSeparator2") as HSeparator
	if separator_2 != null:
		separator_2.hide()

	var footer_lbl := result_panel.get_node("VBoxContainer/FooterLabel") as Label
	footer_lbl.custom_minimum_size = Vector2(720, 250)
	footer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	footer_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slide_label.add_theme_font_override("font", UI_STYLE.FONT_SEMIBOLD)
	slide_label.add_theme_font_size_override("font_size", 26)
	slide_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _reveal_result_message() -> void:
	var title_lbl := result_panel.get_node("VBoxContainer/TitleLabel") as Label
	var sub_lbl := result_panel.get_node("VBoxContainer/SubLabel") as Label
	var footer_lbl := result_panel.get_node("VBoxContainer/FooterLabel") as Label

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(title_lbl, "modulate:a", 1.0, RESULT_TEXT_FADE_IN).set_delay(RESULT_TITLE_DELAY)
	tween.tween_property(sub_lbl, "modulate:a", 1.0, RESULT_TEXT_FADE_IN).set_delay(RESULT_SUBTITLE_DELAY)
	tween.tween_property(footer_lbl, "modulate:a", 1.0, RESULT_TEXT_FADE_IN).set_delay(RESULT_BODY_DELAY)
	if _credit_label != null:
		tween.tween_property(_credit_label, "modulate:a", 0.58, RESULT_TEXT_FADE_IN).set_delay(RESULT_CREDIT_DELAY)
	await tween.finished

func _play_slide_sfx(_slide: Dictionary, is_done: bool) -> void:
	_try_play_wind_gust(is_done)
	if not is_done:
		SFX.thunder_close(-11.0)

func _try_play_wind_gust(is_done: bool) -> void:
	var now := float(Time.get_ticks_msec()) / 1000.0
	if now < _next_wind_gust_time:
		return

	var chance := WIND_GUST_CHANCE_DONE if is_done else WIND_GUST_CHANCE_FAILED
	if randf() > chance:
		return

	_next_wind_gust_time = now + WIND_GUST_MIN_INTERVAL
	SFX.wind_gust(-21.0)

func _flash_lightning(energy: float = 6.0, duration: float = 0.14) -> void:
	if lightning == null:
		return
	lightning.visible = true
	lightning.light_energy = energy
	lightning.light_indirect_energy = energy * 0.65
	lightning.light_volumetric_fog_energy = energy * 0.4
	var tween := create_tween()
	tween.tween_property(lightning, "light_energy", 0.0, duration)
	tween.parallel().tween_property(lightning, "light_indirect_energy", 0.0, duration)
	tween.parallel().tween_property(lightning, "light_volumetric_fog_energy", 0.0, duration)
	tween.finished.connect(func() -> void:
		if lightning != null:
			lightning.visible = false
	)

func _run_lightning_loop() -> void:
	while _lightning_active:
		await get_tree().create_timer(randf_range(LIGHTNING_MIN_DELAY, LIGHTNING_MAX_DELAY)).timeout
		if not _lightning_active:
			return
		_flash_lightning(LIGHTNING_FLASH_ENERGY, LIGHTNING_FLASH_DURATION)
		if randf() <= LIGHTNING_DOUBLE_FLASH_CHANCE:
			await get_tree().create_timer(LIGHTNING_DOUBLE_FLASH_DELAY).timeout
			if not _lightning_active:
				return
			_flash_lightning(LIGHTNING_FLASH_ENERGY * 0.65, LIGHTNING_FLASH_DURATION * 0.85)
