# AudioManager.gd
extends Node

# ── PLAYERS ───────────────────────────────────────────────────────────────────
# One dedicated player per bus so they never stomp each other.
@onready var _music_player:    AudioStreamPlayer = $MusicPlayer
@onready var _ambience_player: AudioStreamPlayer = $AmbiencePlayer
@onready var _sfx_player:      AudioStreamPlayer = $SFXPlayer
@onready var _voice_player:    AudioStreamPlayer = $VoicePlayer

# ── FADE STATE ────────────────────────────────────────────────────────────────
var _music_tween:    Tween = null
var _ambience_tween: Tween = null
var _sfx_tween: Tween = null

const FADE_DURATION: float = 1.5   # seconds for crossfade

# ── PUBLIC API ────────────────────────────────────────────────────────────────

## Play a background music track, with optional fade-in.
func play_music(stream: AudioStream, fade_in: bool = true) -> void:
	if _music_player.stream == stream and _music_player.playing:
		return   # already playing this track — do nothing
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	_music_player.stream    = stream
	_music_player.volume_db = -80.0 if fade_in else 0.0
	_music_player.play()
	if fade_in:
		_music_tween = create_tween()
		_music_tween.tween_property(_music_player, "volume_db", 0.0, FADE_DURATION)

## Stop music, with optional fade-out.
func stop_music(fade_out: bool = true) -> void:
	if not _music_player.playing:
		return
	if fade_out:
		_music_tween = create_tween()
		_music_tween.tween_property(_music_player, "volume_db", -80.0, FADE_DURATION)
		await _music_tween.finished
	_music_player.stop()

## Play a looping ambience layer.
func play_ambience(stream: AudioStream, fade_in: bool = true) -> void:
	if _ambience_player.stream == stream and _ambience_player.playing:
		return
	if _ambience_tween and _ambience_tween.is_valid():
		_ambience_tween.kill()
	_ambience_player.stream    = stream
	_ambience_player.volume_db = -80.0 if fade_in else 0.0
	_ambience_player.play()
	if fade_in:
		_ambience_tween = create_tween()
		_ambience_tween.tween_property(_ambience_player, "volume_db", 0.0, FADE_DURATION)

## Stop ambience.
func stop_ambience(fade_out: bool = true) -> void:
	if not _ambience_player.playing:
		return
	if fade_out:
		_ambience_tween = create_tween()
		_ambience_tween.tween_property(_ambience_player, "volume_db", -80.0, FADE_DURATION)
		await _ambience_tween.finished
	_ambience_player.stop()

## Fire a one-shot SFX. Safe to call from anywhere.
func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		push_warning("AudioManager.play_sfx: null stream passed")
		return
	_sfx_player.volume_db = volume_db
	_sfx_player.stream    = stream
	_sfx_player.play()

## Fire a one-shot voice/talking sound.
func play_voice(stream: AudioStream) -> void:
	if stream == null:
		return
	_voice_player.stream = stream
	_voice_player.play()

func stop_voice() -> void:
	_voice_player.stop()
	
func stop_sfx(fade_out: bool = true) -> void:
	if fade_out:
		_sfx_tween = create_tween()
		_sfx_tween.tween_property(_sfx_player, "volume_db", -10.0, FADE_DURATION)
		await _sfx_tween.finished
	_sfx_player.stop()

## Hard-stop everything — used on scene restart.
func stop_all() -> void:
	stop_music(false)
	stop_ambience(false)
	_sfx_player.stop()
	_voice_player.stop()
