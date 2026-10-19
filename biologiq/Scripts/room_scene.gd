extends Node2D

@export var room_title := "BIOLOGIQ ROOM"
@export var room_owner := ""
@export var room_status := ""
@export var room_description := "Room content and interactions are test placeholders for this demo."

var hud: CanvasLayer


func _ready() -> void:
	_build_room()
	queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file("res://Scenes/main_map.tscn")


func _build_room() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var root := VBoxContainer.new()
	root.position = Vector2(64, 54)
	root.size = Vector2(1152, 600)
	root.add_theme_constant_override("separation", 18)
	hud.add_child(root)
	var title := Label.new()
	title.text = room_title.to_upper()
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("#143d47"))
	root.add_child(title)
	var owner := Label.new()
	owner.text = "%s  ·  %s ACCESS" % [room_owner, room_status.to_upper()]
	owner.add_theme_font_size_override("font_size", 17)
	owner.add_theme_color_override("font_color", Color("#52756e"))
	root.add_child(owner)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)
	var note := Label.new()
	note.text = room_description + "\n\nPress E or ESC to return to the hallway."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(900, 100)
	note.add_theme_font_size_override("font_size", 20)
	note.add_theme_color_override("font_color", Color("#315960"))
	root.add_child(note)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("#dce6df"))
	draw_rect(Rect2(38, 30, 1204, 660), Color("#b8d2c6"))
	draw_rect(Rect2(52, 44, 1176, 632), Color("#fff9e9"))
	# Room floor and window panels establish a shared visual style without repeating map sprites.
	draw_rect(Rect2(52, 430, 1176, 246), Color("#e7e0cd"))
	draw_rect(Rect2(890, 140, 230, 170), Color("#b7d6d2"))
	draw_rect(Rect2(900, 150, 210, 150), Color("#dce9df"))
	draw_line(Vector2(1005, 150), Vector2(1005, 300), Color("#8caea4"), 4)
	draw_line(Vector2(900, 225), Vector2(1110, 225), Color("#8caea4"), 4)
	draw_rect(Rect2(155, 360, 340, 28), Color("#26616a"))
	draw_rect(Rect2(170, 388, 14, 70), Color("#42636a"))
	draw_rect(Rect2(465, 388, 14, 70), Color("#42636a"))
	draw_rect(Rect2(670, 365, 130, 66), Color("#75938b"))
	draw_rect(Rect2(686, 375, 108, 46), Color("#dce9df"))
