extends RefCounted

const UI_HOVER: AudioStream = preload("res://game/assets/sfx/musicholder-hover-button-287656.mp3")
const UI_CLICK: AudioStream = preload("res://game/assets/sfx/universfield-button-124476.mp3")
const UI_CANCEL: AudioStream = preload("res://game/assets/sfx/nomagician-ui-button-sound-cancel-back-exit-continue-467877.mp3")
const UI_ERROR: AudioStream = preload("res://game/assets/sfx/universfield-error-010-206498.mp3")

const CASH_GAIN: AudioStream = preload("res://game/assets/sfx/floraphonic-coin-and-money-bag-3-185264.mp3")
const PURCHASE_SUCCESS: AudioStream = preload("res://game/assets/sfx/ksjsbwuil-cash-register-1-513922.mp3")
const SHOP_BEEP: AudioStream = preload("res://game/assets/sfx/cartoon-music-game-sfx-cash-register-scanner-single-beep-494483.mp3")
const ITEM_TOUCH: AudioStream = preload("res://game/assets/sfx/freesound_community-put_item-83043.mp3")
const INVENTORY_OPEN: AudioStream = preload("res://game/assets/sfx/270393__littlerobotsoundfactory__inventory_open_00.wav")
const INVENTORY_CLOSE: AudioStream = preload("res://game/assets/sfx/568991__fission9__inventory-close.wav")
const MAP_OPEN: AudioStream = preload("res://game/assets/sfx/freesound_crunchpixstudio-open-map-384948.mp3")
const WATER_FILL: AudioStream = preload("res://game/assets/sfx/universfield-water-191999.mp3")
const HAMMER: AudioStream = preload("res://game/assets/sfx/freesound_community-hammeringroof-94320.mp3")
const WIND_GUST: AudioStream = preload("res://game/assets/sfx/dragon-studio-gust-of-wind-511325.mp3")
const THUNDER_DISTANT: AudioStream = preload("res://game/assets/sfx/freesound_community-027958_distant-thunderwav-79709.mp3")
const THUNDER_CLOSE: AudioStream = preload("res://game/assets/sfx/u_vrs223ln83-loud-thunder-439064.mp3")

static func play(stream: AudioStream, volume_db: float = -6.0, pitch_variation: float = 0.0) -> void:
	if Engine.is_editor_hint() or stream == null:
		return
	var pitch := 1.0
	if pitch_variation > 0.0:
		pitch = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	AudioManager.play_sfx(stream, volume_db, pitch)

static func ui_hover() -> void: play(UI_HOVER, -20.0, 0.03)
static func ui_click() -> void: play(UI_CLICK, -12.0, 0.03)
static func ui_cancel() -> void: play(UI_CANCEL, -12.0, 0.02)
static func ui_error() -> void: play(UI_ERROR, -10.0, 0.02)
static func cash_gain() -> void: play(CASH_GAIN, -7.0, 0.02)
static func purchase_success() -> void: play(PURCHASE_SUCCESS, -8.0, 0.02)
static func shop_beep() -> void: play(SHOP_BEEP, -12.0, 0.02)
static func item_touch(volume_db: float = -10.0) -> void: play(ITEM_TOUCH, volume_db, 0.05)
static func inventory_open() -> void: play(INVENTORY_OPEN, -10.0, 0.02)
static func inventory_close() -> void: play(INVENTORY_CLOSE, -10.0, 0.02)
static func map_open() -> void: play(MAP_OPEN, -10.0, 0.02)
static func water_fill() -> void: play(WATER_FILL, -8.0, 0.02)
static func hammer() -> void: play(HAMMER, -9.0, 0.02)
static func thunder_close(volume_db: float = -8.0) -> void: play(THUNDER_CLOSE, volume_db, 0.04)
static func thunder_distant(volume_db: float = -16.0) -> void: play(THUNDER_DISTANT, volume_db, 0.05)
static func wind_gust(volume_db: float = -15.0) -> void: play(WIND_GUST, volume_db, 0.05)

static func wire_button(button: Button, cancel: bool = false) -> void:
	if button == null or button.has_meta("sfx_wired"):
		return
	button.set_meta("sfx_wired", true)
	button.mouse_entered.connect(func() -> void: ui_hover())
	button.pressed.connect(func() -> void:
		if cancel:
			ui_cancel()
		else:
			ui_click()
	)
