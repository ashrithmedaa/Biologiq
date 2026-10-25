extends Node
## Single-slot encrypted save storage for native and Godot Web exports.
## Game systems can register a provider implementing capture_save_state() and
## restore_save_state(data), or call set_save_state() directly.

signal status_changed(message: String, is_error: bool)
signal save_loaded(data: Dictionary)
signal save_created(data: Dictionary)

const SAVE_PATH := "user://slot_1.sav"
const IMPORT_TEMP_PATH := "user://slot_1_import.tmp"
const SLOT_ID := "slot_1"
const SAVE_VERSION := 1
const AUTOSAVE_INTERVAL_SECONDS := 120.0
const MAX_SAVE_BYTES := 8 * 1024 * 1024

# This is a format key, not a secret. Godot's password encryption is suitable
# for keeping saves non-plaintext and deterring casual editing; a key embedded
# in a client-side game cannot protect against a determined reverse engineer.
const SAVE_PASSWORD := "Biologiq-Save-Format-v1-Change-Before-Release"

var _current_state: Dictionary = {}
var _state_provider: Object
var _autosave_timer: Timer
var _playtime_remainder := 0.0
var _room_return_position := Vector2.ZERO
var _has_room_return_position := false

# Keep every JS callback and object alive for as long as browser JS can call it.
var _active_file_input: JavaScriptObject
var _active_file_reader: JavaScriptObject
var _file_picker_callback: JavaScriptObject
var _file_picker_cancel_callback: JavaScriptObject
var _file_reader_load_callback: JavaScriptObject
var _file_reader_error_callback: JavaScriptObject


func _ready() -> void:
	_current_state = _default_save_data()
	_autosave_timer = Timer.new()
	_autosave_timer.name = "SaveAutosaveTimer"
	_autosave_timer.wait_time = AUTOSAVE_INTERVAL_SECONDS
	_autosave_timer.one_shot = false
	_autosave_timer.timeout.connect(_on_autosave_timeout)
	add_child(_autosave_timer)
	_autosave_timer.start()


func _process(delta: float) -> void:
	_playtime_remainder += delta
	if _playtime_remainder >= 1.0:
		var elapsed_seconds := int(_playtime_remainder)
		_playtime_remainder -= float(elapsed_seconds)
		_current_state["playtime"] = int(_current_state.get("playtime", 0)) + elapsed_seconds


func register_state_provider(provider: Object) -> void:
	## Provider contract: capture_save_state() -> Dictionary and
	## restore_save_state(data: Dictionary). Pass null to unregister.
	_state_provider = provider


func set_save_state(data: Dictionary) -> void:
	## Set the complete game state that will be persisted in slot_1.
	_current_state = _normalize_save_data(data)


func get_save_state() -> Dictionary:
	return _deep_copy_dictionary(_current_state)


func remember_room_entry_position(position: Vector2) -> void:
	_room_return_position = position
	_has_room_return_position = true


func take_room_return_position(fallback: Vector2) -> Vector2:
	if not _has_room_return_position:
		return fallback
	_has_room_return_position = false
	return _room_return_position


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func get_slot_summary() -> Dictionary:
	## Read-only metadata for the save selector; does not restore gameplay state.
	if not FileAccess.file_exists(SAVE_PATH):
		return {"exists": false}
	var file := FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.READ, SAVE_PASSWORD)
	if file == null:
		return {"exists": true, "valid": false}
	if file.get_length() <= 0 or file.get_length() > MAX_SAVE_BYTES:
		file.close()
		return {"exists": true, "valid": false}
	var json_text := file.get_as_text()
	file.close()
	var parser := JSON.new()
	if parser.parse(json_text) != OK or not parser.data is Dictionary:
		return {"exists": true, "valid": false}
	var data: Dictionary = parser.data
	if not _validate_save_data(data):
		return {"exists": true, "valid": false}
	return {
		"exists": true,
		"valid": true,
		"timestamp": str(data.get("timestamp", "Unknown time")),
		"playtime": int(data.get("playtime", 0)),
		"imported": bool(data.get("imported_from_file", false)),
	}


