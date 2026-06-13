extends Node

const SFX = preload("res://game/audio/Sfx.gd")

const LIGHT_RAIN: AudioStream = preload("res://game/assets/sfx/523722__klankbeeld__room-tone-wind-rain-long-200216_0114.ogg")
const WIND: AudioStream = preload("res://game/assets/sfx/jci-21-wind-blowing-sfx-12809.mp3")
const HEAVY_STORM: AudioStream = preload("res://game/assets/sfx/soundreality-rain-thunder-sfx-525011.mp3")
const LOW_RUMBLE: AudioStream = preload("res://game/assets/sfx/u_7hpxkdroz2-storm-461601.mp3")
const TRAIN_ANNOUNCEMENT: AudioStream = preload("res://game/assets/sfx/freesound_community-057519_train-announcement-44505.mp3")

var _rain_player: AudioStreamPlayer
var _wind_player: AudioStreamPlayer
var _heavy_player: AudioStreamPlayer
var _rumble_player: AudioStreamPlayer
var _train_player: AudioStreamPlayer
var _one_shot_timer: float = 0.0
var _fade_tweens: Dictionary = {}

func _ready() -> void:
	_rain_player = _make_loop_player(LIGHT_RAIN, "StormLightRain")
	_wind_player = _make_loop_player(WIND, "StormWind")
	_heavy_player = _make_loop_player(HEAVY_STORM, "StormHeavyRain")
	_rumble_player = _make_loop_player(LOW_RUMBLE, "StormLowRumble")
	_train_player = _make_loop_player(TRAIN_ANNOUNCEMENT, "GroceryTrainAnnouncement")
	_train_player.volume_db = -80.0

	GlobalTimer.time_updated.connect(func(_minute: int) -> void: _update_layers())
	GlobalTimer.encroachment_threshold_reached.connect(func(_zone: String) -> void: _update_layers(true))
	GlobalTimer.storm_arrived.connect(func() -> void: _update_layers(true))
	StormEnroachment.location_state_changed.connect(func(_loc: String, _state: String) -> void: _update_layers(true))
	SceneManager.travel_completed.connect(func(_loc: String) -> void: _update_layers(true))
	_update_layers()

func _process(delta: float) -> void:
	_one_shot_timer -= delta
	if _one_shot_timer > 0.0:
		return
	var progress: float = GlobalTimer.get_storm_progress()
	if progress < 0.32 or not _should_play_layers():
		_one_shot_timer = 6.0
		return
	var is_ending_scene := _is_ending_scene()
	if randf() < clamp(progress, 0.25, 0.85):
		if progress > 0.72 and randf() < 0.35:
			SFX.thunder_close(-13.0)
		elif randf() < 0.55:
			SFX.thunder_distant(-18.0)
		elif not is_ending_scene:
			SFX.wind_gust(-18.0)
	if SceneManager.current_location == "grocery" and randf() < 0.35:
		SFX.shop_beep()
	_one_shot_timer = randf_range(10.0, 22.0) * lerpf(1.0, 0.55, progress)

func _make_loop_player(stream: AudioStream, player_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = "Ambience"
	player.stream = stream
	player.volume_db = -80.0
	add_child(player)
	player.play()
	return player

func _should_play_layers() -> bool:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return false
	var scene_path := tree.current_scene.scene_file_path
	return scene_path.contains("/locations/") or scene_path.contains("/ending/")

func _is_ending_scene() -> bool:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return false
	return tree.current_scene.scene_file_path.contains("/ending/")

func _update_layers(force: bool = false) -> void:
	var progress: float = GlobalTimer.get_storm_progress()
	var active: bool = _should_play_layers()
	var location: String = SceneManager.current_location
	var state: String = StormEnroachment.get_state(location)
	var danger_boost: float = 0.18 if state == "danger" else (0.30 if state == "inaccessible" else 0.0)
	var intensity: float = clampf(progress + danger_boost + _location_bias(location), 0.0, 1.0)
	if not active:
		intensity = 0.0

	_fade_to(_rain_player, linear_to_db(lerpf(0.001, 0.28, smoothstep(0.18, 0.72, intensity))) if intensity > 0.18 else -80.0, force)
	_fade_to(_wind_player, linear_to_db(lerpf(0.001, 0.22, smoothstep(0.35, 0.86, intensity))) if intensity > 0.35 else -80.0, force)
	_fade_to(_heavy_player, linear_to_db(lerpf(0.001, 0.34, smoothstep(0.58, 1.0, intensity))) if intensity > 0.58 else -80.0, force)
	_fade_to(_rumble_player, linear_to_db(lerpf(0.001, 0.18, smoothstep(0.70, 1.0, intensity))) if intensity > 0.70 else -80.0, force)
	_fade_to(_train_player, -18.0 if active and location == "grocery" else -80.0, force)

func _location_bias(location: String) -> float:
	match location:
		"grocery":
			return 0.18
		"pharmacy", "hardware":
			return 0.08
		"ate_linda", "tindahan":
			return 0.04
		_:
			return 0.0

func _fade_to(player: AudioStreamPlayer, volume_db: float, immediate: bool = false) -> void:
	if player == null:
		return
	if is_equal_approx(player.volume_db, volume_db):
		return
	var previous_tween := _fade_tweens.get(player) as Tween
	if previous_tween != null and previous_tween.is_valid():
		previous_tween.kill()
	if immediate:
		player.volume_db = volume_db
		_fade_tweens.erase(player)
		return
	var tween := create_tween()
	_fade_tweens[player] = tween
	tween.tween_property(player, "volume_db", volume_db, 1.25)
	tween.finished.connect(func() -> void:
		if _fade_tweens.get(player) == tween:
			_fade_tweens.erase(player)
	)
