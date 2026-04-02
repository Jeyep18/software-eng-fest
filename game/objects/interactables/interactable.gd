class_name Interactable
extends Area3D

@export var prompt_label: String = "[Press E to Interact]"

## Override in subclasses that have an active "showing" state.
var is_showing: bool = false

signal player_entered(interactable: Interactable)
signal player_exited(interactable: Interactable)
signal prompt_visibility_changed(should_show: bool)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if not player_entered.is_connected(body._on_interactable_entered):
		player_entered.connect(body._on_interactable_entered)
	if not player_exited.is_connected(body._on_interactable_exited):
		player_exited.connect(body._on_interactable_exited)
	player_entered.emit(self)


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_exited.emit(self)


func interact() -> void:
	push_warning("Interactable: interact() not implemented on " + name)
