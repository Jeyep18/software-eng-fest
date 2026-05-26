class_name GameUIStyle
extends RefCounted

const FONT_REGULAR: FontFile = preload("res://game/assets/fonts/inter/Inter-Regular.ttf")
const FONT_SEMIBOLD: FontFile = preload("res://game/assets/fonts/inter/Inter-SemiBold.ttf")
const SFX = preload("res://game/audio/Sfx.gd")

const PANEL_BG: Color = Color(0.075, 0.08, 0.085, 0.96)
const PANEL_BG_SOFT: Color = Color(0.075, 0.08, 0.085, 0.82)
const SECTION_BG: Color = Color(1, 1, 1, 0.045)
const BORDER: Color = Color(0.95, 0.78, 0.45, 0.45)
const BORDER_SOFT: Color = Color(1, 1, 1, 0.10)
const TEXT: Color = Color(1, 1, 1, 0.86)
const TEXT_MUTED: Color = Color(1, 1, 1, 0.64)
const ACCENT: Color = Color(0.98, 0.9, 0.62)

static func panel_style(bg_color: Color = PANEL_BG, border_color: Color = BORDER, radius: int = 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style

static func button_style(bg_color: Color, border_color: Color = BORDER_SOFT) -> StyleBoxFlat:
	var style := panel_style(bg_color, border_color, 6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style

static func apply_button(button: Button) -> void:
	button.add_theme_font_override("font", FONT_SEMIBOLD)
	button.add_theme_stylebox_override("normal", button_style(Color(0.13, 0.14, 0.15, 0.95)))
	button.add_theme_stylebox_override("hover", button_style(Color(0.18, 0.19, 0.19, 0.98), BORDER))
	button.add_theme_stylebox_override("pressed", button_style(Color(0.10, 0.11, 0.12, 0.98), BORDER))
	button.add_theme_stylebox_override("disabled", button_style(Color(0.08, 0.08, 0.08, 0.65), Color(1, 1, 1, 0.05)))
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", ACCENT)
	button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.35))
	if not button.has_theme_font_size_override("font_size"):
		button.add_theme_font_size_override("font_size", 16)
	SFX.wire_button(button)

static func apply_panel(panel: Control, soft: bool = false) -> void:
	var bg := PANEL_BG_SOFT if soft else PANEL_BG
	if panel is Panel:
		(panel as Panel).add_theme_stylebox_override("panel", panel_style(bg))
	elif panel is PanelContainer:
		(panel as PanelContainer).add_theme_stylebox_override("panel", panel_style(bg))

static func apply_label(label: Label, muted: bool = false, accent: bool = false) -> void:
	label.add_theme_font_override("font", FONT_REGULAR)
	label.add_theme_color_override("font_color", ACCENT if accent else (TEXT_MUTED if muted else TEXT))

static func apply_tree(root: Node) -> void:
	if root is Button:
		apply_button(root as Button)
	elif root is Panel or root is PanelContainer:
		apply_panel(root as Control)
	elif root is Label:
		apply_label(root as Label)
	for child in root.get_children():
		apply_tree(child)
