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

# ── Node References ────────────────────────────────────────────────────────────
@onready var ending_camera: Camera3D          = $EndingCamera
@onready var fade_overlay:  ColorRect         = $CanvasLayer/FadeOverlay
@onready var slide_label:   Label             = $CanvasLayer/SlideLabel
@onready var result_panel:  Control           = $CanvasLayer/ResultPanel

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
const RESULT_HOLD_DURATION: float = 7.0

var SLIDES: Array = []

func _ready() -> void:
	SLIDES = [
		{
			"need":            NeedsLog.Need.WINDOWS,
			"gamestate_flag":  "",
			"anchor":          anchor_windows,
			"visual_cue_path": "World3D/WindowArea/WindowTaskVisualCue",
			"label_done":      "Bintana — Nasakloban ✓",
			"label_skip":      "Bintana — Walang Proteksyon ✗",
		},
		{
			"need":            NeedsLog.Need.ROOF,
			"gamestate_flag":  "",
			"anchor":          anchor_roof,
			"visual_cue_path": "World3D/RoofArea/RoofTaskVisualCue",
			"label_done":      "Bubong — Napatakpan ✓",
			"label_skip":      "Bubong — Butas Pa Rin ✗",
		},
		{
			"need":            NeedsLog.Need.MEDICINE,
			"gamestate_flag":  "",
			"anchor":          anchor_medicine,
			"visual_cue_path": "World3D/BedroomArea/MedicineTaskVisualCue",
			"label_done":      "Gamot ni Lola — Nakuha ✓",
			"label_skip":      "Gamot ni Lola — Hindi Nakuha ✗",
		},
		{
			"need":            NeedsLog.Need.FOOD,
			"gamestate_flag":  "",
			"anchor":          anchor_food,
			"visual_cue_path": "World3D/KitchenArea/FoodTaskVisualCue",
			"label_done":      "Pagkain — Handa ✓",
			"label_skip":      "Pagkain — Kulang ✗",
		},
		{
			"need":            NeedsLog.Need.WATER,
			"gamestate_flag":  "",
			"anchor":          anchor_water,
			"visual_cue_path": "World3D/WaterArea/WaterTaskVisualCue",
			"label_done":      "Tubig — Napuno ✓",
			"label_skip":      "Tubig — Walang Reserba ✗",
		},
		{
			"need":            NeedsLog.Need.FLASHLIGHT,
			"gamestate_flag":  "",
			"anchor":          anchor_radio,
			"visual_cue_path": "World3D/RadioArea/RadioTaskVisualCue",
			"label_done":      "Radyo / Flashlight — Gumagana ✓",
			"label_skip":      "Radyo / Flashlight — Patay ✗",
		},
	]

	get_tree().paused = false
	GlobalTimer.pause_timer()

	# Hide ALL visual cues before anything fades in.
	_hide_all_visual_cues()

	fade_overlay.color     = Color(0, 0, 0, 1)
	slide_label.modulate.a = 0.0
	result_panel.hide()
	
	_start.call_deferred()


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
	print("Camera is current: ", ending_camera == get_viewport().get_camera_3d())
	print("Camera global pos: ", ending_camera.global_position)
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
		await _fade(0.0)

		# Cinematic camera move (skip on first beat — already snapped).
		if i > 0:
			await _move_camera_to(slide["anchor"])
		else:
			await get_tree().create_timer(0.15).timeout

		# Show the status label (non-blocking fade-in).
		_start_label(slide["label_done"] if is_done else slide["label_skip"], is_done)

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
	await _fade(0.0)
	result_panel.show()
	result_panel.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(result_panel, "modulate:a", 1.0, 0.8)
	await tween.finished
	await get_tree().create_timer(RESULT_HOLD_DURATION).timeout
	await _fade(1.0)
	GameState.reset()
	GlobalTimer.reset()
	NeedsLog.reset()
	EconomyManager.reset()
	InventoryManager.inventory.clear()
	SceneManager.load_scene("main_menu")

func _populate_result_panel() -> void:
	var title_lbl:  Label         = result_panel.get_node("VBoxContainer/TitleLabel")
	var sub_lbl:    Label         = result_panel.get_node("VBoxContainer/SubLabel")
	var item_list:  VBoxContainer = result_panel.get_node("VBoxContainer/ItemList")
	var footer_lbl: Label         = result_panel.get_node("VBoxContainer/FooterLabel")

	var completed_count: int = 0
	for slide in SLIDES:
		if _check_slide_done(slide):
			completed_count += 1

	title_lbl.text = "Dumating ang Bagyo."

	# match cannot use SLIDES.size() as a pattern (not a constant) — use if/elif.
	if completed_count == SLIDES.size():
		sub_lbl.text = "Nakaligtas kayong lahat."
		sub_lbl.add_theme_color_override("font_color", Color(0.55, 0.92, 0.60))
	elif completed_count >= 4:
		sub_lbl.text = "Nandito pa rin kayo. Sugatan, pero buhay."
		sub_lbl.add_theme_color_override("font_color", Color(0.95, 0.80, 0.45))
	elif completed_count >= 2:
		sub_lbl.text = "Mahirap ang gabi. Pero hindi kayo sumuko."
		sub_lbl.add_theme_color_override("font_color", Color(0.90, 0.65, 0.35))
	else:
		sub_lbl.text = "Hindi lahat ay naihanda. Hindi lahat ay napigilan."
		sub_lbl.add_theme_color_override("font_color", Color(0.90, 0.38, 0.38))

	for child in item_list.get_children():
		child.queue_free()

	for slide in SLIDES:
		var is_done: bool      = _check_slide_done(slide)
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		var icon: Label = Label.new()
		icon.custom_minimum_size   = Vector2(22, 0)
		icon.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
		icon.add_theme_font_size_override("font_size", 14)
		icon.text = "✓" if is_done else "✗"
		icon.add_theme_color_override("font_color",
				Color(0.55, 0.92, 0.60) if is_done else Color(0.90, 0.38, 0.38))
		row.add_child(icon)

		var lbl: Label = Label.new()
		lbl.text = slide["label_done"] if is_done else slide["label_skip"]
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color",
				Color(0.85, 0.92, 0.80) if is_done else Color(0.75, 0.62, 0.60))
		row.add_child(lbl)

		item_list.add_child(row)

	footer_lbl.text = (
		"Sa Pilipinas, humigit-kumulang 20 bagyo ang tumatalab bawat taon.\n"
		+ "Maraming pamilya ang haharapin ang bagyo nang walang sapat na tulong.\n"
		+ "Ang kahandaan ay hindi lamang responsibilidad ng bawat isa — ito ay karapatan."
	)
	footer_lbl.add_theme_color_override("font_color", Color(0.75, 0.72, 0.65))
	footer_lbl.add_theme_font_size_override("font_size", 10)
	footer_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
