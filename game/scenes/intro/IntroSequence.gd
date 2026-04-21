# IntroSequence.gd
# Attach to: the root CanvasLayer node of IntroSequence.tscn
# Location:  res://game/scenes/intro/IntroSequence.gd

extends CanvasLayer

# ── Node References ────────────────────────────────────────────────────────────
# These names must match EXACTLY what you named the nodes in Step 2.
@onready var background:  ColorRect = $Background
@onready var line_label:  Label     = $Background/LineLabel
@onready var skip_hint:   Label     = $Background/SkipHint

# ── State ──────────────────────────────────────────────────────────────────────
var _skipped: bool = false

# ── Line Data ──────────────────────────────────────────────────────────────────
# Each dictionary is one beat in the sequence.
#
# Keys:
#   "text"  — the string displayed. Empty string = silent pause (no label shown).
#   "hold"  — seconds the text stays fully visible before fading.
#   "fade"  — seconds the fade-out takes.
#   "style" — controls font size + color. See _apply_style() below.
#             "normal"  = 15px, off-white
#             "large"   = 22px, white
#             "small"   = 11px, uppercase, gray
#             "italic"  = 13px, italic, dimmer white (for Taglish lines)
#             "pause"   = no label — just silence for "hold" seconds
#
const LINES: Array = [
	{ "text": "Every year,",                          "hold": 1.8, "fade": 0.7, "style": "normal" },
	{ "text": "the storms come.",                     "hold": 2.0, "fade": 0.7, "style": "normal" },
	{ "text": "",                                     "hold": 0.8, "fade": 0.0, "style": "pause"  },
	{ "text": "They always come.",                    "hold": 2.2, "fade": 0.7, "style": "normal" },
	{ "text": "",                                     "hold": 0.5, "fade": 0.0, "style": "pause"  },
	{ "text": "Sa Pilipinas,",                        "hold": 1.6, "fade": 0.6, "style": "italic" },
	{ "text": "a typhoon is not a question of if.",   "hold": 2.0, "fade": 0.7, "style": "normal" },
	{ "text": "It is a question of how ready you are.","hold": 2.6, "fade": 0.8, "style": "normal" },
	{ "text": "",                                     "hold": 0.8, "fade": 0.0, "style": "pause"  },
	{ "text": "For most families,",                   "hold": 1.8, "fade": 0.6, "style": "normal" },
	{ "text": "readiness is a privilege.",            "hold": 2.8, "fade": 0.9, "style": "large"  },
	{ "text": "",                                     "hold": 0.8, "fade": 0.0, "style": "pause"  },
	{ "text": "This is the story of one family.",     "hold": 2.0, "fade": 0.7, "style": "normal" },
	{ "text": "",                                     "hold": 0.5, "fade": 0.0, "style": "pause"  },
	{ "text": "One storm.",                           "hold": 2.4, "fade": 0.8, "style": "large"  },
	{ "text": "",                                     "hold": 0.5, "fade": 0.0, "style": "pause"  },
	{ "text": "Twelve hours.",                        "hold": 2.6, "fade": 0.9, "style": "small"  },	
]

# ── Ready ──────────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Start with everything invisible
	line_label.modulate.a  = 0.0
	skip_hint.modulate.a   = 0.0
	line_label.text        = ""

	# Begin the sequence
	_run_sequence()

# ── Input — Skip on any key or mouse click ────────────────────────────────────
func _input(event: InputEvent) -> void:
	if _skipped:
		return
	if event.is_action_pressed("ui_accept") \
	or event.is_action_pressed("ui_cancel") \
	or (event is InputEventMouseButton and event.pressed):
		_skipped = true

# ── Main Sequence Coroutine ────────────────────────────────────────────────────
func _run_sequence() -> void:
	# Short silence before anything appears
	await get_tree().create_timer(0.8).timeout

	# Fade in the skip hint
	_fade_node(skip_hint, 1.0, 1.2)

	# Play each line
	for line_data in LINES:
		if _skipped:
			break

		# Silent pause — no label, just wait
		if line_data["style"] == "pause":
			await get_tree().create_timer(line_data["hold"]).timeout
			continue

		# Apply the visual style for this line
		_apply_style(line_data["style"])
		line_label.text = line_data["text"]

		# Fade in
		await _fade_label_in(0.6)

		# Hold
		await get_tree().create_timer(line_data["hold"]).timeout

		# Fade out (skip if the player pressed skip during hold)
		if not _skipped:
			await _fade_label_out(line_data["fade"])

		# Brief gap between lines
		await get_tree().create_timer(0.25).timeout

	# Sequence done — go to main menu
	_end_sequence()

# ── End: Fade to black and load main menu ────────────────────────────────────
func _end_sequence() -> void:
	line_label.text    = ""
	line_label.modulate.a = 0.0
	skip_hint.modulate.a  = 0.0

	# Hold on black for a moment
	await get_tree().create_timer(0.6).timeout

	# Use your existing TransitionOverlay, then load the main menu
	await TransitionOverlay.fade_to_black()
	SceneManager.load_scene("main_menu")   # make sure "main_menu" is in SceneManager.SCENE_PATHS

# ── Style Application ─────────────────────────────────────────────────────────
func _apply_style(style: String) -> void:
	match style:
		"normal":
			line_label.add_theme_font_size_override("font_size", 15)
			line_label.modulate = Color(0.91, 0.89, 0.86)   # warm off-white
			line_label.add_theme_color_override("font_color", Color(0.91, 0.89, 0.86))
		"large":
			line_label.add_theme_font_size_override("font_size", 22)
			line_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		"small":
			line_label.add_theme_font_size_override("font_size", 11)
			line_label.add_theme_color_override("font_color", Color(0.53, 0.53, 0.50))
			# Uppercase is set manually in the text string if desired,
			# or you can enable it via a LabelSettings resource.
		"italic":
			line_label.add_theme_font_size_override("font_size", 13)
			line_label.add_theme_color_override("font_color", Color(0.78, 0.76, 0.72))
			# To make it actually italic, assign an italic font variant
			# via a LabelSettings resource on LineLabel in the Inspector.

# ── Tween Helpers ─────────────────────────────────────────────────────────────
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
	# Non-awaited — runs in background
