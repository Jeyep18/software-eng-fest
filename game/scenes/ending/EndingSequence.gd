# The scene keeps visual-only sets. Capture gameplay state before any awaits;
# presentation beats and leaderboard submission must describe the same run.

extends Node

signal result_continue_requested

const UI_STYLE = preload("res://game/ui/GameUIStyle.gd")
const SFX = preload("res://game/audio/Sfx.gd")
const ENDING_STORM: AudioStream = preload("res://game/assets/sfx/soundreality-rain-thunder-sfx-525011.mp3")
const HOUSE_ENV: Environment = preload("res://game/resources/environments/house1_environment.tres")
const SHOP_ENV: Environment = preload("res://game/resources/environments/storm_shop_environment.tres")
const PUBLIC_SHOTS: Dictionary = {
	"hardware": ["LocationSets/Hardware/Start", "LocationSets/Hardware/Focus", "After the storm, repairing a home still depended on materials a family could reach and afford."],
	"grocery": ["LocationSets/Grocery/Start", "LocationSets/Grocery/Focus", "The market held supplies, but families needed a way to reach and afford them before the roads closed."],
	"pharmacy": ["LocationSets/Pharmacy/Start", "LocationSets/Pharmacy/Focus", "Medicine and a meal could be found here, if families could reach the shops in time."],
	"tindahan": ["LocationSets/Tindahan/Start", "LocationSets/Tindahan/Focus", "At the tindahan, neighbors shared warnings and helped one another prepare."],
}

# ── Node References ────────────────────────────────────────────────────────────
@onready var ending_camera: Camera3D          = $EndingCamera
@onready var fade_overlay:  ColorRect         = $CanvasLayer/FadeOverlay
@onready var slide_label:   Label             = $CanvasLayer/VBoxContainer/SlideLabel
@onready var result_panel:  Control           = $CanvasLayer/ResultPanel
@onready var lightning:     SpotLight3D       = $Lights/Lightning
@onready var world_environment: WorldEnvironment = $Environment/WorldEnvironment
@onready var house_sun: DirectionalLight3D = $Environment/DirectionalLight3D

@onready var anchor_windows:  Node3D = $World3D/WindowArea
@onready var anchor_roof:     Node3D = $World3D/RoofArea
@onready var anchor_medicine: Node3D = $World3D/BedroomArea
@onready var anchor_food:     Node3D = $World3D/KitchenArea
@onready var anchor_water:    Node3D = $World3D/WaterArea
@onready var anchor_radio:    Node3D = $World3D/RadioArea

# ── Timing ─────────────────────────────────────────────────────────────────────
const FADE_DURATION:        float = 0.65
const CAMERA_MOVE_DURATION: float = 7.0
const CAMERA_ORBIT_ANGLE: float = 1.5
const SLIDE_HOLD_DURATION:  float = 4.0
const LABEL_FADE_IN:        float = 0.35
const LABEL_FADE_OUT:       float = 0.35
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
var _continue_label: Label = null
var _awaiting_result_continue: bool = false
var _snapshot: Dictionary = {}
var _camera_tween: Tween