func create_new_save(initial_state: Dictionary = {}) -> bool:
	var fresh := _default_save_data()
	if not initial_state.is_empty():
		fresh.merge(initial_state, true)
	_current_state = _normalize_save_data(fresh)
	_current_state["imported_from_file"] = false
	_playtime_remainder = 0.0
	_current_state["timestamp"] = _timestamp_now()
	if _state_provider != null and is_instance_valid(_state_provider) and _state_provider.has_method("restore_save_state"):
		_state_provider.call("restore_save_state", _deep_copy_dictionary(_current_state))
	save_created.emit(_deep_copy_dictionary(_current_state))
	return save_slot()


func delete_uploaded_save() -> bool:
	## Remove the imported slot so the player can select a replacement file.
	var summary := get_slot_summary()
	if not bool(summary.get("valid", false)) or not bool(summary.get("imported", false)):
		status_changed.emit("There is no uploaded save to remove.", true)
		return false
	var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if remove_error != OK:
		status_changed.emit("Could not remove the uploaded save. Try again.", true)
		return false
	_current_state = _default_save_data()
	if _state_provider != null and is_instance_valid(_state_provider) and _state_provider.has_method("restore_save_state"):
		_state_provider.call("restore_save_state", _deep_copy_dictionary(_current_state))
	status_changed.emit("Uploaded save removed. You can choose another file.", false)
	return true


func save_slot() -> bool:
	var payload := _capture_current_state()
	if payload.is_empty():
		status_changed.emit("Save failed: game state must be a dictionary.", true)
		return false
	payload["save_version"] = SAVE_VERSION
	payload["slot_id"] = SLOT_ID
	payload["timestamp"] = _timestamp_now()
	_current_state = _normalize_save_data(payload)
	var json_text := JSON.stringify(_to_json_safe(_current_state))
	if json_text.is_empty():
		status_changed.emit("Save failed: the game state could not be serialized.", true)
		return false
	if json_text.to_utf8_buffer().size() > MAX_SAVE_BYTES - 128:
		status_changed.emit("Save failed: the game state is larger than the 8 MB save limit.", true)
		return false
	var file := FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.WRITE, SAVE_PASSWORD)
	if file == null:
		status_changed.emit("Save failed: local browser storage could not be opened.", true)
		return false
	file.store_string(json_text)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		status_changed.emit("Save failed: the encrypted save could not be written.", true)
		return false
	status_changed.emit("Save stored locally · " + str(_current_state["timestamp"]), false)
	return true


func load_slot() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		status_changed.emit("No local save exists yet. Create a new save or upload one.", true)
		return false
	var file := FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.READ, SAVE_PASSWORD)
	if file == null:
		status_changed.emit("The local save could not be decrypted. It may be damaged.", true)
		return false
	if file.get_length() <= 0 or file.get_length() > MAX_SAVE_BYTES:
		file.close()
		status_changed.emit("The local save is empty or larger than the supported limit.", true)
		return false
	var json_text := file.get_as_text()
	var read_error := file.get_error()
	file.close()
	if read_error != OK and read_error != ERR_FILE_EOF:
		status_changed.emit("The local save could not be read.", true)
		return false
	return _apply_json_save(json_text)


func export_save_to_file() -> bool:
	## Encrypts the current state first, then downloads the resulting ciphertext.
	if not save_slot():
		return false
	if not OS.has_feature("web"):
		status_changed.emit("Browser download is available in the Web export.", true)
		return false
	if not FileAccess.file_exists(SAVE_PATH):
		status_changed.emit("Download failed: the encrypted save file is missing.", true)
		return false
	var buffer := FileAccess.get_file_as_bytes(SAVE_PATH)
	if buffer.is_empty():
		status_changed.emit("Download failed: the encrypted save is empty.", true)
		return false
	JavaScriptBridge.download_buffer(buffer, "rpg_save.sav", "application/octet-stream")
	status_changed.emit("Encrypted save download started.", false)
	return true


