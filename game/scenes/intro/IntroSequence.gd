# IntroSequence.gd
# Attach to: the root CanvasLayer node of IntroSequence.tscn
# Location:  res://game/scenes/intro/IntroSequence.gd

extends CanvasLayer

# ── Node References ────────────────────────────────────────────────────────────
@onready var background: ColorRect = $Background
@onready var line_label: Label     = $Background/LineLabel
@onready var skip_hint:  Label     = $Background/SkipHint

const UI_STYLE = preload("res://game/ui/GameUIStyle.gd")

# ── State ──────────────────────────────────────────────────────────────────────
var _skipped: bool = false
var _skip_enabled: bool = false
var _studio_kicker: Label
var _studio_label: Label

const CONTENT_WARNING: String = "CONTENT WARNING\n\nBagyong Bahay contains themes of natural disasters, systemic poverty, and government neglect.\n\nCertain endings lead to heavy, grief-driven outcomes."
const DEDICATION: String = "This game is dedicated to every Filipino family that has had to brave the storm with far too little."

# ── Line Data ──────────────────────────────────────────────────────────────────
# Pacing logic:
#   - "pause" beats create breathing room. Use them generously.
#   - The sequence moves in four emotional blocks:
#       1. Ordinary morning   — slow, warm, specific
#       2. The bulletin       — short, clinical, abrupt
#       3. The house          — grounded, no drama, just facts
#       4. The handoff        — quiet pressure, then silence
#
# Resist the urge to explain. Let the details do the work.
#
const LINES: Array = [

	# ── Block 1: Ordinary Morning ──────────────────────────────────────────────
	# Opens warm. Taglish sets the register immediately.
	# The family is introduced through texture, not description.

	{ "text": "Garlic rice on the table. Coffee cooling beside it. The kitchen radio humming through static.", "hold": 3.2, "fade": 0.9, "style": "italic" },
	{ "text": "", "hold": 0.9, "fade": 0.0, "style": "pause" },
	{ "text": "Then the rain stayed long enough to become a warning.", "hold": 3.0, "fade": 0.9, "style": "normal" },
	{ "text": "", "hold": 0.9, "fade": 0.0, "style": "pause" },
	{ "text": "They said the flood barriers were repaired.", "hold": 2.7, "fade": 0.8, "style": "normal" },
	{ "text": "So why is the water already touching the door?", "hold": 2.9, "fade": 0.9, "style": "large" },
	{ "text": "", "hold": 0.9, "fade": 0.0, "style": "pause" },

	# ── Block 2: The Bulletin ──────────────────────────────────────────────────
	# Short. Clinical. The rhythm breaks on purpose here.
	# No adjectives. Just the numbers.

	{ "text": "Somewhere in the Philippines, a family begins counting the hours by what they can still save.", "hold": 3.7, "fade": 1.0, "style": "large" },
	{ "text": "", "hold": 1.0, "fade": 0.0, "style": "pause" },
	{ "text": "Signal No. 4.", "hold": 2.4, "fade": 0.8, "style": "normal" },
	{ "text": "Landfall in exactly 12 hours.", "hold": 3.2, "fade": 0.9, "style": "large" },
	{ "text": "", "hold": 1.1, "fade": 0.0, "style": "pause" },
	{ "text": "Do what you can with what you have left.", "hold": 3.6, "fade": 1.1, "style": "normal" },

	# ── Trailing silence before scene transition ───────────────────────────────
	{ "text": "", "hold": 0.7, "fade": 0.0, "style": "pause" },
	{ "text": "", "hold": 0.7, "fade": 0.0, "style": "pause" },
]

# ── Ready ──────────────────────────────────────────────────────────────────────
func _ready() -> void:
	AudioManager.stop_music(false)
	AudioManager.stop_ambience(false)
	_setup_font_overrides()
	_setup_studio_splash()
	line_label.modulate.a = 0.0
	skip_hint.modulate.a  = 0.0
	line_label.text       = ""
	_run_sequence()

# ── Input — Skip on any key or mouse click ────────────────────────────────────
func _input(event: InputEvent) -> void:
	if _skipped or not _skip_enabled:
		return
	if event.is_action_pressed("ui_accept") \
	or event.is_action_pressed("ui_cancel") \
	or (event is InputEventMouseButton and event.pressed):
		_skipped = true

# ── Main Sequence Coroutine ────────────────────────────────────────────────────
func _run_sequence() -> void:
	await _run_studio_splash()
	if _skipped:
		await _end_sequence()
		return

	await _show_card("Made with Godot 4", "credit", 1.8, 0.8)
	if _skipped:
		await _end_sequence()
		return

	await _show_card(CONTENT_WARNING, "warning", 4.0, 0.8)
	if _skipped:
		await _end_sequence()
		return

	await _show_card(DEDICATION, "warning", 3.0, 0.8)
	if _skipped:
		await _end_sequence()
		return

	_skip_enabled = true
	AudioManager.play_ambience(preload("res://game/assets/sfx/freesound_community-morning-birds-30911-FreeSoundCommunityPixabay.mp3"))
	AudioManager.play_music(preload("res://game/assets/sfx/samuelfjohanns-extreme-sad-cinema-12299-SamuelFJohannsPixabay.mp3"))
	await _wait_or_skip(0.8)
	_fade_node(skip_hint, 1.0, 1.2)

	for line_data in LINES:
		if _skipped:
			break

		if line_data["style"] == "pause":
			await _wait_or_skip(line_data["hold"])
			continue

		_apply_style(line_data["style"])
		line_label.text = line_data["text"]

		await _fade_label_in(0.6)
		await _wait_or_skip(line_data["hold"])

		if not _skipped:
			await _fade_label_out(line_data["fade"])

		await _wait_or_skip(0.25)

	await _end_sequence()

