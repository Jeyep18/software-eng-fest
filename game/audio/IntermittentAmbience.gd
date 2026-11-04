extends AudioStreamPlayer3D
## Scene-owned ambience with quiet gaps and optional player proximity.

@export var trigger_distance: float = 5.0
@export var interval_min: float = 12.0
@export var interval_max: float = 24.0

var _rng := RandomNumberGenerator.new()
var _wait: float = 0.0
var _player: Node3D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if stream == null or interval_min <= 0.0 or interval_max < interval_min or trigger_distance < 0.0:
		push_warning("IntermittentAmbience %s: missing stream or invalid timing/distance." % name)
		set_process(false)
		return
	# Imported loops must finish before scheduling the next quiet gap.
	stream = stream.duplicate()
	if stream is AudioStreamMP3:
		stream.loop = false
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	_rng.randomize()
	_wait = _rng.randf_range(1.0, 3.0)
	finished.connect(_schedule_next)
	GlobalTimer.storm_arrived.connect(stop)


func _process(delta: float) -> void:
	if SceneManager.storm_transition_pending or SceneManager.is_travelling:
		stop()
		return
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
	if not is_instance_valid(_player):
		stop()
		return
	if trigger_distance > 0.0 and global_position.distance_squared_to(_player.global_position) > trigger_distance * trigger_distance:
		if playing:
			stop()
			_schedule_next()
		return
	if playing:
		return
	_wait -= delta
	if _wait <= 0.0:
		play()


func _schedule_next() -> void:
	_wait = _rng.randf_range(interval_min, interval_max)