func import_save_from_file() -> bool:
	## Opens a browser file picker. The .json extension is accepted for the
	## requested picker UX, but plaintext JSON is rejected during validation.
	if not OS.has_feature("web"):
		status_changed.emit("Upload is available in the Web export.", true)
		return false
	if _active_file_input != null:
		status_changed.emit("A save upload is already in progress.", true)
		return false
	var document := JavaScriptBridge.get_interface("document")
	if document == null:
		status_changed.emit("The browser file picker is unavailable.", true)
		return false
	_active_file_input = document.createElement("input")
	_active_file_input.type = "file"
	_active_file_input.accept = ".sav,.json,application/octet-stream,application/json"
	_active_file_input.style.display = "none"
	_file_picker_callback = JavaScriptBridge.create_callback(_on_file_picker_changed)
	_file_picker_cancel_callback = JavaScriptBridge.create_callback(_on_file_picker_cancelled)
	_active_file_input.onchange = _file_picker_callback
	_active_file_input.oncancel = _file_picker_cancel_callback
	document.body.appendChild(_active_file_input)
	_active_file_input.click()
	status_changed.emit("Choose an encrypted RPG save file to upload.", false)
	return true


func _on_file_picker_changed(args: Array) -> void:
	if args.is_empty() or _active_file_input == null:
		_cleanup_browser_upload()
		return
	var files = _active_file_input.files
	if files == null or files.length == 0:
		_cleanup_browser_upload()
		status_changed.emit("No file selected.", false)
		return
	var selected_file = files[0]
	if int(selected_file.size) <= 0 or int(selected_file.size) > MAX_SAVE_BYTES:
		_cleanup_browser_upload()
		status_changed.emit("Upload failed: choose a non-empty save under 8 MB.", true)
		return
	_active_file_reader = JavaScriptBridge.create_object("FileReader")
	_file_reader_load_callback = JavaScriptBridge.create_callback(_on_file_reader_loaded)
	_file_reader_error_callback = JavaScriptBridge.create_callback(_on_file_reader_failed)
	_active_file_reader.onload = _file_reader_load_callback
	_active_file_reader.onerror = _file_reader_error_callback
	_active_file_reader.readAsArrayBuffer(selected_file)


func _on_file_reader_loaded(args: Array) -> void:
	if args.is_empty() or _active_file_reader == null:
		_cleanup_browser_upload()
		status_changed.emit("Upload failed: the selected file could not be read.", true)
		return
	var result = _active_file_reader.result
	if result == null or not JavaScriptBridge.is_js_buffer(result):
		_cleanup_browser_upload()
		status_changed.emit("Upload failed: the selected file was not binary save data.", true)
		return
	var encrypted_bytes := JavaScriptBridge.js_buffer_to_packed_byte_array(result)
	_cleanup_browser_upload()
	import_save_bytes(encrypted_bytes)


func _on_file_reader_failed(_args: Array) -> void:
	_cleanup_browser_upload()
	status_changed.emit("Upload failed: the browser could not read that file.", true)


func _on_file_picker_cancelled(_args: Array) -> void:
	_cleanup_browser_upload()
	status_changed.emit("No file selected.", false)