func _ready() -> void:
	_snapshot = {
		"resolved_needs": NeedsLog.get_all_resolved().duplicate(),
		"resolved_ids": NeedsLog.get_resolved_need_ids(),
		"weighted_progress": NeedsLog.get_weighted_progress(),
		"boarded_windows": NeedsLog.boarded_window_count(),
		"nestor_status": SideQuestLog.get_quest_state(SideQuestLog.QUEST_MANG_NESTOR_CHICKEN),
		"visited": SceneManager.get_visited_locations(),
		"difficulty_id": GameState.get_difficulty_id(),
		"difficulty_label": GameState.get_difficulty_label(),
		"remaining_minutes": LeaderboardManager.consume_remaining_time_snapshot(),
		"unranked": DevMode.run_unranked,
	}
	AudioManager.play_ambience(ENDING_STORM)
	AudioManager.play_music(preload("res://game/assets/sfx/samuelfjohanns-extreme-sad-cinema-12299-SamuelFJohannsPixabay.mp3"))
	SLIDES = [
		{
			"need":            NeedsLog.Need.WINDOWS,
			"anchor":          anchor_windows,
			"visual_cue_path": "World3D/WindowArea/WindowTaskVisualCue",
			"label_done":      "Both windows held against the wind.",
			"label_partial":   "One window had boards; the other still let wind and rain in.",
			"label_skip":      "Unboarded windows let wind and rain into the house.",
		},
		{
			"need":            NeedsLog.Need.ROOF,
			"anchor":          anchor_roof,
			"visual_cue_path": "World3D/RoofArea/RoofTaskVisualCue",
			"label_done":      "The patched roof kept rain out of the living room.",
			"label_skip":      "Rain entered through the unrepaired roof.",
		},
		{
			"need":            NeedsLog.Need.MEDICINE,
			"anchor":          anchor_medicine,
			"visual_cue_path": "World3D/MedicineTaskVisualCue",
			"label_done":      "Lola had the medicine she needed through the storm.",
			"label_skip":      "Lola faced the storm without her needed medicine.",
		},
		{
			"need":            NeedsLog.Need.FOOD,
			"anchor":          anchor_food,
			"visual_cue_path": "World3D/FoodTaskVisualCue",
			"label_done":      "The family had food ready for the storm.",
			"label_skip":      "The family had no food set aside when the storm came.",
		},
		{
			"need":            NeedsLog.Need.WATER,
			"anchor":          anchor_water,
			"visual_cue_path": "World3D/WaterArea/WaterTaskVisualCue",
			"label_done":      "Clean water was ready at home.",
			"label_skip":      "The family had no clean water stored at home.",
		},
		{
			"need":            NeedsLog.Need.FLASHLIGHT,
			"anchor":          anchor_radio,
			"visual_cue_path": "World3D/RadioArea/RadioTaskVisualCue",
			"label_done":      "The radio and flashlight helped the family follow warnings through the dark.",
			"label_skip":      "With no working radio or flashlight, the family had less light and fewer updates.",
		},
	]
	_append_visited_shots()
	$LocationSets/Tindahan/NestorVisual.visible = _snapshot["nestor_status"] != SideQuestLog.STATE_NOT_STARTED and _snapshot["nestor_status"] != SideQuestLog.STATE_COMPLETED

	get_tree().paused = false
	GlobalTimer.pause_timer(self)

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

func _input(event: InputEvent) -> void:
	if not _awaiting_result_continue or not _is_continue_input(event):
		return
	_awaiting_result_continue = false
	get_viewport().set_input_as_handled()
	result_continue_requested.emit()

func _is_continue_input(event: InputEvent) -> bool:
	return (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed) or (event is InputEventJoypadButton and event.pressed) or (event is InputEventScreenTouch and event.pressed)


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

func _append_visited_shots() -> void:
	var visited: Array = _snapshot["visited"]
	var quest_status: String = _snapshot["nestor_status"]
	for location_id in ["hardware", "grocery", "pharmacy", "tindahan"]:
		if not visited.has(location_id) and not (location_id == "tindahan" and quest_status != SideQuestLog.STATE_NOT_STARTED):
			continue
		var shot: Array = PUBLIC_SHOTS[location_id]
		var text: String = shot[2]
		if location_id == "tindahan" and quest_status == SideQuestLog.STATE_COMPLETED:
			text = "Mang Nestor's place outside the tindahan stood empty. He returned home with the chicken, and his family weathered the storm with food on the table."
		elif location_id == "tindahan" and quest_status != SideQuestLog.STATE_NOT_STARTED:
			text = "Mang Nestor was still waiting outside the tindahan when the storm came. The promised meal never reached his family; they had no food on the table."
		SLIDES.append({
			"anchor": get_node(shot[0]),
			"focus": get_node(shot[1]),
			"location_id": location_id,
			"text": text,
		})


