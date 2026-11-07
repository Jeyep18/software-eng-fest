extends Node

const AMBIENCE = preload("res://game/audio/IntermittentAmbience.gd")
const SCARY: AudioStream = preload("res://game/assets/audio/music/freesound_community-scary-ambience-59002.mp3")
const ENDING: AudioStream = preload("res://game/scenes/ending/EndingSequence.gd").ENDING_MUSIC
const BARK: AudioStream = preload("res://game/assets/audio/gameplay/dragon-studio-free-dog-bark-419014.mp3")

var _checks := 0
var _failures := 0

class ControlledEnding extends "res://game/scenes/ending/EndingSequence.gd":
	func _start() -> void:
		pass

class SmokePlayerFixture extends Node3D:
	var locked := false
	func set_movement_locked(value: bool) -> void:
		locked = value


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("AUDIO FAIL: " + description)


func _run() -> void:
	if OS.get_environment("BAGYONG_ISOLATED_SMOKE") != OS.get_user_data_dir():
		push_error("Audio regression requires isolated user data.")
		get_tree().quit(1)
		return
	get_tree().current_scene = null
	TutorialModal.mark_do_not_show_again()
	SceneManager.reset()
	GameState.reset()
	GameState.house_tasks_unlocked = true
	GlobalTimer.start_fresh()
	GlobalTimer.pause_timer(self)
	var bus_volumes: Array[float] = []
	for index in AudioServer.bus_count:
		bus_volumes.append(AudioServer.get_bus_volume_db(index))
	await _test_lotto_audio()
	await _test_proximity()
	await _test_locations()
	await _test_smoker()
	await _test_ending_audio()
	for index in AudioServer.bus_count:
		_check(is_equal_approx(AudioServer.get_bus_volume_db(index), bus_volumes[index]), "playback preserves saved bus gain %d" % index)
	AudioManager.stop_all()
	print("Audio regression: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)


func _test_ending_audio() -> void:
	SideQuestLog.start_mang_nestor_chicken()
	var ending := preload("res://game/scenes/ending/EndingSequence.tscn").instantiate()
	ending.set_script(ControlledEnding)
	add_child(ending)
	await get_tree().process_frame
	var storm_player: AudioStreamPlayer = AudioManager._ambience_player
	var music_player: AudioStreamPlayer = AudioManager._music_player
	_check(storm_player.stream != ending.ENDING_STORM and storm_player.stream.loop, "ending loops its own storm stream")
	_check(not ending.ENDING_STORM.loop, "ending leaves the shared storm import unchanged")
	_check(music_player.stream.get_length() <= 36.0, "ending music excludes the fading outro")
	_check(music_player.stream == ENDING and ENDING.loop_mode == AudioStreamWAV.LOOP_FORWARD, "ending uses the authored continuous music loop")
	var model: Node3D = ending.get_node("LocationSets/Tindahan/NestorVisual")
	var animations := model.find_children("*", "AnimationPlayer", true, false)
	_check(model.visible and animations.size() == 1 and animations[0].current_animation == "idle_loop", "unfinished errand shows Nestor with his authored idle animation")
	for player in [storm_player, music_player]:
		player.seek(player.stream.get_length() - 0.15)
	await get_tree().create_timer(0.6).timeout
	_check(storm_player.playing and storm_player.get_playback_position() < 1.0, "ending storm keeps playing across its recording boundary")
	_check(music_player.playing and music_player.get_playback_position() < 1.0, "ending music keeps playing across its loop boundary")
	ending.queue_free()
	await get_tree().process_frame


func _test_lotto_audio() -> void:
	AudioManager.play_music(SCARY, true, -12.0)
	await get_tree().create_timer(AudioManager.FADE_DURATION + 0.1).timeout
	_check(is_equal_approx(AudioManager._music_player.volume_db, -12.0), "scary music fades to reduced track gain")
	var position_before := AudioManager._music_player.get_playback_position()
	var ui := ScratchLottoUI.new()
	add_child(ui)
	ui.open_ui()
	_check(AudioManager._music_player.stream == ui._lotto_music and ui._lotto_music.loop, "lottery owns a looping music track while open")
	_check(ui._scratch_player.bus == &"SFX" and ui._scratch_player.stream.get_length() > 0.0, "scratch sound is imported on SFX")
	var sounds_before := AudioManager.get_child_count()
	_check(not ui.buy_ticket() and AudioManager.get_child_count() == sounds_before, "failed purchase makes no purchase sound")
	GameState.add_cash(1000)
	_check(ui.buy_ticket() and AudioManager.get_child_count() == sounds_before + 1, "successful purchase plays store sound")
	var purchase := AudioManager.get_child(-1) as AudioStreamPlayer
	_check(purchase.stream == preload("res://game/audio/Sfx.gd").PURCHASE_SUCCESS, "lotto uses the exact store purchase stream")
	ui._scratch_all_button.pressed.emit()
	_check(ui._scratch_player.playing and ui._settled, "Scratch All plays scratching and settles ticket")
	ui.request_close()
	_check(not ui._scratch_player.playing, "closing lotto stops its scratch player")
	_check(AudioManager._music_player.stream == SCARY and is_equal_approx(AudioManager._music_player.volume_db, -12.0), "closing lotto restores original track and gain")
	_check(absf(AudioManager._music_player.get_playback_position() - position_before) < 0.25, "closing lotto resumes the previous music position")
	ui.open_ui()
	ui.buy_ticket()
	ui.force_close()
	_check(not ui._scratch_player.playing and AudioManager._music_player.stream == SCARY, "forced close settles silently and restores music")
	ui.open_ui()
	ui.queue_free()
	await get_tree().process_frame
	_check(AudioManager._music_player.stream == SCARY, "scene teardown restores interrupted gameplay music")
	ui = ScratchLottoUI.new()
	add_child(ui)
	ui.open_ui()
	AudioManager.play_music(ENDING, false)
	ui.queue_free()
	await get_tree().process_frame
	_check(AudioManager._music_player.stream == ENDING, "late lotto teardown preserves newer ending music")
	AudioManager.stop_music(false)
	ui = ScratchLottoUI.new()
	add_child(ui)
	ui.open_ui()
	ui.request_close()
	_check(not AudioManager._music_player.playing, "lotto restores silence when no music was playing")
	ui.free()


func _test_proximity() -> void:
	var player := Node3D.new()
	player.add_to_group("player")
	add_child(player)
	var listener := AudioListener3D.new()
	player.add_child(listener)
	listener.make_current()
	player.position = Vector3(50, 0, 0)
	var sound := AMBIENCE.new()
	sound.stream = BARK
	sound.bus = "Ambience"
	add_child(sound)
	sound.set_process(false)
	_check(sound.stream != BARK and not sound.stream.loop, "ambience duplicates imports and disables looping per instance")
	sound._wait = 0.0
	sound._process(1.0)
	_check(not sound.playing, "nearby bark remains silent outside player range")
	player.position = Vector3.ZERO
	sound._process(0.1)
	_check(sound.playing, "bark starts near the player")
	sound.play(maxf(sound.stream.get_length() - 0.05, 0.0))
	var finish_deadline := Time.get_ticks_msec() + 2000
	while sound.playing and Time.get_ticks_msec() < finish_deadline:
		await get_tree().process_frame
	_check(not sound.playing and sound._wait >= sound.interval_min, "finished bark schedules a quiet gap instead of looping")
	sound._process(sound._wait + 0.1)
	_check(sound.playing, "scheduled quiet gap expires and starts a second bark")
	player.position = Vector3(50, 0, 0)
	sound._process(0.1)
	_check(not sound.playing and sound._wait >= sound.interval_min, "leaving range stops the sound and schedules a quiet gap")
	player.position = Vector3.ZERO
	for index in 10:
		sound._schedule_next()
		_check(sound._wait >= sound.interval_min and sound._wait <= sound.interval_max, "random gap stays within bounds %d" % index)
	sound._wait = 2.0
	sound.set_process(true)
	get_tree().paused = true
	await get_tree().create_timer(0.08).timeout
	_check(is_equal_approx(sound._wait, 2.0), "scene pause freezes ambience scheduling")
	get_tree().paused = false
	await get_tree().create_timer(0.08).timeout
	_check(sound._wait < 2.0, "ambience resumes after unpause")
	sound.set_process(false)
	sound._wait = 0.0
	sound._process(0.1)
	SceneManager.is_travelling = true
	sound._process(0.1)
	_check(not sound.playing, "travel stops local ambience")
	SceneManager.is_travelling = false
	SceneManager.storm_transition_pending = true
	sound._process(100.0)
	_check(not sound.playing, "pending storm blocks ambience restart")
	SceneManager.storm_transition_pending = false
	sound.trigger_distance = 0.0
	player.position = Vector3(50, 0, 0)
	sound._wait = 0.0
	sound._process(0.1)
	_check(sound.playing, "distant bark can play across an outdoor map")
	var sound_ref: WeakRef = weakref(sound)
	sound.free()
	_check(sound_ref.get_ref() == null, "scene-owned ambience is freed with its owner")
	player.free()


func _test_locations() -> void:
	var cat_streams: Dictionary = {}
	var animal_count := 0
	for location in ["home", "grocery", "hardware", "pharmacy", "tindahan"]:
		var scene := (load(SceneManager.SCENE_PATHS[location]) as PackedScene).instantiate()
		add_child(scene)
		for frame in 4:
			await get_tree().process_frame
		for sound in scene.get_node("AmbientSounds").get_children():
			if sound is AudioStreamPlayer3D:
				_check(sound.bus == &"Ambience", "%s/%s respects Ambience slider" % [location, sound.name])
				_check(sound.volume_db <= 0.0, "%s/%s has no positive gain boost" % [location, sound.name])
		if location != "home":
			var distant := scene.get_node("AmbientSounds/DistantDog")
			_check(distant.get_script() == AMBIENCE and distant.trigger_distance == 0.0 and distant.interval_min == 10.0 and distant.interval_max == 20.0 and distant.volume_db == -3.0, location + " has more frequent audible distant barking")
		else:
			_check(AudioManager.get_music_state()["volume_db"] == -12.0, "production home requests quieter scary music")
		if scene.has_node("AmbientAnimals"):
			for animal in scene.get_node("AmbientAnimals").get_children():
				animal_count += 1
				var sounds := animal.find_children("*", "AudioStreamPlayer3D", true, false)
				_check(sounds.size() == 1 and sounds[0].get_script() == AMBIENCE, "%s/%s owns proximity audio" % [location, animal.name])
				_check(sounds[0].stream.get_length() > 0.0, "%s/%s has imported animal audio" % [location, animal.name])
				_check(sounds[0].interval_min >= 4.0 and sounds[0].interval_max <= 12.0, "%s/%s repeats with shorter quiet gaps" % [location, animal.name])
				_check(sounds[0].volume_db >= -3.0 and sounds[0].unit_size >= 3.0, "%s/%s has stronger nearby audio" % [location, animal.name])
				if animal.species == AmbientAnimal.Species.CAT:
					cat_streams[sounds[0].stream.get_class()] = true
				else:
					_check(sounds[0].interval_max > sounds[0].interval_min, "dog barks have varied intervals")
		scene.queue_free()
		await get_tree().process_frame
	_check(animal_count == 5 and cat_streams.size() == 2, "all five animals have sound and cats use both WAV purring and MP3 meowing")


func _test_smoker() -> void:
	SceneManager.reset()
	GlobalTimer.start_fresh()
	GlobalTimer.pause_timer(self)
	var scene := preload("res://game/entities/npcs/quests/smoke_break_npc.tscn").instantiate()
	add_child(scene)
	var npc := scene.get_node("Area3D")
	var accepted: AudioStreamPlayer = npc.get_node("SmokeAccepted")
	var ambient := scene.get_node("SmokingAmbience")
	_check(accepted.stream.get_length() > 0.0 and ambient.stream.get_length() > 0.0, "both smoker sounds are imported")
	_check(accepted.bus == &"SFX" and ambient.bus == &"Ambience" and ambient.trigger_distance == 3.0, "smoker acceptance and nearby ambience use separate channels")
	npc._on_choice_declined()
	_check(not accepted.playing and not GameState.tindahan_smoke_break_taken, "declining smoking does not play acceptance SFX")
	var player := SmokePlayerFixture.new()
	player.add_to_group("player")
	add_child(player)
	var minutes_before := GlobalTimer.current_minutes
	npc._pending_smoke = true
	npc._on_choice_accepted()
	_check(accepted.playing and GameState.tindahan_smoke_break_taken, "accepting smoking plays the one-shot")
	await get_tree().create_timer(4.0).timeout
	_check(GlobalTimer.current_minutes == minutes_before + npc.time_cost_minutes, "smoke audio preserves existing time cost")
	_check(accepted.playing and is_equal_approx(TransitionOverlay.overlay.color.a, 1.0) and player.locked, "smoking stays black and movement stays locked while the recording plays")
	var stayed_black := true
	var deadline := Time.get_ticks_msec() + int(accepted.stream.get_length() * 1000.0) + 2000
	while accepted.playing and Time.get_ticks_msec() < deadline:
		stayed_black = stayed_black and is_equal_approx(TransitionOverlay.overlay.color.a, 1.0) and player.locked
		await get_tree().process_frame
	_check(not accepted.playing and stayed_black, "blackout lasts through the entire smoke recording")
	while npc._pending_smoke and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	_check(not npc._pending_smoke and not player.locked and is_zero_approx(TransitionOverlay.overlay.color.a), "smoke completion fades back and releases movement")
	npc._on_choice_accepted()
	_check(not accepted.playing, "repeated acceptance cannot replay one-time smoking sound")
	scene.free()
	player.free()