func import_save_bytes(encrypted_bytes: PackedByteArray) -> bool:
	## Writes uploaded ciphertext to a temporary file for Godot's encrypted
	## FileAccess reader; only validated JSON is allowed to replace slot_1.
	if encrypted_bytes.is_empty() or encrypted_bytes.size() > MAX_SAVE_BYTES:
		status_changed.emit("Upload failed: the save is empty or larger than 8 MB.", true)
		return false
	var temporary := FileAccess.open(IMPORT_TEMP_PATH, FileAccess.WRITE)
	if temporary == null:
		status_changed.emit("Upload failed: temporary browser storage is unavailable.", true)
		return false
	temporary.store_buffer(encrypted_bytes)
	temporary.flush()
	var temp_error := temporary.get_error()
	temporary.close()
	if temp_error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(IMPORT_TEMP_PATH))
		status_changed.emit("Upload failed: the selected file could not be staged.", true)
		return false
	if not FileAccess.file_exists(IMPORT_TEMP_PATH):
		status_changed.emit("Upload failed: temporary save data is missing.", true)
		return false
	var file := FileAccess.open_encrypted_with_pass(IMPORT_TEMP_PATH, FileAccess.READ, SAVE_PASSWORD)
	if file == null:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(IMPORT_TEMP_PATH))
		status_changed.emit("Invalid save: decryption failed. This file may use another key or be corrupt.", true)
		return false
	var json_text := file.get_as_text()
	file.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(IMPORT_TEMP_PATH))
	return _apply_json_save(json_text, true)


func _apply_json_save(json_text: String, imported := false) -> bool:
	if json_text.is_empty():
		status_changed.emit("Invalid save: the decrypted data is empty.", true)
		return false
	var parser := JSON.new()
	var parse_error := parser.parse(json_text)
	if parse_error != OK or not (parser.data is Dictionary):
		status_changed.emit("Invalid save: decryption or JSON validation failed.", true)
		return false
	var parsed: Dictionary = parser.data
	if not _validate_save_data(parsed):
		status_changed.emit("Invalid save: required RPG data or save version is missing.", true)
		return false
	var normalized := _normalize_save_data(_from_json_safe(parsed))
	normalized["imported_from_file"] = imported or bool(normalized.get("imported_from_file", false))
	var previous_state := _deep_copy_dictionary(_current_state)
	_current_state = normalized
	_playtime_remainder = 0.0
	if imported:
		var provider := _state_provider
		_state_provider = null
		var persisted := save_slot()
		_state_provider = provider
		if not persisted:
			_current_state = previous_state
			return false
	if _state_provider != null and is_instance_valid(_state_provider) and _state_provider.has_method("restore_save_state"):
		_state_provider.call("restore_save_state", _deep_copy_dictionary(_current_state))
	save_loaded.emit(_deep_copy_dictionary(_current_state))
	var source := "Uploaded save restored" if imported else "Save loaded"
	status_changed.emit(source + " · " + str(_current_state["timestamp"]), false)
	return true


func _capture_current_state() -> Dictionary:
	if _state_provider != null and is_instance_valid(_state_provider) and _state_provider.has_method("capture_save_state"):
		var captured = _state_provider.call("capture_save_state")
		if captured is Dictionary:
			var payload: Dictionary = _normalize_save_data(captured)
			payload["playtime"] = max(int(_current_state.get("playtime", 0)), int(payload.get("playtime", 0)))
			payload["imported_from_file"] = bool(_current_state.get("imported_from_file", false))
			return payload
	return _deep_copy_dictionary(_current_state)


func _on_autosave_timeout() -> void:
	if has_save() or (_state_provider != null and is_instance_valid(_state_provider)):
		save_slot()


func _default_save_data() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"timestamp": _timestamp_now(),
		"playtime": 0,
		"slot_id": SLOT_ID,
		"imported_from_file": false,
		"player": {
			"level": 1,
			"hp": 100,
			"mp": 30,
			"stats": {"strength": 1, "defense": 1, "agility": 1, "intelligence": 1},
			"position": Vector2.ZERO,
		},
		"inventory": [],
		"active_quests": [],
		"completed_quests": [],
		"world_flags": {},
	}


