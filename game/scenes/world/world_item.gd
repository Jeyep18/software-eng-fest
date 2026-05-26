# FILE: res://scripts/WorldItem.gd
# ATTACH TO: The root Area3D node of WorldItem.tscn
# PURPOSE: A reusable, pickupable world item that:
#   1. Displays any 3D model assigned in its ItemData resource
#   2. Shows a monologue when picked up (using the shared MonologueUI)
#   3. Adds itself to the InventoryManager
#   4. Removes itself from the scene

# WHY extends Interactable:
# Your player already knows how to talk to Interactable objects.
# It connects signals, calls interact(), shows prompts — all automatically.
# By extending Interactable, WorldItem gets ALL of that for free.
class_name WorldItem
extends Interactable

# --- CONFIGURATION (set these in the Inspector) ---

@export var world_item_id: String = ""

## The data blueprint for this item. Drag a .tres file here.
@export var item_data: ItemData

## The MonologueUI scene. Drag monologue_ui.tscn here.
## WHY: Same as the Fridge — we instantiate our own copy of the UI
## so each item is self-contained and doesn't conflict with others.
@export var monologue_ui_scene: PackedScene
@export var require_pickup_confirmation: bool = false

# --- CONSTANTS ---
# The speaker name shown in the monologue box during pickup.
# "Player" matches your existing fridge setup convention.
const SPEAKER_NAME: String = "Player"

# --- INTERNAL STATE ---
# Reference to the MonologueUI instance we create at runtime.
var _ui: MonologueUI = null

# Tracks which line of the pickup_lines array we're currently showing.
var _current_line: int = 0

# Whether the monologue is currently on screen.
var _is_showing: bool = false

# Whether the typewriter effect is still typing out text.
var _is_typing: bool = false

# Reference to the active tween (for the typewriter animation).
var _tween: Tween = null
var _paused_timer: bool = false
var _awaiting_pickup_confirmation: bool = false
var _confirm_modal: Control = null
var _confirm_message: Label = null
var _canvas_layer: CanvasLayer = null

# --- READY ---
func _ready() -> void:
	# Always call super._ready() when extending a class.
	# WHY: This runs Interactable's _ready(), which connects the
	# body_entered/body_exited signals to your player system.
	# If you skip this, the player will never trigger this item.
	super._ready()

	# Safety check: warn loudly if no data was assigned.
	if item_data == null:
		push_warning("WorldItem at " + str(global_position) + " has no ItemData assigned!")
		return
	
	if world_item_id != "" and GameState.is_item_collected(world_item_id):
		queue_free()
		return

	# Set the prompt text the player sees when nearby.
	# This uses the inherited 'prompt_label' variable from Interactable.
	prompt_label = "Press E to pick up " + item_data.item_name

	# Load the 3D model if one is assigned in the ItemData.
	_load_model()

	# Set up the MonologueUI if pickup lines exist.
	# WHY: If the item has no pickup_lines, we skip the monologue entirely
	# and just pick up silently. No crashes, no empty dialogue boxes.
	if item_data.pickup_lines.size() > 0:
		_setup_ui()

	# Listen for when the player walks away mid-dialogue.
	# This uses the inherited signal from Interactable.
	if not player_exited.is_connected(_on_player_left):
		player_exited.connect(_on_player_left)


# --- MODEL LOADING ---
func _load_model() -> void:
	# If no model is assigned in ItemData, there's nothing to load.
	if item_data.item_model == null:
		return

	# Instantiate the PackedScene (the .glb file) into an actual node.
	# WHY: A PackedScene is just a blueprint (like ItemData is a blueprint).
	# .instantiate() creates a real, living copy of it in the scene.
	var model_instance = item_data.item_model.instantiate()

	# Add the model as a child of this WorldItem node.
	add_child(model_instance)


# --- UI SETUP ---
func _setup_ui() -> void:
	if monologue_ui_scene == null:
		push_error("WorldItem '" + item_data.item_name + "': monologue_ui_scene not assigned!")
		return

	# Create the UI — same pattern as the Fridge script.
	_ui = monologue_ui_scene.instantiate() as MonologueUI

	# We need a CanvasLayer to hold the UI.
	# WHY: CanvasLayer keeps UI drawn on top of the 3D world, fixed to screen.
	# Without it, the UI would exist in 3D space and look broken.
	_canvas_layer = CanvasLayer.new()
	add_child(_canvas_layer)
	_canvas_layer.add_child(_ui)

	_ui.hide_ui()


# --- INTERACT (called by the player system automatically) ---
# This is the function Interactable defines and your player calls.
# The player presses E → player calls interact() on the current Interactable.
func interact() -> void:
	if _awaiting_pickup_confirmation:
		return

	# CASE 1: No pickup lines defined — skip monologue, pick up immediately.
	if item_data.pickup_lines.size() == 0:
		_prompt_or_pickup()
		return

	# CASE 2: Monologue not started yet — show the first line.
	if not _is_showing:
		_current_line = 0
		_show_current_line()
		return

	# CASE 3: Typewriter is still typing — skip to end of current line.
	if _is_typing:
		_skip_to_line_end()
		return

	# CASE 4: Move to next line.
	_current_line += 1

	# CASE 5: No more lines — monologue is done, pick up the item.
	if _current_line >= item_data.pickup_lines.size():
		if require_pickup_confirmation:
			_show_pickup_confirmation()
		else:
			_hide_monologue()
			_do_pickup()  # ← THIS is when the item actually gets picked up.
		return

	# Otherwise show the next line.
	_show_current_line()


