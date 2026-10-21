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
	root.position = Vector2(72, 52)
	root.size = Vector2(1136, 610)
	root.add_theme_constant_override("separation", 14)
	hud.add_child(root)
	var title := Label.new()
	title.text = room_title.to_upper()
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("#192787"))
	root.add_child(title)
	var owner := Label.new()
	owner.text = "%s  ·  %s ACCESS" % [room_owner, room_status.to_upper()]
	owner.add_theme_font_size_override("font_size", 17)
	owner.add_theme_color_override("font_color", Color("#5D9374"))
	root.add_child(owner)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)
	var note := Label.new()
	note.text = room_description + "\n\nPress E or ESC to return to the hallway."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(900, 100)
	note.add_theme_font_size_override("font_size", 18)
	note.add_theme_color_override("font_color", Color("#115293"))
	root.add_child(note)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("#8BAF75"))
	# Dark navy pixel frame, warm cream walls, and a gridded tiled floor carry through every room.
	draw_rect(Rect2(32, 24, 1216, 672), Color("#192787"))
	draw_rect(Rect2(44, 36, 1192, 648), Color("#FAF5E6"))
	draw_rect(Rect2(52, 44, 1176, 8), Color("#5D9374"))
	draw_rect(Rect2(52, 422, 1176, 262), Color("#F3EEDC"))
	for x in range(52, 1228, 32):
		for y in range(422, 684, 32):
			draw_rect(Rect2(x, y, 32, 32), Color("#EDE5D2"), false, 1.0)
	# Pixel window with a deep blue sill.
	draw_rect(Rect2(900, 136, 224, 172), Color("#192787"))
	draw_rect(Rect2(908, 144, 208, 156), Color("#8BC8D8"))
	draw_rect(Rect2(916, 152, 192, 140), Color("#B9DCE3"))
	draw_rect(Rect2(1004, 152, 8, 140), Color("#115293"))
	draw_rect(Rect2(916, 216, 192, 8), Color("#115293"))
	draw_rect(Rect2(888, 308, 248, 12), Color("#192787"))
	# Work table, legs, and a compact instrument cabinet.
	draw_rect(Rect2(144, 356, 360, 16), Color("#192787"))
	draw_rect(Rect2(152, 348, 344, 12), Color("#D77A45"))
	draw_rect(Rect2(160, 372, 16, 82), Color("#115293"))
	draw_rect(Rect2(472, 372, 16, 82), Color("#115293"))
	draw_rect(Rect2(676, 352, 144, 78), Color("#5D9374"))
	draw_rect(Rect2(688, 364, 120, 54), Color("#8BC8D8"))
	# Wall-mounted BIOLOGIQ mark and small blocky foliage add room identity.
	draw_rect(Rect2(120, 142, 176, 92), Color("#E6E0D2"))
	draw_rect(Rect2(128, 150, 160, 76), Color("#192787"))
	draw_string(ThemeDB.fallback_font, Vector2(144, 192), "BIOLOGIQ", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#FAF5E6"))
	draw_rect(Rect2(1120, 360, 24, 44), Color("#D77A45"))
	draw_rect(Rect2(1112, 336, 16, 28), Color("#5D9374"))
	draw_rect(Rect2(1136, 328, 16, 36), Color("#5D9374"))
	draw_rect(Rect2(1144, 352, 16, 12), Color("#5D9374"))
	# Small orange pixels act as restrained accents in the otherwise cool pastel palette.
	draw_rect(Rect2(824, 112, 12, 12), Color("#D77A45"))
	draw_rect(Rect2(840, 112, 12, 12), Color("#D77A45"))
	draw_rect(Rect2(840, 96, 12, 12), Color("#D77A45"))
