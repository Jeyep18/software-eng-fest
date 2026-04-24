# IntroSequence.gd
# Attach to: the root CanvasLayer node of IntroSequence.tscn
# Location:  res://game/scenes/intro/IntroSequence.gd

extends CanvasLayer

# ── Node References ────────────────────────────────────────────────────────────
@onready var background: ColorRect = $Background
@onready var line_label: Label     = $Background/LineLabel
@onready var skip_hint:  Label     = $Background/SkipHint

# ── State ──────────────────────────────────────────────────────────────────────
var _skipped: bool = false

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

	{ "text": "The flood barriers were repaired last year. The budget was approved. The funds were released.",                        "hold": 2.0, "fade": 0.8, "style": "italic"  },
	{ "text": "",                                      "hold": 0.6, "fade": 0.0, "style": "pause"   },
	{ "text": "So why is the water rising?",                                "hold": 1.4, "fade": 0.6, "style": "normal"  },
	{ "text": "",                             "hold": 1.8, "fade": 0.7, "style": "normal"  },
	{ "text": "",                                      "hold": 0.8, "fade": 0.0, "style": "pause"   },
	{ "text": "Every year, the storm comes. Every year, the government is ready",      "hold": 2.0, "fade": 0.7, "style": "normal"  },
	{ "text": "This year, you were not",                      "hold": 1.8, "fade": 0.7, "style": "normal"  },
	{ "text": "",                                      "hold": 0.6, "fade": 0.0, "style": "pause"   },

	# ── Block 2: The Bulletin ──────────────────────────────────────────────────
	# Short. Clinical. The rhythm breaks on purpose here.
	# No adjectives. Just the numbers.

	{ "text": "Somewhere in the Philippines, a family prepares for the storm",                       "hold": 2.4, "fade": 0.9, "style": "large"   },
	{ "text": "",                                      "hold": 0.8, "fade": 0.0, "style": "pause"   },
	{ "text": "Signal 3",                             "hold": 1.6, "fade": 0.6, "style": "normal"  },
	{ "text": "Escalating to Signal 4",               "hold": 2.0, "fade": 0.7, "style": "normal"  },
	{ "text": "Only 12 hours left",             "hold": 2.6, "fade": 0.8, "style": "normal"  },
	{ "text": "",                                      "hold": 0.9, "fade": 0.0, "style": "pause"   },
	{ "text": "Do what you can",                       "hold": 1.6, "fade": 0.5, "style": "normal"  },
	{ "text": "with what you have.",                   "hold": 2.6, "fade": 1.0, "style": "normal"  },

	# ── Trailing silence before scene transition ───────────────────────────────
	{ "text": "",                                      "hold": 0.6, "fade": 0.0, "style": "pause"   },
	{ "text": "",                                      "hold": 0.6, "fade": 0.0, "style": "pause"   },
	{ "text": "",                                      "hold": 0.6, "fade": 0.0, "style": "pause"   },
]

# ── Ready ──────────────────────────────────────────────────────────────────────
func _ready() -> void:
	line_label.modulate.a = 0.0
	skip_hint.modulate.a  = 0.0
	line_label.text       = ""
	_run_sequence()
	AudioManager.play_ambience(preload("res://game/assets/sfx/freesound_community-morning-birds-30911-FreeSoundCommunityPixabay.mp3"))
	AudioManager.play_music(preload("res://game/assets/sfx/samuelfjohanns-extreme-sad-cinema-12299-SamuelFJohannsPixabay.mp3"))

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
	await get_tree().create_timer(0.8).timeout
	_fade_node(skip_hint, 1.0, 1.2)

	for line_data in LINES:
		if _skipped:
			break

		if line_data["style"] == "pause":
			await get_tree().create_timer(line_data["hold"]).timeout
			continue

		_apply_style(line_data["style"])
		line_label.text = line_data["text"]

		await _fade_label_in(0.6)
		await get_tree().create_timer(line_data["hold"]).timeout

		if not _skipped:
			await _fade_label_out(line_data["fade"])

		await get_tree().create_timer(0.25).timeout

	_end_sequence()

# ── End: Fade to black and load main menu ────────────────────────────────────
func _end_sequence() -> void:
	line_label.text       = ""
	line_label.modulate.a = 0.0
	skip_hint.modulate.a  = 0.0

	await get_tree().create_timer(0.6).timeout
	await TransitionOverlay.fade_to_black()
	SceneManager.load_scene("main_menu")

# ── Style Application ─────────────────────────────────────────────────────────
func _apply_style(style: String) -> void:
	match style:
		"normal":
			line_label.add_theme_font_size_override("font_size", 35)
			line_label.add_theme_color_override("font_color", Color(0.91, 0.89, 0.86))
		"large":
			line_label.add_theme_font_size_override("font_size", 35)
			line_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		"small":
			line_label.add_theme_font_size_override("font_size", 35)
			line_label.add_theme_color_override("font_color", Color(0.53, 0.53, 0.50))
		"italic":
			line_label.add_theme_font_size_override("font_size", 35)
			line_label.add_theme_color_override("font_color", Color(0.78, 0.76, 0.72))
			# Assign an italic font variant via LabelSettings in the Inspector
			# for this style to render correctly.

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