# ── Main Sequence ──────────────────────────────────────────────────────────────
func _run_sequence() -> void:
	await get_tree().create_timer(0.3).timeout

	for slide in SLIDES:
		var is_house: bool = slide.has("need")
		var is_done: bool = is_house and _check_slide_done(slide)
		var is_partial: bool = is_house and slide["need"] == NeedsLog.Need.WINDOWS and not is_done and _snapshot["boarded_windows"] == 1
		_apply_visual_cue(slide, is_done, is_partial)
		_set_shot_environment(slide.get("location_id", ""))
		_snap_camera_to(slide["anchor"])
		if not is_house:
			ending_camera.look_at(slide["focus"].global_position)
		await _fade(0.0)
		if is_house:
			_play_slide_sfx(slide, is_done)
		var source_text: String = slide.get("text", "")
		if is_house:
			source_text = slide["label_partial"] if is_partial else (slide["label_done"] if is_done else slide["label_skip"])
		var localized_text := LocalizationManager.translate(source_text)
		_start_label(localized_text)
		_move_camera_around(slide)
		await get_tree().create_timer(maxf(SLIDE_HOLD_DURATION, float(localized_text.length()) / 17.0)).timeout
		await _fade_out_label()
		await _fade(1.0)
	await _show_closing_line()
	await _show_result_panel()

func _show_closing_line() -> void:
	var closing := LocalizationManager.translate("What you prepared mattered. So did the people you remembered. But being strong isn't just enough. Families also deserve protection they can depend on.")
	_start_label(closing)
	await _fade(0.0)
	await get_tree().create_timer(maxf(8.0, float(closing.length()) / 17.0)).timeout
	await _fade_out_label()
	await _fade(1.0)


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

func _apply_visual_cue(slide: Dictionary, is_done: bool, is_partial: bool = false) -> void:
	var path: String = slide.get("visual_cue_path", "")
	if path == "":
		return
	var node: Node3D = get_node_or_null(path)
	if node == null:
		push_warning("EndingSequence: visual_cue_path not found: " + path)
		return
	node.visible = is_done or is_partial


# ── Slide State Check ──────────────────────────────────────────────────────────
func _check_slide_done(slide: Dictionary) -> bool:
	return _snapshot["resolved_needs"].has(slide["need"])


# ── Camera ─────────────────────────────────────────────────────────────────────
func _snap_camera_to(anchor: Node3D) -> void:
	if _camera_tween and _camera_tween.is_running():
		_camera_tween.kill()
	ending_camera.global_transform = anchor.global_transform

func _move_camera_around(slide: Dictionary) -> void:
	# House anchors retain their authored view; town Focus nodes are editable in the scene.
	var focus: Vector3 = slide["focus"].global_position if slide.has("focus") else ending_camera.global_position - ending_camera.global_basis.z * 3.0
	var start_offset: Vector3 = ending_camera.global_position - focus
	_camera_tween = create_tween()
	_camera_tween.set_trans(Tween.TRANS_SINE)
	_camera_tween.tween_method(_orbit_camera.bind(focus, start_offset), 0.0, 1.0, CAMERA_MOVE_DURATION)

func _orbit_camera(progress: float, focus: Vector3, start_offset: Vector3) -> void:
	ending_camera.global_position = focus + Basis(Vector3.UP, deg_to_rad(CAMERA_ORBIT_ANGLE * progress)) * start_offset
	ending_camera.look_at(focus)

func _set_shot_environment(location_id: String) -> void:
	var is_house := location_id.is_empty()
	world_environment.environment = HOUSE_ENV if is_house else SHOP_ENV
	house_sun.visible = is_house
	$Environment/VoxelGI.visible = is_house
	for location_set in $LocationSets.get_children():
		var active: bool = location_set.name.to_lower() == location_id
		var sun := location_set.get_node_or_null("Sun") as DirectionalLight3D
		if sun:
			sun.visible = active
		var gi := location_set.get_node_or_null("VoxelGI") as VoxelGI
		if gi:
			gi.visible = active


