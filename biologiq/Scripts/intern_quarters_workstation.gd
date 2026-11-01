extends Control

const PLAYER_SHEET := "res://Art Assets/Player - Walking Animations (Front, Side, Back).png"
const PIPETTE_SCENE := "res://Scenes/Rooms/student_lab_room.tscn"
const DNA_SCENE := "res://Scenes/Rooms/student_lab_dna_room.tscn"
const DATA_SCENE := "res://Scenes/Rooms/student_lab_data_room.tscn"
const WALK_SPEED := 210.0
const PLAYER_RADIUS := 13.0
const PLAYER_SCALE := 0.19
const EXIT_INTERACT_POSITION := Vector2(1120, 174)

var player: CharacterBody2D
var player_sprite: AnimatedSprite2D
var active_station := -1
var interact_hint := ""
var exit_warning := ""
var exit_warning_timer := 0.0
var room_objects: Array[Dictionary] = []
var station_data: Array[Dictionary] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_room()
	_build_player()
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if exit_warning_timer > 0.0:
		exit_warning_timer = maxf(0.0, exit_warning_timer - _delta)
		if exit_warning_timer == 0.0:
			exit_warning = ""
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player.velocity = direction * WALK_SPEED
	if direction.length_squared() > 0.0:
		if absf(direction.x) > absf(direction.y):
			player_sprite.play("side_right" if direction.x > 0.0 else "side_left")
		else:
			player_sprite.play("front" if direction.y > 0.0 else "back")
	else:
		player_sprite.stop()
	var previous_position := player.position
	player.move_and_slide()
	if not _is_walkable(player.position):
		player.position = previous_position
		player.velocity = Vector2.ZERO
	_update_nearest_station()
	queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		_try_exit_room()
	elif event.keycode == KEY_E:
		if _is_near_exit():
			_try_exit_room()
		elif active_station >= 0 and _station_is_current(active_station):
			get_tree().change_scene_to_file(str(station_data[active_station].scene))


func _build_room() -> void:
	# All activities sit together on one central work table.
	station_data = [
		{"name": "Pipette Practice", "position": Vector2(480, 338), "scene": PIPETTE_SCENE, "accent": Color("#d97743"), "symbol": "PIPETTE"},
		{"name": "DNA Base Pairing", "position": Vector2(640, 338), "scene": DNA_SCENE, "accent": Color("#5c8d75"), "symbol": "DNA"},
		{"name": "Data Verification", "position": Vector2(800, 338), "scene": DATA_SCENE, "accent": Color("#4c78a0"), "symbol": "DATA"},
	]
	room_objects = [
		{"rect": Rect2(400, 260, 480, 130), "kind": "table"},
	]


func _build_player() -> void:
	player = CharacterBody2D.new()
	player.name = "Intern"
	player.position = Vector2(670, 594)
	add_child(player)
	var shadow := Polygon2D.new()
	shadow.color = Color(0.12, 0.15, 0.20, 0.28)
	shadow.polygon = PackedVector2Array([Vector2(-13, 2), Vector2(-9, -4), Vector2(9, -4), Vector2(13, 2), Vector2(8, 6), Vector2(-8, 6)])
	player.add_child(shadow)
	player_sprite = AnimatedSprite2D.new()
	player_sprite.name = "PlayerSprite"
	player_sprite.sprite_frames = _player_frames()
	player_sprite.scale = Vector2(PLAYER_SCALE, PLAYER_SCALE)
	player_sprite.position = Vector2(0, -56)
	player.add_child(player_sprite)
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = PLAYER_RADIUS
	collision.shape = shape
	collision.position = Vector2(0, -7)
	player.add_child(collision)


func _player_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	_add_player_strip(frames, "front", 0)
	_add_player_strip(frames, "side_right", 4)
	_add_player_strip(frames, "side_left", 8)
	_add_player_strip(frames, "back", 12)
	return frames


func _add_player_strip(frames: SpriteFrames, animation_name: String, start_frame: int) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, true)
	frames.set_animation_speed(animation_name, 8.0)
	var texture := load(PLAYER_SHEET) as Texture2D
	for frame_index in 4:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(Vector2((start_frame + frame_index) * 306.0, 0), Vector2(306, 646))
		frames.add_frame(animation_name, atlas)


func _update_nearest_station() -> void:
	active_station = -1
	var closest_distance := 86.0
	for index in station_data.size():
		var station_position: Vector2 = station_data[index].position
		var distance := player.position.distance_to(station_position)
		if distance < closest_distance:
			closest_distance = distance
			active_station = index
	if _is_near_exit():
		interact_hint = "E  Exit to hallway"
	elif active_station < 0:
		interact_hint = "WASD / arrows  Move     E  Use workstation     ESC  Exit"
	elif _all_tasks_complete():
		interact_hint = "All tasks complete"
	elif _station_is_current(active_station):
		interact_hint = "E  Start %s" % station_data[active_station].name
	else:
		interact_hint = "Complete %s first" % _current_station_name()


func _current_station_index() -> int:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null or not save_manager.is_student_lab_pipette_complete():
		return 0
	if not save_manager.is_student_lab_dna_complete():
		return 1
	return 2


func _current_station_name() -> String:
	return str(station_data[_current_station_index()].name)


func _station_is_current(index: int) -> bool:
	return not _all_tasks_complete() and index == _current_station_index()


func _all_tasks_complete() -> bool:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null:
		return false
	return save_manager.is_student_lab_pipette_complete() \
		and save_manager.is_student_lab_dna_complete() \
		and save_manager.is_student_lab_data_complete()


