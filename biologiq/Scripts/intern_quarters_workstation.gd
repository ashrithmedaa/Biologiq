extends Control

const PLAYER_SHEET := "res://Art Assets/Player - Walking Animations (Clean).png"
const STUDENT_LAB_GUIDE := preload("res://Scripts/student_lab_guide.gd")
const PIPETTE_SCENE := "res://Scenes/Rooms/student_lab_room.tscn"
const DNA_SCENE := "res://Scenes/Rooms/student_lab_dna_room.tscn"
const DATA_SCENE := "res://Scenes/Rooms/student_lab_data_room.tscn"
const WALK_SPEED := 210.0
const PLAYER_RADIUS := 13.0
const PLAYER_SCALE := 0.19
const SAM_SCALE := 0.22
const SAM_POSITION := Vector2(110, 220)

var player: CharacterBody2D
var player_sprite: AnimatedSprite2D
var student_guide: Control
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
	_build_sam()
	_style_room_labels()
	_update_nearest_station()
	_refresh_room_ui()
	student_guide = STUDENT_LAB_GUIDE.new() as Control
	student_guide.call("configure", "Intern Quarters", "", false, true)
	add_child(student_guide)


func _physics_process(_delta: float) -> void:
	if student_guide != null and bool(student_guide.call("blocks_minigame_input")):
		player.velocity = Vector2.ZERO
		player_sprite.stop()
		return
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
	player.z_index = 1 if player.position.y > SAM_POSITION.y else 0
	_update_nearest_station()
	_refresh_room_ui()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if student_guide != null and bool(student_guide.call("blocks_minigame_input")):
		return
	if event.keycode == KEY_ESCAPE:
		_try_exit_room()
	elif event.keycode == KEY_E:
		if _is_near_exit():
			_try_exit_room()
		elif _is_near_sam():
			student_guide.call("open_dialogue")
		elif active_station >= 0 and _station_is_current(active_station):
			get_tree().change_scene_to_file(str(station_data[active_station].scene))


func _build_room() -> void:
	# Station interaction positions come from the editable scene nodes.
	var pipette_station := get_node("MapArt/Stations/PipetteStation") as Control
	var dna_station := get_node("MapArt/Stations/DnaStation") as Control
	var data_station := get_node("MapArt/Stations/DataStation") as Control
	station_data = [
		{"name": "Pipette Practice", "position": pipette_station.position, "scene": PIPETTE_SCENE, "accent": Color("#d97743"), "symbol": "PIPETTE", "node": pipette_station},
		{"name": "DNA Base Pairing", "position": dna_station.position, "scene": DNA_SCENE, "accent": Color("#5c8d75"), "symbol": "DNA", "node": dna_station},
		{"name": "Data Verification", "position": data_station.position, "scene": DATA_SCENE, "accent": Color("#4c78a0"), "symbol": "DATA", "node": data_station},
	]
	var table_bounds := get_node("MapArt/Furnishings/TableShadow") as ColorRect
	room_objects = [
		{"rect": Rect2(table_bounds.position, table_bounds.size), "kind": "table"},
		{"rect": Rect2(Vector2(SAM_POSITION.x - 28, 168), Vector2(56, SAM_POSITION.y - 168)), "kind": "Sam"},
	]


func _build_player() -> void:
	player = CharacterBody2D.new()
	player.name = "Intern"
	player.position = Vector2(670, 594)
	player.z_index = 1 if player.position.y > SAM_POSITION.y else 0
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


func _build_sam() -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://Art Assets/Sam - Front walking spritesheet transparent.png") as Texture2D
	atlas.region = Rect2(430, 285, 350, 700)
	var sam := Sprite2D.new()
	sam.name = "Sam"
	sam.texture = atlas
	sam.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sam.scale = Vector2(SAM_SCALE, SAM_SCALE)
	sam.position = SAM_POSITION - Vector2(0, 350 * SAM_SCALE)
	sam.z_index = 0
	add_child(sam)


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
	elif _is_near_sam():
		interact_hint = "E  Talk to Sam"
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
		_refresh_room_ui()


func _is_near_exit() -> bool:
	var exit_point := get_node("MapArt/ExitAccessPoint") as Marker2D
	return player.position.distance_to(exit_point.position) < 82.0


func _is_near_sam() -> bool:
	return player.position.distance_to(SAM_POSITION) < 96.0


func _is_walkable(at: Vector2) -> bool:
	if at.x < 64.0 or at.x > 1216.0 or at.y < 168.0 or at.y > 646.0:
		return false
	var foot_rect := Rect2(at - Vector2(PLAYER_RADIUS, PLAYER_RADIUS), Vector2(PLAYER_RADIUS * 2.0, PLAYER_RADIUS * 2.0))
	for object in room_objects:
		if foot_rect.intersects(object.rect):
			return false
	return true


func _refresh_room_ui() -> void:
	var task_label := get_node("UI/Header/TaskLabel") as Label
	var footer_label := get_node("UI/Footer/Prompt") as Label
	task_label.text = "TASK: Exit the intern quarters" if _all_tasks_complete() else "CURRENT TASK: %s" % _current_station_name().to_upper()
	footer_label.text = exit_warning if exit_warning != "" else interact_hint
	footer_label.add_theme_color_override("font_color", Color("#f4b6a9") if exit_warning != "" else Color("#f4efdf"))
	for index in station_data.size():
		var station: Dictionary = station_data[index]
		var station_node := station.node as Control
		var selected := _station_is_current(index)
		var marker := station_node.get_node("ActivityMarker") as Polygon2D
		marker.color = station.accent if selected else Color("#a7a69e")
		var station_label := station_node.get_node("StationName") as Label
		station_label.add_theme_color_override("font_color", Color("#303856") if selected else Color("#777971"))
		(station_node.get_node("CurrentLabel") as Label).visible = selected


func _style_room_labels() -> void:
	for label in find_children("*", "Label", true, false):
		(label as Label).add_theme_font_override("font", GameFont.FONT)
