class_name CameraVolume
extends Area3D

@export_group("Position")
@export var z_distance: float = 6.0
@export var height_offset: float = 2.0

@export_group("Z Boundary")
@export var z_wall_position: float = 0.0
@export var z_camera_buffer: float = 1.5
@export var z_dynamic_enabled: bool = false

@export_group("X Bounds")
@export var x_min: float = -5.0
@export var x_max: float = 5.0

@export_group("Y Behaviour")
@export var lock_y: bool = true
@export var locked_y_position: float = 0.0

@export_group("Transition")
@export var transition_duration: float = 0.6
@export var transition_ease: Tween.EaseType = Tween.EASE_OUT

signal player_entered_volume(volume: CameraVolume)
signal player_exited_volume(volume: CameraVolume)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_entered_volume.emit(self)


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_exited_volume.emit(self)
