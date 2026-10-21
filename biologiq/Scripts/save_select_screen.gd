extends Node2D

@onready var save_manager: Node = get_node("/root/SaveManager")
@onready var status_label: Label = $CanvasLayer/ScreenRoot/CenterContainer/SavePanel/PanelContent/StatusLabel
@onready var slot_label: Label = $CanvasLayer/ScreenRoot/CenterContainer/SavePanel/PanelContent/SlotPanel/SlotLabel
@onready var new_save_button: Button = $CanvasLayer/ScreenRoot/CenterContainer/SavePanel/PanelContent/ActionGrid/NewSaveButton
@onready var upload_save_button: Button = $CanvasLayer/ScreenRoot/CenterContainer/SavePanel/PanelContent/ActionGrid/UploadRow/UploadSaveButton
@onready var remove_upload_button: Button = $CanvasLayer/ScreenRoot/CenterContainer/SavePanel/PanelContent/ActionGrid/UploadRow/RemoveUploadButton
@onready var next_button: Button = $CanvasLayer/ScreenRoot/CenterContainer/SavePanel/PanelContent/ActionGrid/NextButton
@onready var back_button: Button = $CanvasLayer/ScreenRoot/CenterContainer/SavePanel/PanelContent/BackButton

const SUCCESS_COLOR := Color("#d5e8c8")
const ERROR_COLOR := Color("#f88777")


func _ready() -> void:
	new_save_button.pressed.connect(_on_new_save_pressed)
	upload_save_button.pressed.connect(_on_upload_save_pressed)
	remove_upload_button.pressed.connect(_on_remove_upload_pressed)
	next_button.pressed.connect(_on_next_pressed)
	back_button.pressed.connect(_on_back_pressed)
	save_manager.status_changed.connect(_on_save_status_changed)
	_refresh_slot_summary()


func _refresh_slot_summary() -> void:
	var summary: Dictionary = save_manager.get_slot_summary()
	if not bool(summary.get("exists", false)):
		slot_label.text = "SLOT 1  ·  EMPTY"
		status_label.text = "No save found. Start a new game or upload a save file."
		status_label.add_theme_color_override("font_color", SUCCESS_COLOR)
	elif not bool(summary.get("valid", false)):
		slot_label.text = "SLOT 1  ·  UNAVAILABLE"
		status_label.text = "The local save is damaged or cannot be decrypted. Create a new game or upload another file."
		status_label.add_theme_color_override("font_color", ERROR_COLOR)
	else:
		slot_label.text = "SLOT 1  ·  SAVED  ·  " + str(summary.get("timestamp", "Unknown time"))
		if bool(summary.get("imported", false)):
			status_label.text = "Uploaded save ready · play time " + _format_playtime(int(summary.get("playtime", 0))) + ". Click Next to continue."
		else:
			status_label.text = "Local save ready · play time " + _format_playtime(int(summary.get("playtime", 0))) + ". Click Next to continue."
		status_label.add_theme_color_override("font_color", SUCCESS_COLOR)
	_update_slot_controls(summary)


func _update_slot_display() -> void:
	var summary: Dictionary = save_manager.get_slot_summary()
	if not bool(summary.get("exists", false)):
		slot_label.text = "SLOT 1  ·  EMPTY"
	elif not bool(summary.get("valid", false)):
		slot_label.text = "SLOT 1  ·  UNAVAILABLE"
	else:
		slot_label.text = "SLOT 1  ·  SAVED  ·  " + str(summary.get("timestamp", "Unknown time"))
	_update_slot_controls(summary)


func _update_slot_controls(summary: Dictionary) -> void:
	var valid := bool(summary.get("valid", false))
	var uploaded := valid and bool(summary.get("imported", false))
	upload_save_button.disabled = uploaded
	remove_upload_button.visible = uploaded
	next_button.disabled = not valid


func _on_new_save_pressed() -> void:
	if not save_manager.create_new_save():
		return
	var error := get_tree().change_scene_to_file("res://Scenes/employee_orientation.tscn")
	if error != OK:
		_on_save_status_changed("Could not open the character selection scene.", true)


func _on_upload_save_pressed() -> void:
	save_manager.import_save_from_file()


func _on_remove_upload_pressed() -> void:
	save_manager.delete_uploaded_save()
	_update_slot_display()


func _on_next_pressed() -> void:
	if not bool(save_manager.get_slot_summary().get("valid", false)):
		_on_save_status_changed("Create a new game or upload a valid save before continuing.", true)
		return
	if not save_manager.load_slot():
		return
	var error := get_tree().change_scene_to_file("res://Scenes/main_map.tscn")
	if error != OK:
		_on_save_status_changed("Could not open the map scene.", true)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/select_screen.tscn")


func _on_save_status_changed(message: String, is_error: bool) -> void:
	status_label.text = message
	status_label.add_theme_color_override("font_color", ERROR_COLOR if is_error else SUCCESS_COLOR)
	if not is_error and (message.begins_with("Save stored") or message.begins_with("Save loaded") or message.begins_with("Uploaded save restored") or message.begins_with("Uploaded save removed")):
		_update_slot_display()


func _format_playtime(seconds: int) -> String:
	var hours := int(seconds / 3600.0)
	var minutes := int((seconds % 3600) / 60.0)
	return "%02d:%02d" % [hours, minutes]
