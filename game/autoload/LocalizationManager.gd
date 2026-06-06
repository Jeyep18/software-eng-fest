extends Node

signal language_changed(language_id: String)

const LANGUAGE_ENGLISH: String = "english"
const LANGUAGE_TAGALOG: String = "tagalog"
const SETTINGS_PATH: String = "user://language_settings.cfg"
const TEXT_CSV_PATH: String = "res://game/localization/game_text.csv"

const LANGUAGE_LABELS: Dictionary = {
	LANGUAGE_ENGLISH: "English",
	LANGUAGE_TAGALOG: "Tagalog",
}

var current_language: String = LANGUAGE_ENGLISH
var _english_by_source: Dictionary = {}
var _tagalog_by_source: Dictionary = {}
var _english_by_key: Dictionary = {}
var _tagalog_by_key: Dictionary = {}


func _ready() -> void:
	_load_text_table()
	_load_settings()
	if not language_changed.is_connected(_on_language_changed):
		language_changed.connect(_on_language_changed)
	if get_tree() != null and not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added)
	call_deferred("localize_tree", get_tree().root)


func set_language(language_id: String) -> void:
	if not LANGUAGE_LABELS.has(language_id):
		language_id = LANGUAGE_ENGLISH
	if current_language == language_id:
		return
	current_language = language_id
	_save_settings()
	language_changed.emit(current_language)


func get_language() -> String:
	return current_language


func get_language_index() -> int:
	return 1 if current_language == LANGUAGE_TAGALOG else 0


func get_language_from_index(index: int) -> String:
	return LANGUAGE_TAGALOG if index == 1 else LANGUAGE_ENGLISH


func translate(text: String) -> String:
	if text.is_empty():
		return text
	if current_language == LANGUAGE_TAGALOG:
		return _tagalog_by_source.get(text, text)
	return _english_by_source.get(text, text)


func translate_key(key: String, fallback_text: String = "") -> String:
	if key.is_empty():
		return fallback_text
	var fallback := fallback_text if not fallback_text.is_empty() else key
	if current_language == LANGUAGE_TAGALOG:
		return _tagalog_by_key.get(key, fallback)
	return _english_by_key.get(key, fallback)


func trf(text: String, values: Array) -> String:
	return translate(text) % values


func trfk(key: String, values: Array, fallback_text: String = "") -> String:
	return translate_key(key, fallback_text) % values


func localize_tree(root: Node) -> void:
	if root == null:
		return
	_localize_node(root)
	for child in root.get_children():
		localize_tree(child)


func _load_text_table() -> void:
	_english_by_source.clear()
	_tagalog_by_source.clear()
	_english_by_key.clear()
	_tagalog_by_key.clear()

	if not FileAccess.file_exists(TEXT_CSV_PATH):
		push_warning("LocalizationManager: missing text table at " + TEXT_CSV_PATH)
		return

	var file := FileAccess.open(TEXT_CSV_PATH, FileAccess.READ)
	if file == null:
		push_warning("LocalizationManager: could not open text table at " + TEXT_CSV_PATH)
		return

	var header := file.get_csv_line()
	var column_index := _get_column_index(header)
	var required_columns := ["key", "source_text", "english", "tagalog"]
	for column in required_columns:
		if not column_index.has(column):
			push_warning("LocalizationManager: text table is missing column '" + column + "'.")
			return

	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.is_empty() or (row.size() <= 1 and str(row[0]).strip_edges().is_empty()):
			continue

		var key := _csv_value(row, column_index, "key")
		var source_text := _csv_value(row, column_index, "source_text")
		var english_text := _csv_value(row, column_index, "english")
		var tagalog_text := _csv_value(row, column_index, "tagalog")
		if source_text.is_empty():
			continue

		if english_text.is_empty():
			english_text = source_text
		if tagalog_text.is_empty():
			tagalog_text = source_text

		_english_by_source[source_text] = english_text
		_tagalog_by_source[source_text] = tagalog_text
		if not key.is_empty():
			_english_by_key[key] = english_text
			_tagalog_by_key[key] = tagalog_text


func _get_column_index(header: PackedStringArray) -> Dictionary:
	var column_index := {}
	for i in header.size():
		column_index[str(header[i]).strip_edges()] = i
	return column_index


func _csv_value(row: PackedStringArray, column_index: Dictionary, column_name: String) -> String:
	var index := int(column_index[column_name])
	if index < 0 or index >= row.size():
		return ""
	return str(row[index])


func _on_node_added(node: Node) -> void:
	_localize_node.call_deferred(node)


func _on_language_changed(_language_id: String) -> void:
	localize_tree(get_tree().root)


func _localize_node(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	_localize_property(node, "text")
	_localize_property(node, "placeholder_text")
	_localize_property(node, "tooltip_text")


func _localize_property(node: Node, property_name: StringName) -> void:
	var source_meta := "_localization_source_" + str(property_name)
	var current_value: Variant = node.get(property_name)
	if typeof(current_value) != TYPE_STRING:
		return

	var current_text := str(current_value)
	var source_text := current_text
	if node.has_meta(source_meta):
		source_text = str(node.get_meta(source_meta))
		if current_text != translate(source_text) and _has_translation(current_text):
			source_text = current_text
			node.set_meta(source_meta, source_text)
	elif _has_translation(current_text):
		node.set_meta(source_meta, current_text)
	else:
		return

	var translated := translate(source_text)
	if translated != current_text:
		node.set(property_name, translated)


func _has_translation(text: String) -> bool:
	return _english_by_source.has(text) or _tagalog_by_source.has(text)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		current_language = LANGUAGE_ENGLISH
		return
	current_language = str(config.get_value("language", "current", LANGUAGE_ENGLISH))
	if not LANGUAGE_LABELS.has(current_language):
		current_language = LANGUAGE_ENGLISH


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("language", "current", current_language)
	config.save(SETTINGS_PATH)