# ── End: Fade to black and load main menu ────────────────────────────────────
func _end_sequence() -> void:
	line_label.text       = ""
	line_label.modulate.a = 0.0
	skip_hint.modulate.a  = 0.0
	if _studio_kicker != null:
		_studio_kicker.modulate.a = 0.0
	if _studio_label != null:
		_studio_label.modulate.a = 0.0

	await _wait_or_skip(0.6)
	await TransitionOverlay.fade_to_black()
	SceneManager.load_scene("main_menu")

func _show_card(text: String, style: String, hold: float, fade: float) -> void:
	_apply_style(style)
	line_label.text = text
	await _fade_label_in(0.8)
	await _wait_for_duration(hold)
	await _fade_label_out(fade)
	await _wait_for_duration(0.3)

func _wait_or_skip(duration: float) -> void:
	var remaining := duration
	while remaining > 0.0 and not _skipped:
		var step := minf(remaining, 0.05)
		await get_tree().create_timer(step).timeout
		remaining -= step

func _wait_for_duration(duration: float) -> void:
	var remaining := duration
	while remaining > 0.0:
		var step := minf(remaining, 0.05)
		await get_tree().create_timer(step).timeout
		remaining -= step

# ── Style Application ─────────────────────────────────────────────────────────
func _apply_style(style: String) -> void:
	match style:
		"normal":
			line_label.add_theme_font_override("font", UI_STYLE.FONT_REGULAR)
			line_label.add_theme_font_size_override("font_size", 35)
			line_label.add_theme_color_override("font_color", Color.WHITE)
		"large":
			line_label.add_theme_font_override("font", UI_STYLE.FONT_SEMIBOLD)
			line_label.add_theme_font_size_override("font_size", 35)
			line_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		"credit":
			line_label.add_theme_font_override("font", UI_STYLE.FONT_SEMIBOLD)
			line_label.add_theme_font_size_override("font_size", 42)
			line_label.add_theme_color_override("font_color", Color.WHITE)
		"warning":
			line_label.add_theme_font_override("font", UI_STYLE.FONT_REGULAR)
			line_label.add_theme_font_size_override("font_size", 28)
			line_label.add_theme_color_override("font_color", Color.WHITE)
		"small":
			line_label.add_theme_font_override("font", UI_STYLE.FONT_REGULAR)
			line_label.add_theme_font_size_override("font_size", 35)
			line_label.add_theme_color_override("font_color", Color(0.53, 0.53, 0.50))
		"italic":
			line_label.add_theme_font_override("font", UI_STYLE.FONT_REGULAR)
			line_label.add_theme_font_size_override("font_size", 35)
			line_label.add_theme_color_override("font_color", Color.WHITE)
			# Assign an italic font variant via LabelSettings in the Inspector
			# for this style to render correctly.

# ── Tween Helpers ─────────────────────────────────────────────────────────────
func _setup_font_overrides() -> void:
	line_label.add_theme_font_override("font", UI_STYLE.FONT_REGULAR)
	line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skip_hint.add_theme_font_override("font", UI_STYLE.FONT_REGULAR)

func _setup_studio_splash() -> void:
	_studio_kicker = Label.new()
	_studio_kicker.name = "StudioSplashKicker"
	_studio_kicker.text = "developed by"
	_studio_kicker.modulate = Color(1, 1, 1, 0)
	_studio_kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_studio_kicker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_studio_kicker.add_theme_font_override("font", UI_STYLE.FONT_REGULAR)
	_studio_kicker.add_theme_font_size_override("font_size", 20)
	_studio_kicker.add_theme_color_override("font_color", Color.WHITE)
	_studio_kicker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_studio_kicker.offset_top = -74.0
	_studio_kicker.offset_bottom = -74.0
	background.add_child(_studio_kicker)

	_studio_label = Label.new()
	_studio_label.name = "StudioSplashLabel"
	_studio_label.text = "3 Netherite Ingots"
	_studio_label.modulate = Color(1, 1, 1, 0)
	_studio_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_studio_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_studio_label.add_theme_font_override("font", UI_STYLE.FONT_SEMIBOLD)
	_studio_label.add_theme_font_size_override("font_size", 54)
	_studio_label.add_theme_color_override("font_color", Color.WHITE)
	_studio_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.add_child(_studio_label)

func _run_studio_splash() -> void:
	await _wait_for_duration(0.5)

	var intro_tween := create_tween()
	intro_tween.set_parallel(true)
	intro_tween.set_trans(Tween.TRANS_CUBIC)
	intro_tween.set_ease(Tween.EASE_OUT)
	intro_tween.tween_property(_studio_kicker, "modulate:a", 1.0, 0.9)
	intro_tween.tween_property(_studio_label, "modulate:a", 1.0, 1.0)
	await intro_tween.finished

	await _wait_for_duration(2.4)
	var outro_tween := create_tween()
	outro_tween.set_parallel(true)
	outro_tween.set_trans(Tween.TRANS_CUBIC)
	outro_tween.set_ease(Tween.EASE_IN)
	outro_tween.tween_property(_studio_kicker, "modulate:a", 0.0, 0.8)
	outro_tween.tween_property(_studio_label, "modulate:a", 0.0, 0.8)
	await outro_tween.finished

func _fade_label_in(duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(line_label, "modulate:a", 1.0, duration) \
		 .set_ease(Tween.EASE_OUT)
	await tween.finished

func _fade_label_out(duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(line_label, "modulate:a", 0.0, duration) \
		 .set_ease(Tween.EASE_IN)
	await tween.finished

func _fade_node(node: Control, target_alpha: float, duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(node, "modulate:a", target_alpha, duration) \
		 .set_ease(Tween.EASE_OUT)