# ── Fade ───────────────────────────────────────────────────────────────────────
func _fade(target_alpha: float) -> void:
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade_overlay, "color:a", target_alpha, FADE_DURATION)
	await tween.finished


# ── Label ──────────────────────────────────────────────────────────────────────
func _start_label(text: String) -> void:
	slide_label.text = text
	slide_label.add_theme_color_override("font_color", UI_STYLE.TEXT)
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
	_continue_label.modulate.a = 1.0
	_awaiting_result_continue = true
	await result_continue_requested
	await _fade(1.0)
	result_panel.hide()
	await _submit_leaderboard_score()
	DevMode.end_run()
	SceneManager.reset()
	StormEnroachment.reset()
	GameState.reset()
	GlobalTimer.reset()
	NeedsLog.reset()
	SideQuestLog.reset()
	EconomyManager.reset()
	ShopUi.reset()
	InventoryManager.reset()
	await TransitionOverlay.fade_to_black()
	SceneManager.load_scene("main_menu")

func _submit_leaderboard_score() -> void:
	if _leaderboard_score_saved:
		return
	if _snapshot["unranked"]:
		_leaderboard_score_saved = true
		return

	var prompt_layer := _create_leaderboard_prompt()
	var name_input: LineEdit = prompt_layer.get_node("Panel/MarginContainer/VBoxContainer/NameInput")
	var submit_button: Button = prompt_layer.get_node("Panel/MarginContainer/VBoxContainer/ButtonRow/SubmitButton")

	name_input.text_changed.connect(func(new_text: String) -> void:
		submit_button.disabled = new_text.strip_edges().is_empty()
	)
	name_input.text_submitted.connect(func(_new_text: String) -> void:
		if not submit_button.disabled:
			submit_button.pressed.emit()
	)

	add_child(prompt_layer)
	CursorState.request_visible(prompt_layer)
	name_input.call_deferred("grab_focus")
	await submit_button.pressed

	var player_name: String = name_input.text.strip_edges()
	if player_name.is_empty():
		player_name = "Player"

	LeaderboardManager.record_run(player_name, _snapshot["resolved_ids"], _snapshot["nestor_status"], _snapshot["remaining_minutes"], _snapshot["difficulty_id"])
	SFX.ui_click()
	_leaderboard_score_saved = true
	prompt_layer.queue_free()

