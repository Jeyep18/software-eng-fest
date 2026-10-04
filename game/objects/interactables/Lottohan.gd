extends Interactable

@onready var _lotto_ui: ScratchLottoUI = $LottoUI


func _ready() -> void:
	super._ready()
	_lotto_ui.closed.connect(_on_lotto_closed)


func interact() -> void:
	if not is_interaction_available() or ShopUi.is_open():
		return
	_lotto_ui.open_ui()
	if _lotto_ui.is_open():
		is_showing = true
		prompt_visibility_changed.emit(false)


func is_interaction_available() -> bool:
	return not is_showing and not SceneManager.storm_transition_pending


func _on_lotto_closed() -> void:
	is_showing = false
	prompt_visibility_changed.emit(true)