# --- MONOLOGUE HELPERS ---
# These mirror the Fridge script exactly, just using item_data.pickup_lines.

func _show_current_line() -> void:
	if not _paused_timer:
		GlobalTimer.pause_timer()
		_paused_timer = true
	get_tree().call_group("player", "set_movement_locked", true)
	is_showing = true  # inherited from Interactable
	_is_showing = true
	_is_typing = true

	var line: String = item_data.pickup_lines[_current_line]
	_ui.show_line(line, SPEAKER_NAME)
	_ui.set_prompt_visible(false)
	prompt_visibility_changed.emit(false)

	if _tween and _tween.is_valid():
		_tween.kill()

	_tween = _ui.run_typewriter(20.0)  # 20 characters per second
	_tween.finished.connect(_on_typewriter_finished, CONNECT_ONE_SHOT)


func _skip_to_line_end() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_ui.skip_to_end()
	_ui.set_prompt_visible(true)
	_is_typing = false


func _hide_monologue() -> void:
	is_showing = false
	if _tween and _tween.is_valid():
		_tween.kill()
	_ui.hide_ui()
	_is_showing = false
	_is_typing = false
	_current_line = 0
	if _paused_timer:
		GlobalTimer.resume_timer()
		_paused_timer = false
	get_tree().call_group("player", "set_movement_locked", false)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	prompt_visibility_changed.emit(true)

func _show_pickup_confirmation() -> void:
	_awaiting_pickup_confirmation = true
	is_showing = true
	_is_showing = true
	_is_typing = false
	if _ui != null:
		_ui.hide_ui()
	_show_confirm_dialog()
	prompt_visibility_changed.emit(false)

func _prompt_or_pickup() -> void:
	if require_pickup_confirmation:
		if _ui == null:
			_setup_ui()
		if not _paused_timer:
			GlobalTimer.pause_timer()
			_paused_timer = true
		get_tree().call_group("player", "set_movement_locked", true)
		_show_pickup_confirmation()
	else:
		_do_pickup()

func _confirm_pickup() -> void:
	_awaiting_pickup_confirmation = false
	_hide_monologue()
	_do_pickup()

func _show_confirm_dialog() -> void:
	if _canvas_layer == null:
		_canvas_layer = CanvasLayer.new()
		add_child(_canvas_layer)
	if _confirm_modal == null:
		_build_confirm_modal()
	_confirm_message.text = "Pick up %s?" % item_data.item_name
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_confirm_modal.show()
	_confirm_modal.grab_focus()

func _build_confirm_modal() -> void:
	_confirm_modal = Control.new()
	_confirm_modal.name = "PickupConfirmModal"
	_confirm_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm_modal.focus_mode = Control.FOCUS_ALL
	_confirm_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm_modal.gui_input.connect(_on_confirm_modal_gui_input)
	_canvas_layer.add_child(_confirm_modal)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.45)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm_modal.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_confirm_modal.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 150)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)

	var title := Label.new()
	title.text = "Pick Up Item?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	content.add_child(title)

	_confirm_message = Label.new()
	_confirm_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_message.add_theme_font_size_override("font_size", 16)
	content.add_child(_confirm_message)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	content.add_child(actions)

	var leave_button := Button.new()
	leave_button.text = "Leave"
	leave_button.focus_mode = Control.FOCUS_NONE
	leave_button.custom_minimum_size = Vector2(100, 36)
	leave_button.pressed.connect(_on_pickup_cancelled)
	actions.add_child(leave_button)

	var pickup_button := Button.new()
	pickup_button.text = "Pick Up"
	pickup_button.focus_mode = Control.FOCUS_NONE
	pickup_button.custom_minimum_size = Vector2(100, 36)
	pickup_button.pressed.connect(_on_pickup_confirmed)
	actions.add_child(pickup_button)

	_confirm_modal.hide()

func _on_confirm_modal_gui_input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventJoypadButton:
		_confirm_modal.accept_event()

func _unhandled_input(event: InputEvent) -> void:
	if not _awaiting_pickup_confirmation:
		return
	if event is InputEventKey or event is InputEventJoypadButton:
		get_viewport().set_input_as_handled()

func _on_pickup_confirmed() -> void:
	if _confirm_modal != null:
		_confirm_modal.hide()
	_confirm_pickup()

func _on_pickup_cancelled() -> void:
	if _confirm_modal != null:
		_confirm_modal.hide()
	_awaiting_pickup_confirmation = false
	_hide_monologue()


func _on_typewriter_finished() -> void:
	_is_typing = false
	_ui.set_prompt_visible(true)


func _on_player_left(_interactable: Interactable) -> void:
	# If the player walks away during the monologue, close it.
	# The item stays in the world — they didn't finish reading.
	if _is_showing:
		_awaiting_pickup_confirmation = false
		if _confirm_modal != null and _confirm_modal.visible:
			_confirm_modal.hide()
		_hide_monologue()


# --- THE ACTUAL PICKUP ---
func _do_pickup() -> void:
	if item_data == null:
		return

	var success = InventoryManager.add_item(item_data)

	if success:
		# ↓ ADD THIS before queue_free
		if world_item_id != "":
			GameState.mark_item_collected(world_item_id)
		queue_free()
	else:
		push_warning("WorldItem: inventory full, cannot pick up: " + item_data.item_name)