func _create_leaderboard_prompt() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.name = "LeaderboardNamePrompt"
	layer.layer = 50

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(580, 280)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -290
	panel.offset_top = -140
	panel.offset_right = 290
	panel.offset_bottom = 140
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
	summary.text = LocalizationManager.trf("Mode: %s\nNeeds: %d / %d  |  Priority: %d / %d  |  Time left: %s", [
		_snapshot["difficulty_label"],
		_snapshot["resolved_ids"].size(),
		NeedsLog.Need.size(),
		_snapshot["weighted_progress"],
		NeedsLog.TOTAL_WEIGHT,
		_format_minutes(_snapshot["remaining_minutes"]),
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
	# Whole hours; the remainder below supplies the minutes.
	@warning_ignore("integer_division")
	var hours: int = safe_minutes / 60
	var mins: int = safe_minutes % 60
	return "%dh %02dm" % [hours, mins]

func _populate_result_panel() -> void:
	var title_lbl:  Label         = result_panel.get_node("VBoxContainer/TitleLabel")
	var sub_lbl:    Label         = result_panel.get_node("VBoxContainer/SubLabel")
	var item_list:  VBoxContainer = result_panel.get_node("VBoxContainer/ItemList")
	var footer_lbl: Label         = result_panel.get_node("VBoxContainer/FooterLabel")
	var box := result_panel.get_node("VBoxContainer") as VBoxContainer

	var resolved_ids: Array = _snapshot["resolved_ids"]
	var weight: int = _snapshot["weighted_progress"]
	var nestor_completed: bool = _snapshot["nestor_status"] == SideQuestLog.STATE_COMPLETED
	var household_title := LocalizationManager.translate(_get_household_title())
	var promise_title := ""
	if _snapshot["nestor_status"] != SideQuestLog.STATE_NOT_STARTED:
		promise_title = LocalizationManager.translate("A Promise Kept" if nestor_completed else "A Promise Unfulfilled")
	title_lbl.text = household_title if promise_title.is_empty() else household_title + "\n" + promise_title
	title_lbl.modulate.a = 0.0

	sub_lbl.text = _get_missing_needs_line(resolved_ids)
	sub_lbl.add_theme_color_override("font_color", UI_STYLE.TEXT_MUTED)
	sub_lbl.modulate.a = 0.0

	for child in item_list.get_children():
		child.queue_free()
	item_list.show()
	item_list.modulate.a = 0.0
	var summary_panel := PanelContainer.new()
	summary_panel.add_theme_stylebox_override("panel", UI_STYLE.panel_style(Color(0.04, 0.085, 0.075, 0.92), UI_STYLE.BORDER, 6))
	item_list.add_child(summary_panel)
	var summary_margin := MarginContainer.new()
	for side in ["left", "right"]:
		summary_margin.add_theme_constant_override("margin_" + side, 18)
	for side in ["top", "bottom"]:
		summary_margin.add_theme_constant_override("margin_" + side, 12)
	summary_panel.add_child(summary_margin)
	var summary_box := VBoxContainer.new()
	summary_box.add_theme_constant_override("separation", 8)
	summary_margin.add_child(summary_box)
	var summary_title := Label.new()
	summary_title.text = LocalizationManager.translate("RUN SUMMARY")
	summary_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_title.add_theme_font_override("font", UI_STYLE.FONT_SEMIBOLD)
	summary_title.add_theme_font_size_override("font_size", 23)
	summary_title.add_theme_color_override("font_color", UI_STYLE.ACCENT)
	summary_box.add_child(summary_title)
	var metrics := GridContainer.new()
	metrics.columns = 2
	metrics.add_theme_constant_override("h_separation", 20)
	metrics.add_theme_constant_override("v_separation", 5)
	summary_box.add_child(metrics)
	var metric_lines := [
		LocalizationManager.trf("Needs met: %d / %d", [resolved_ids.size(), NeedsLog.Need.size()]),
		LocalizationManager.trf("Priority weight: %d / %d", [weight, NeedsLog.TOTAL_WEIGHT]),
		LocalizationManager.trf("Preparation: %d points", [weight * 2000]),
	]
	if _snapshot["nestor_status"] != SideQuestLog.STATE_NOT_STARTED:
		metric_lines.append(LocalizationManager.trf("Mang Nestor: +%d points", [1000 if nestor_completed else 0]))
	metric_lines.append_array([
		LocalizationManager.trf("Time: +%d points", [_snapshot["remaining_minutes"]]),
		LocalizationManager.trf("Mode: %s (x%.1f)", [_snapshot["difficulty_label"], GameState.get_difficulty_score_multiplier(_snapshot["difficulty_id"])]),
		LocalizationManager.translate("Dev Mode run - unranked") if _snapshot["unranked"] else LocalizationManager.trf("Score: %d", [roundi(LeaderboardManager.calculate_score(resolved_ids, nestor_completed, _snapshot["remaining_minutes"], _snapshot["difficulty_id"]))]),
	])
	for metric_text in metric_lines:
		var metric := Label.new()
		metric.text = metric_text
		metric.custom_minimum_size = Vector2(390, 0)
		metric.add_theme_font_override("font", UI_STYLE.FONT_REGULAR)
		metric.add_theme_font_size_override("font_size", 19)
		metric.add_theme_color_override("font_color", UI_STYLE.TEXT)
		metrics.add_child(metric)

	footer_lbl.text = (
		LocalizationManager.translate("Every year, an average of 20 typhoons test our resilience. But while \"flood control projects\" remain sturdy only on paper and political tarpaulins, ordinary citizens are left to swim for their lives.")
		+ "\n\n"
		+ LocalizationManager.translate("Safety is not a privilege to be earned. It is a basic accountability of those in power.")
	)
	footer_lbl.modulate.a = 0
	footer_lbl.add_theme_font_override("font", UI_STYLE.FONT_REGULAR)
	footer_lbl.add_theme_color_override("font_color", Color(0.82, 0.80, 0.72))
	footer_lbl.add_theme_font_size_override("font_size", 23)
	footer_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer_lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	footer_lbl.custom_minimum_size = Vector2(840, 0)
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

	if _continue_label == null:
		_continue_label = Label.new()
		_continue_label.name = "ContinueLabel"
		_continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(_continue_label)
	_continue_label.text = LocalizationManager.translate("Press any key or button to continue")
	_continue_label.modulate.a = 0.0
	_continue_label.add_theme_font_override("font", UI_STYLE.FONT_REGULAR)
	_continue_label.add_theme_font_size_override("font_size", 19)
	_continue_label.add_theme_color_override("font_color", UI_STYLE.TEXT_MUTED)

func _get_household_title() -> String:
	var weight: int = _snapshot["weighted_progress"]
	var ids: Array = _snapshot["resolved_ids"]
	if weight == NeedsLog.TOTAL_WEIGHT:
		return "A Prepared Home"
	if weight >= 8 and ids.has("food") and ids.has("water") and ids.has("medicine"):
		return "Essentials Secured, Gaps Remain"
	if weight >= 4:
		return "A Night of Shortages"
	return "Too Little Prepared"

func _get_missing_needs_line(resolved_ids: Array) -> String:
	var missing: Array[String] = []
	for entry in [["food", "food"], ["water", "water"], ["medicine", "Lola's medicine"], ["roof", "roof"], ["windows", "windows"], ["flashlight", "radio and flashlight"]]:
		if not resolved_ids.has(entry[0]):
			missing.append(LocalizationManager.translate(entry[1]))
	if missing.is_empty():
		return LocalizationManager.translate("All household needs were met.")
	return LocalizationManager.trf("Still missing at home: %s", [", ".join(missing)])

func _apply_result_ui_style() -> void:
	UI_STYLE.apply_tree(result_panel)
	result_panel.custom_minimum_size = Vector2(900, 600)
	result_panel.set_anchors_preset(Control.PRESET_CENTER)
	result_panel.offset_left = -450.0
	result_panel.offset_top = -300.0
	result_panel.offset_right = 450.0
	result_panel.offset_bottom = 300.0
	result_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	var box := result_panel.get_node("VBoxContainer") as VBoxContainer
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)

	var title_lbl := result_panel.get_node("VBoxContainer/TitleLabel") as Label
	title_lbl.add_theme_font_override("font", UI_STYLE.FONT_SEMIBOLD)
	title_lbl.add_theme_font_size_override("font_size", 30)
	title_lbl.add_theme_color_override("font_color", Color(0.94, 0.94, 0.90))
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var sub_lbl := result_panel.get_node("VBoxContainer/SubLabel") as Label
	sub_lbl.add_theme_font_override("font", UI_STYLE.FONT_SEMIBOLD)
	sub_lbl.add_theme_font_size_override("font_size", 20)
	sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

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
	footer_lbl.custom_minimum_size = Vector2(840, 185)
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
	tween.tween_property(result_panel.get_node("VBoxContainer/ItemList"), "modulate:a", 1.0, RESULT_TEXT_FADE_IN).set_delay(RESULT_BODY_DELAY)
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
