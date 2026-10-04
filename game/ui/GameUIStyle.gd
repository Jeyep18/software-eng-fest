class_name GameUIStyle
extends RefCounted

const FONT_REGULAR: FontFile = preload("res://game/assets/fonts/inter/Inter-Regular.ttf")
const FONT_SEMIBOLD: FontFile = preload("res://game/assets/fonts/inter/Inter-SemiBold.ttf")
const FONT_HEADING: FontFile = preload("res://game/assets/fonts/easvhs/eas-vhs.ttf")
const GAME_THEME: Theme = preload("res://game/ui/GameTheme.tres")
const SFX = preload("res://game/audio/Sfx.gd")

const PANEL_BG: Color = Color(0.075, 0.11, 0.115, 0.96)
const PANEL_BG_SOFT: Color = Color(0.075, 0.11, 0.115, 0.82)
const SECTION_BG: Color = Color(0.19, 0.30, 0.26, 0.28)
const BORDER: Color = Color(0.21, 0.47, 0.37, 0.80)
const BORDER_SOFT: Color = Color(0.47, 0.66, 0.55, 0.24)
const TEXT: Color = Color(0.91, 0.90, 0.85)
const TEXT_MUTED: Color = Color(0.67, 0.71, 0.68)
const ACCENT: Color = Color(0.35, 0.80, 0.65)

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
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, GAME_THEME.get_stylebox(state, "Button"))
	if not button.has_theme_font_size_override("font_size"):
		button.add_theme_font_size_override("font_size", 20)
	SFX.wire_button(button)

static func apply_panel(panel: Control, soft: bool = false) -> void:
	var bg := PANEL_BG_SOFT if soft else PANEL_BG
	if panel is Panel:
		(panel as Panel).add_theme_stylebox_override("panel", panel_style(bg) if soft else GAME_THEME.get_stylebox("panel", "Panel"))
	elif panel is PanelContainer:
		(panel as PanelContainer).add_theme_stylebox_override("panel", panel_style(bg) if soft else GAME_THEME.get_stylebox("panel", "PanelContainer"))

static func apply_label(label: Label, muted: bool = false, accent: bool = false) -> void:
	label.add_theme_font_override("font", FONT_HEADING if accent else FONT_REGULAR)
	label.add_theme_color_override("font_color", ACCENT if accent else (TEXT_MUTED if muted else TEXT))
	if not label.has_theme_font_size_override("font_size"):
		label.add_theme_font_size_override("font_size", 20)

static func apply_tree(root: Node) -> void:
	if root is Button:
		apply_button(root as Button)
	elif root is Panel or root is PanelContainer:
		apply_panel(root as Control)
	elif root is Label:
		apply_label(root as Label)
	for child in root.get_children():
		apply_tree(child)