func _try_exit_room() -> void:
	if _all_tasks_complete():
		get_tree().change_scene_to_file("res://Scenes/main_map.tscn")
	else:
		exit_warning = "Please complete all tasks before exiting"
		exit_warning_timer = 2.5
		queue_redraw()


func _is_near_exit() -> bool:
	return player.position.distance_to(EXIT_INTERACT_POSITION) < 82.0


func _is_walkable(at: Vector2) -> bool:
	if at.x < 64.0 or at.x > 1216.0 or at.y < 168.0 or at.y > 646.0:
		return false
	var foot_rect := Rect2(at - Vector2(PLAYER_RADIUS, PLAYER_RADIUS), Vector2(PLAYER_RADIUS * 2.0, PLAYER_RADIUS * 2.0))
	for object in room_objects:
		if foot_rect.intersects(object.rect):
			return false
	return true


func _draw() -> void:
	# Keep the room simple so the table and exit are immediately readable.
	draw_rect(Rect2(0, 0, 1280, 720), Color("#17204f"))
	draw_rect(Rect2(36, 24, 1208, 672), Color("#ddd9ca"))
	draw_rect(Rect2(48, 36, 1184, 640), Color("#e9e4d4"))
	draw_rect(Rect2(48, 36, 1184, 10), Color("#536e58"))
	_draw_floor_tiles()
	_draw_table()
	_draw_exit_door()
	_draw_activity_markers()
	_draw_hud()


func _draw_floor_tiles() -> void:
	var tile_color := Color("#d9d4c4")
	for x in range(48, 1232, 106):
		draw_line(Vector2(x, 46), Vector2(x, 676), tile_color, 2.0)
	for y in range(46, 676, 58):
		draw_line(Vector2(48, y), Vector2(1232, y), tile_color, 2.0)



func _draw_table() -> void:
	draw_rect(Rect2(400, 264, 480, 132), Color("#303968"))
	draw_rect(Rect2(412, 254, 456, 118), Color("#b87954"))
	draw_rect(Rect2(422, 261, 436, 100), Color("#eee7d5"))
	draw_rect(Rect2(430, 367, 18, 36), Color("#545e77"))
	draw_rect(Rect2(834, 367, 18, 36), Color("#545e77"))
	draw_string(GameFont.FONT, Vector2(0, 230), "WORKSTATION", HORIZONTAL_ALIGNMENT_CENTER, 1280, 16, Color("#414969"))
	for index in station_data.size():
		var station: Dictionary = station_data[index]
		var position: Vector2 = station.position
		var accent: Color = station.accent
		draw_rect(Rect2(position - Vector2(53, 34), Vector2(106, 68)), Color("#f6f0e2"))
		draw_rect(Rect2(position - Vector2(53, 34), Vector2(106, 68)), Color("#7f8792"), false, 2.0)
		draw_circle(position + Vector2(0, -5), 12, accent)
		draw_string(GameFont.FONT, position + Vector2(-48, 26), str(station.symbol), HORIZONTAL_ALIGNMENT_CENTER, 96, 11, Color("#303856"))


func _draw_exit_door() -> void:
	draw_rect(Rect2(1070, 35, 100, 12), Color("#333968"))
	draw_rect(Rect2(1080, 43, 80, 102), Color("#29336f"))
	draw_rect(Rect2(1087, 50, 66, 88), Color("#59638a"))
	draw_circle(Vector2(1140, 96), 4, Color("#f1df9c"))
	draw_string(GameFont.FONT, Vector2(1060, 164), "EXIT", HORIZONTAL_ALIGNMENT_CENTER, 120, 13, Color("#343b62"))


func _draw_activity_markers() -> void:
	for index in station_data.size():
		var station: Dictionary = station_data[index]
		var selected := _station_is_current(index)
		var position: Vector2 = station.position
		var accent: Color = station.accent
		var marker_color := accent if selected else Color("#a7a69e")
		draw_circle(position + Vector2(0, -32), 5, marker_color)
		draw_string(GameFont.FONT, position + Vector2(-58, 48), str(station.name), HORIZONTAL_ALIGNMENT_CENTER, 116, 11, Color("#303856") if selected else Color("#777971"))
		if selected:
			draw_string(GameFont.FONT, position + Vector2(-52, 64), "CURRENT", HORIZONTAL_ALIGNMENT_CENTER, 104, 9, accent)


func _draw_hud() -> void:
	draw_rect(Rect2(0, 0, 1280, 36), Color("#17204f"))
	draw_string(GameFont.FONT, Vector2(24, 25), "INTERN QUARTERS", HORIZONTAL_ALIGNMENT_LEFT, 250, 15, Color("#f4efdf"))
	var task_label := "TASK: Exit the intern quarters" if _all_tasks_complete() else "CURRENT TASK: %s" % _current_station_name().to_upper()
	draw_string(GameFont.FONT, Vector2(250, 25), task_label, HORIZONTAL_ALIGNMENT_CENTER, 780, 14, Color("#d9dfc7"))
	draw_rect(Rect2(0, 666, 1280, 54), Color(0.09, 0.12, 0.28, 0.92))
	var footer_text := exit_warning if exit_warning != "" else interact_hint
	draw_string(GameFont.FONT, Vector2(0, 699), footer_text, HORIZONTAL_ALIGNMENT_CENTER, 1280, 15, Color("#f4b6a9") if exit_warning != "" else Color("#f4efdf"))