func _normalize_save_data(source: Dictionary) -> Dictionary:
	var result := _default_save_data()
	result.merge(source, true)
	result["save_version"] = int(result.get("save_version", SAVE_VERSION))
	result["timestamp"] = str(result.get("timestamp", _timestamp_now()))
	result["playtime"] = max(0, int(result.get("playtime", 0)))
	result["slot_id"] = SLOT_ID
	var player: Dictionary = result.get("player", {}) if result.get("player", {}) is Dictionary else {}
	var defaults: Dictionary = _default_save_data()["player"]
	defaults.merge(player, true)
	defaults["level"] = int(defaults.get("level", 1))
	defaults["hp"] = int(defaults.get("hp", 100))
	defaults["mp"] = int(defaults.get("mp", 30))
	defaults["stats"] = defaults.get("stats", {}) if defaults.get("stats", {}) is Dictionary else {}
	for stat_name in defaults["stats"]:
		if defaults["stats"][stat_name] is int or defaults["stats"][stat_name] is float:
			defaults["stats"][stat_name] = int(defaults["stats"][stat_name])
	defaults["position"] = _decode_vector2(defaults.get("position", Vector2.ZERO))
	result["player"] = defaults
	for key in ["inventory", "active_quests", "completed_quests"]:
		if not result.get(key) is Array:
			result[key] = []
	if not result.get("world_flags") is Dictionary:
		result["world_flags"] = {}
	return result


func _validate_save_data(data: Dictionary) -> bool:
	if int(data.get("save_version", -1)) != SAVE_VERSION or str(data.get("slot_id", "")) != SLOT_ID:
		return false
	if not data.get("player", null) is Dictionary:
		return false
	var player: Dictionary = data["player"]
	for key in ["level", "hp", "mp", "stats", "position"]:
		if not player.has(key):
			return false
	if not player["stats"] is Dictionary or not data.get("inventory", null) is Array:
		return false
	if not data.get("active_quests", null) is Array or not data.get("completed_quests", null) is Array:
		return false
	return data.get("world_flags", null) is Dictionary and data.has("timestamp") and data.has("playtime")


func _to_json_safe(value: Variant) -> Variant:
	if value is Vector2:
		return {"__type": "Vector2", "x": value.x, "y": value.y}
	if value is Color:
		return {"__type": "Color", "html": value.to_html(true)}
	if value is Dictionary:
		var converted: Dictionary = {}
		for key in value:
			converted[str(key)] = _to_json_safe(value[key])
		return converted
	if value is Array:
		var converted_array: Array = []
		for item in value:
			converted_array.append(_to_json_safe(item))
		return converted_array
	return value


func _from_json_safe(value: Variant) -> Variant:
	if value is Dictionary:
		if value.get("__type", "") == "Vector2" and value.has("x") and value.has("y"):
			return Vector2(float(value["x"]), float(value["y"]))
		if value.get("__type", "") == "Color" and value.has("html"):
			return Color.from_string(str(value["html"]), Color.WHITE)
		var converted: Dictionary = {}
		for key in value:
			converted[key] = _from_json_safe(value[key])
		return converted
	if value is Array:
		var converted_array: Array = []
		for item in value:
			converted_array.append(_from_json_safe(item))
		return converted_array
	return value


func _decode_vector2(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	if value is Dictionary:
		if value.get("__type", "") == "Vector2":
			return Vector2(float(value.get("x", 0.0)), float(value.get("y", 0.0)))
		if value.has("x") and value.has("y"):
			return Vector2(float(value["x"]), float(value["y"]))
	return Vector2.ZERO


func _deep_copy_dictionary(source: Dictionary) -> Dictionary:
	return source.duplicate(true)


func _timestamp_now() -> String:
	return Time.get_datetime_string_from_system(true, true)


func _cleanup_browser_upload() -> void:
	if _active_file_input != null:
		var parent = _active_file_input.parentNode
		if parent != null:
			parent.removeChild(_active_file_input)
	_active_file_input = null
	_active_file_reader = null
	_file_picker_callback = null
	_file_picker_cancel_callback = null
	_file_reader_load_callback = null
	_file_reader_error_callback = null
