extends Node2D

const SHARON_SHEET := "res://Art Assets/Sharon O_Riley - Typing.png"
const PLAYER_SHEET := "res://Art Assets/Player - Walking Animations (Clean).png"
const MARIA_SHEET := "res://Art Assets/MariaFINAL.png"
const DOOR_SPRITE := "res://Art Assets/door.png"
const SAM_FRONT_SHEET := "res://Art Assets/Sam - Front walking spritesheet transparent.png"
const SAM_SIDE_SHEET := "res://Art Assets/Sam - Side walking spritesheet.png"
const SAM_BACK_SHEET := "res://Art Assets/Sam walking - Back spritesheet.png"
const MAIN_ENTRANCE_POSITION := Vector2(1800, 390)
const MAIN_ENTRANCE_EXIT_POSITION := Vector2(1800, 155)
const WALK_SPEED := 250.0
const SAM_WALK_SPEED := WALK_SPEED
const MARIA_WALK_SPEED := 250.0
const DIALOGUE_CHARACTERS_PER_SECOND := 38.0
const INTERACT_DISTANCE := 78.0
const WORLD_WIDTH := 3600.0
const WORLD_HEIGHT := 2400.0
const DOOR_SOUND := "res://684538__pnmcarrierailfan__doors-wood-door-with-latch_1.mp3"
const TALKING_SOUND := "res://tunetank.com_talking-gibberish-silly-character.wav"
const CHARACTER_VOICES := {
	"Sharon": "res://Art Assets/Sharonvoice.mp3",
	"Sam": "res://Art Assets/Samvoice.mp3",
	"Maria": "res://Art Assets/Mariavoice.mp3",
}

var player: CharacterBody2D
var player_sprite: AnimatedSprite2D
var camera: Camera2D
var dialogue_panel: PanelContainer
var dialogue_label: Label
var dialogue_hint: Label
var interaction_hint: Label
var guide_label: Label
var sam: Node2D
var sam_sprite: AnimatedSprite2D
var sam_interaction_index := -1
var sam_last_stop_position := Vector2.ZERO
var maria: Node2D
var maria_sprite: AnimatedSprite2D
var sharon: Node2D
var floor_title: Label
var menu_layer: CanvasLayer
var menu_status_label: Label
var demo_progress_bar: ProgressBar
var dialogue_lines: Array[String] = []
var dialogue_index := 0
var dialogue_open := false
var dialogue_typing := false
var dialogue_type_progress := 0.0
var dialogue_completes_checkin := false
var dialogue_completes_sam_intro := false
var dialogue_completes_maria_lines := false
var dialogue_completes_sam_final_lines := false
var dialogue_completes_student_lab_task := false
var sharon_checked_in := false
var sam_intro_done := false
var sam_entrance_active := false
var tour_phase := 0
var tour_moving := false
var dialogue_completes_tour_stop := false
var maria_scene_active := false
var maria_meeting_done := false
var student_lab_task_received := false
var intern_quarters_round := 1
var dialogue_completes_second_task_list := false
var dialogue_completes_farewell := false
var farewell_scene_active := false
var farewell_done := false
var menu_open := false
var player_facing := "down"
var interactables: Array[Dictionary] = []
var room_doors: Array[Dictionary] = []
var player_program := "Research Shadowing"
var player_status := "Master's"
var side_door_texture: Texture2D
var open_door_texture: Texture2D
var open_door_name := ""
var main_entry_open := false
var talking_audio: AudioStreamPlayer
var npc_dialogue_active := false
var dialogue_voice := ""


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_setup_input()
	_setup_audio()
	_load_player_status()
	_build_map()
	_build_characters()
	var save_manager := get_node_or_null("/root/SaveManager")
	var spawn_position := MAIN_ENTRANCE_POSITION
	if save_manager != null:
		save_manager.register_state_provider(self)
		restore_save_state(save_manager.get_save_state())
		spawn_position = save_manager.take_room_return_position(MAIN_ENTRANCE_POSITION)
	player.global_position = spawn_position
	if sam_intro_done and tour_phase == 0:
		tour_phase = 1
		if sam_last_stop_position == Vector2.ZERO:
			sam.global_position = player.global_position + Vector2(58, 10)
	_build_hud()
	_build_menu()
	if sharon_checked_in and not sam_intro_done:
		_begin_sam_entrance()
	elif sam_intro_done:
		if maria_meeting_done:
			sam.hide()
			guide_label.text = "Get to do list from Sharon"
			guide_label.show()
		elif tour_phase in [1, 3, 5]:
			sam.show()
			_begin_tour_walk()
		elif tour_phase in [2, 4, 6]:
			sam.show()
			guide_label.text = "Talk to Sam"
			guide_label.show()
		elif tour_phase >= 7:
			sam.show()
			_begin_maria_scene()
	if student_lab_task_received:
		guide_label.text = _intern_quarters_task_text()
		guide_label.show()
	if save_manager != null:
		save_manager.status_changed.connect(_on_save_status_changed)
	_update_player_animation(false)


func _physics_process(_delta: float) -> void:
	if dialogue_open or menu_open or sam_entrance_active or maria_scene_active or farewell_scene_active:
		player.velocity = Vector2.ZERO
		_update_player_animation(false)
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player.velocity = direction * WALK_SPEED
	if direction.length_squared() > 0.0:
		if absf(direction.x) > absf(direction.y):
			player_facing = "right" if direction.x > 0.0 else "left"
		else:
			player_facing = "down" if direction.y > 0.0 else "up"
	var previous_position := player.global_position
	player.move_and_slide()
	if not _is_walkable_position(player.global_position):
		player.global_position = previous_position
		player.velocity = Vector2.ZERO
	_update_sharon_draw_order()
	_update_player_animation(direction.length_squared() > 0.0)
	_update_interaction_hint()
	if floor_title != null:
		floor_title.text = "BIOLOGIQ  /  FLOOR 2" if player.global_position.y > 1000.0 else "BIOLOGIQ  /  FLOOR 1"
	_update_sam_interactable()


func _process(delta: float) -> void:
	if not dialogue_open or not dialogue_typing:
		return
	dialogue_type_progress += DIALOGUE_CHARACTERS_PER_SECOND * delta
	var visible_count := mini(int(dialogue_type_progress), dialogue_label.text.length())
	dialogue_label.visible_characters = visible_count
	if visible_count >= dialogue_label.text.length():
		dialogue_typing = false
		talking_audio.stop()
		dialogue_hint.text = "Click or press Enter to continue"


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		elif dialogue_open and not maria_scene_active and not farewell_scene_active:
			_close_dialogue()
		elif menu_open:
			_close_menu()
		return
	if event.keycode == KEY_F and not dialogue_open and not maria_scene_active and not farewell_scene_active:
		_toggle_menu()
		return
	if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		if dialogue_open:
			_advance_dialogue()
		return
	if event.keycode == KEY_E and not dialogue_open and not menu_open:
		if sam_entrance_active or maria_scene_active or farewell_scene_active:
			return
		_interact()
		return


func _setup_input() -> void:
	_add_key_action("move_up", KEY_W)
	_add_key_action("move_up", KEY_UP)
	_add_key_action("move_down", KEY_S)
	_add_key_action("move_down", KEY_DOWN)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_left", KEY_LEFT)
	_add_key_action("move_right", KEY_D)
	_add_key_action("move_right", KEY_RIGHT)


func _add_key_action(action: String, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var key_event := InputEventKey.new()
	key_event.physical_keycode = key
	InputMap.action_add_event(action, key_event)


func _load_player_status() -> void:
	if not is_instance_valid(get_node_or_null("/root/SaveManager")):
		return
	var saved: Dictionary = get_node("/root/SaveManager").get_save_state()
	player_program = str(saved.get("degree_program", player_program))
	player_status = str(saved.get("degree_status", player_status))


func capture_save_state() -> Dictionary:
	var manager := get_node_or_null("/root/SaveManager")
	var state: Dictionary = manager.get_save_state() if manager != null else {}
	var player_data: Dictionary = state.get("player", {}) if state.get("player", {}) is Dictionary else {}
	player_data["position"] = player.global_position if is_instance_valid(player) else Vector2.ZERO
	state["player"] = player_data
	state["degree_program"] = player_program
	state["degree_status"] = player_status
	state["sharon_checked_in"] = sharon_checked_in
	state["sam_intro_done"] = sam_intro_done
	state["maria_meeting_done"] = maria_meeting_done
	state["student_lab_task_received"] = student_lab_task_received
	state["intern_quarters_round"] = intern_quarters_round
	state["farewell_done"] = farewell_done
	state["tour_phase"] = tour_phase
	if is_instance_valid(sam):
		state["sam_position"] = sam.global_position
		state["sam_last_stop_position"] = sam_last_stop_position
	state.erase("inventory")
	return state


func restore_save_state(data: Dictionary) -> void:
	player_program = str(data.get("degree_program", player_program))
	player_status = str(data.get("degree_status", player_status))
	sharon_checked_in = bool(data.get("sharon_checked_in", false))
	sam_intro_done = bool(data.get("sam_intro_done", false))
	maria_meeting_done = bool(data.get("maria_meeting_done", false))
	student_lab_task_received = bool(data.get("student_lab_task_received", false))
	intern_quarters_round = maxi(1, int(data.get("intern_quarters_round", 1)))
	farewell_done = bool(data.get("farewell_done", false))
	tour_phase = int(data.get("tour_phase", tour_phase))
	var saved_sam_position: Variant = data.get("sam_position", Vector2.ZERO)
	if is_instance_valid(sam) and saved_sam_position is Vector2 and saved_sam_position != Vector2.ZERO:
		sam.global_position = saved_sam_position
	var saved_sam_stop: Variant = data.get("sam_last_stop_position", Vector2.ZERO)
	if saved_sam_stop is Vector2:
		sam_last_stop_position = saved_sam_stop
	var player_data: Dictionary = data.get("player", {}) if data.get("player", {}) is Dictionary else {}
	var saved_position: Variant = player_data.get("position", Vector2.ZERO)
	if is_instance_valid(player) and saved_position is Vector2 and saved_position != Vector2.ZERO:
		player.global_position = saved_position


func _build_map() -> void:
	var rooms_root := get_node("MapArt/Rooms")
	for room_node in rooms_root.get_children():
		var room_size: Vector2 = room_node.get_meta("room_size")
		var door_local: Vector2 = room_node.get_meta("door_local")
		var room_position: Vector2 = room_node.global_position
		_add_room(
			str(room_node.get_meta("room_name")),
			Rect2(room_position, room_size),
			room_node.to_global(door_local),
			str(room_node.get_meta("door_side"))
		)

	_build_side_door_sprites()
	_build_room_door_art()


func _add_room(room_name: String, room_rect: Rect2, door_position: Vector2, door_side: String = "bottom") -> void:
	room_doors.append({"name": room_name, "room_rect": room_rect, "position": door_position, "side": door_side})


func _build_side_door_sprites() -> void:
	var door_atlas := load(DOOR_SPRITE) as Texture2D
	var closed_door := AtlasTexture.new()
	closed_door.atlas = door_atlas
	closed_door.region = Rect2(0, 0, 600, 880)
	# A narrow cross-section through the door at handle height reads as a door edge
	# when turned sideways, with the original handle still visible.
	var side_door_detail := AtlasTexture.new()
	side_door_detail.atlas = door_atlas
	side_door_detail.region = Rect2(0, 455, 600, 105)
	var open_door := AtlasTexture.new()
	open_door.atlas = door_atlas
	open_door.region = Rect2(600, 0, 600, 880)
	side_door_texture = closed_door
	open_door_texture = open_door
	for room in room_doors:
		var room_art := _room_art_node(str(room.name))
		if room_art == null:
			continue
		var sprite := room_art.get_node_or_null("DoorAnchor/DoorSprite") as Sprite2D
		if sprite == null:
			continue
		var side := str(room.get("side", "bottom"))
		sprite.texture = side_door_detail if side == "left" or side == "right" else closed_door
		sprite.set_meta("map_door_name", str(room.name))


func _build_room_door_art() -> void:
	for room in room_doors:
		var room_art := _room_art_node(str(room.name))
		if room_art == null:
			continue
		var sprite := room_art.get_node_or_null("DoorAnchor/DoorSprite") as Sprite2D
		if sprite == null:
			continue
		sprite.set_meta("map_door_name", str(room.name))

	var entrance_sprite := get_node("MapArt/Entrance/MainEntranceDoor") as Sprite2D
	entrance_sprite.texture = side_door_texture
	entrance_sprite.set_meta("main_entrance_door", true)
	_refresh_map_door_art()


func _refresh_map_door_art() -> void:
	var entrance_sprite := get_node_or_null("MapArt/Entrance/MainEntranceDoor") as Sprite2D
	if entrance_sprite != null:
		entrance_sprite.texture = open_door_texture if main_entry_open else side_door_texture
	for room in room_doors:
		var room_art := _room_art_node(str(room.name))
		if room_art == null:
			continue
		var sprite := room_art.get_node_or_null("DoorAnchor/DoorSprite") as Sprite2D
		if sprite == null:
			continue
		if str(room.get("side", "bottom")) == "bottom":
			sprite.texture = open_door_texture if str(room.name) == open_door_name else side_door_texture


func _room_art_node(room_name: String) -> Node2D:
	for room_node in get_node("MapArt/Rooms").get_children():
		if str(room_node.get_meta("room_name")) == room_name:
			return room_node as Node2D
	return null


func _build_characters() -> void:
	# The scene desk is centered at (1801, 613); place Sharon's seated typing art there.
	sharon = _make_npc("Sharon", Vector2(1801, 613), _sharon_frames(), 3.4)
	var sharon_sprite := sharon.get_node("Sprite") as AnimatedSprite2D
	sharon_sprite.position = Vector2(0, -56)
	sharon_sprite.play("typing")
	_add_character_interaction("Sharon O'Riley", sharon.position, [])
	var sharon_blocker := StaticBody2D.new()
	sharon_blocker.name = "SharonBlocker"
	sharon_blocker.position = Vector2(1801, 603)
	var sharon_block_shape := CollisionShape2D.new()
	var sharon_block_rectangle := RectangleShape2D.new()
	sharon_block_rectangle.size = Vector2(48, 30)
	sharon_block_shape.shape = sharon_block_rectangle
	sharon_blocker.add_child(sharon_block_shape)
	add_child(sharon_blocker)
	sam = _make_npc("Sam", Vector2(2320, 690), _sam_frames(), 0.19)
	sam_sprite = sam.get_node("Sprite") as AnimatedSprite2D
	_set_sam_walk_animation("walk_left")
	sam_sprite.stop()
	sam.hide()
	sam_interaction_index = _add_character_interaction("Sam", sam.position, [])
	maria = _make_npc("Maria", Vector2.ZERO, _maria_frames(), 0.22)
	maria_sprite = maria.get_node("Sprite") as AnimatedSprite2D
	maria_sprite.position = Vector2(0, -71)
	maria_sprite.stop()
	maria.hide()
	var desk_collider := StaticBody2D.new()
	desk_collider.name = "ReceptionDeskCollider"
	desk_collider.position = Vector2(1801, 613)
	var desk_shape := CollisionShape2D.new()
	var desk_rectangle := RectangleShape2D.new()
	desk_rectangle.size = Vector2(190, 48)
	desk_shape.shape = desk_rectangle
	desk_collider.add_child(desk_shape)
	add_child(desk_collider)

	player = CharacterBody2D.new()
	player.name = "Player"
	player.position = Vector2(1800, 650)
	player.z_index = 3
	add_child(player)
	var shadow := Polygon2D.new()
	shadow.name = "Shadow"
	shadow.color = Color(0.11, 0.2, 0.2, 0.22)
	shadow.polygon = PackedVector2Array([Vector2(-12, 2), Vector2(-8, -3), Vector2(8, -3), Vector2(12, 2), Vector2(8, 6), Vector2(-8, 6)])
	player.add_child(shadow)
	player_sprite = AnimatedSprite2D.new()
	player_sprite.name = "PlayerSprite"
	player_sprite.sprite_frames = _player_frames()
	player_sprite.scale = Vector2(0.19, 0.19)
	player_sprite.position = Vector2(0, -56)
	player.add_child(player_sprite)
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 13.0
	collision.shape = shape
	collision.position = Vector2(0, -7)
	player.add_child(collision)
	camera = Camera2D.new()
	camera.name = "FollowCamera"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(WORLD_WIDTH)
	camera.limit_bottom = int(WORLD_HEIGHT)
	player.add_child(camera)
	camera.make_current()
	_update_sharon_draw_order()


func _update_sharon_draw_order() -> void:
	if not is_instance_valid(sharon) or not is_instance_valid(player):
		return
	# Smaller screen Y is behind the desk; larger screen Y is in front of it.
	sharon.z_index = 4 if player.global_position.y < 613.0 else 2


func _add_character_interaction(character_name: String, at: Vector2, lines: Array[String]) -> int:
	interactables.append({"name": character_name, "position": at, "kind": "person", "lines": lines})
	return interactables.size() - 1


func _make_npc(character_name: String, at: Vector2, frames: SpriteFrames, sprite_scale: float) -> Node2D:
	var body := Node2D.new()
	body.name = character_name
	body.position = at
	add_child(body)
	var sprite := AnimatedSprite2D.new()
	sprite.name = "Sprite"
	sprite.sprite_frames = frames
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.position = Vector2(0, -24)
	body.add_child(sprite)
	return body


func _player_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	_add_strip(frames, "front", PLAYER_SHEET, 0, 4, Vector2(306, 646), true, 8.0)
	# The sheet's first side-facing strip looks right; the second looks left.
	_add_strip(frames, "side_right", PLAYER_SHEET, 4, 4, Vector2(306, 646), true, 8.0)
	_add_strip(frames, "side_left", PLAYER_SHEET, 8, 4, Vector2(306, 646), true, 8.0)
	_add_strip(frames, "back", PLAYER_SHEET, 12, 4, Vector2(306, 646), true, 8.0)
	return frames


func _sharon_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("typing")
	frames.set_animation_loop("typing", true)
	frames.set_animation_speed("typing", 6.0)
	var texture := load(SHARON_SHEET) as Texture2D
	for index in 12:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		# Each 100 px frame pairs a standing pose with the seated computer setup.
		# Keep the full monitor, seated pose, keyboard, and desk while excluding the standing figure.
		atlas.region = Rect2(Vector2(index * 100 + 52, 14), Vector2(48, 22))
		frames.add_frame("typing", atlas)
	return frames


func _sam_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	_add_strip(frames, "walk_front", SAM_FRONT_SHEET, 0, 4, Vector2(1600, 1600), true, 10.0)
	_add_strip(frames, "walk_right", SAM_SIDE_SHEET, 0, 3, Vector2(1600, 1600), true, 10.0)
	# The side sheet changes facing direction halfway through; use its left-facing frames only.
	_add_strip(frames, "walk_left", SAM_SIDE_SHEET, 3, 3, Vector2(1600, 1600), true, 10.0)
	var back_sheet := _sam_back_sheet_upscaled()
	if back_sheet == null:
		# Keep Sam visible in Web builds if an imported back-facing texture is unavailable.
		_add_strip(frames, "walk_back", SAM_FRONT_SHEET, 0, 4, Vector2(1600, 1600), true, 8.0)
		return frames
	frames.add_animation("walk_back")
	frames.set_animation_loop("walk_back", true)
	frames.set_animation_speed("walk_back", 8.0)
	for index in 4:
		var atlas := AtlasTexture.new()
		atlas.atlas = back_sheet
		atlas.region = Rect2(Vector2(index * 1600, 0), Vector2(1600, 1600))
		frames.add_frame("walk_back", atlas)
	return frames


func _sam_back_sheet_upscaled() -> Texture2D:
	# Load the imported Texture2D through ResourceLoader so exported PCK/Web builds can access it.
	var back_texture := load(SAM_BACK_SHEET) as Texture2D
	if back_texture == null:
		return null
	var source := back_texture.get_image()
	if source == null or source.is_empty():
		return null
	var enlarged := Image.create(6400, 1600, false, Image.FORMAT_RGBA8)
	enlarged.fill(Color(0, 0, 0, 0))
	for index in 4:
		var frame := source.get_region(Rect2i(index * 100, 0, 100, 100))
		frame.resize(1600, 1600, Image.INTERPOLATE_NEAREST)
		enlarged.blit_rect(frame, Rect2i(0, 0, 1600, 1600), Vector2i(index * 1600, 0))
	return ImageTexture.create_from_image(enlarged)


func _maria_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	_add_vertical_strip(frames, "walk_front", 0, 4)
	_add_vertical_strip(frames, "walk_left", 4, 4)
	_add_vertical_strip(frames, "walk_right", 8, 4)
	_add_vertical_strip(frames, "walk_back", 12, 4)
	return frames


func _add_vertical_strip(frames: SpriteFrames, animation_name: String, start_frame: int, count: int) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, true)
	frames.set_animation_speed(animation_name, 8.0)
	var texture := load(MARIA_SHEET) as Texture2D
	for index in count:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(Vector2((start_frame + index) * 238, 0), Vector2(238, 646))
		frames.add_frame(animation_name, atlas)


func _add_strip(frames: SpriteFrames, animation_name: String, path: String, start_x: int, count: int, frame_size: Vector2, looping: bool, speed: float) -> void:
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, looping)
	frames.set_animation_speed(animation_name, speed)
	var texture := load(path) as Texture2D
	for index in count:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(Vector2((start_x + index) * frame_size.x, 0), frame_size)
		frames.add_frame(animation_name, atlas)


func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)
	floor_title = _label(hud, "LabTitle", "BIOLOGIQ  /  FLOOR 1", Vector2(24, 18), Vector2(430, 34), 21, Color("#143d47"))
	floor_title.add_theme_font_size_override("font_size", 21)
	var status := _label(hud, "PlayerStatus", "SHADOWING  ·  BIOLOGIQ RESEARCH TEAM", Vector2(24, 51), Vector2(760, 30), 14, Color("#42636a"))
	status.add_theme_font_size_override("font_size", 14)
	interaction_hint = _label(hud, "InteractionHint", "", Vector2(270, 645), Vector2(740, 32), 17, Color("#143d47"))
	interaction_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide_label = _label(hud, "GuidePrompt", "Speak to Sharon at the front desk", Vector2(0, 18), Vector2(1280, 38), 22, Color("#fff9e9"))
	guide_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide_label.add_theme_color_override("font_shadow_color", Color("#143d47"))
	guide_label.add_theme_constant_override("shadow_offset_x", 2)
	guide_label.add_theme_constant_override("shadow_offset_y", 2)
	guide_label.visible = not sam_intro_done
	if sam_intro_done:
		guide_label.text = "Follow Sam"
	if maria_meeting_done and not student_lab_task_received:
		guide_label.text = "Get to do list from Sharon"
		guide_label.show()
	if student_lab_task_received:
		guide_label.text = _intern_quarters_task_text()
		guide_label.show()
	var controls := _label(hud, "Controls", "WASD / Arrows Move   E Talk / Enter Room   Enter Continue   F Menu", Vector2(25, 688), Vector2(790, 25), 13, Color("#42636a"))
	controls.add_theme_font_size_override("font_size", 13)

	dialogue_panel = PanelContainer.new()
	dialogue_panel.name = "DialoguePanel"
	dialogue_panel.position = Vector2(205, 505)
	dialogue_panel.size = Vector2(870, 155)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#143d47")
	style.set_corner_radius_all(14)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 12
	style.content_margin_bottom = 10
	dialogue_panel.add_theme_stylebox_override("panel", style)
	dialogue_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	dialogue_panel.gui_input.connect(_on_dialogue_gui_input)
	hud.add_child(dialogue_panel)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 7)
	dialogue_panel.add_child(box)
	dialogue_label = Label.new()
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.add_theme_color_override("font_color", Color("#fff9e9"))
	dialogue_label.add_theme_font_size_override("font_size", 18)
	dialogue_label.custom_minimum_size = Vector2(810, 50)
	dialogue_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(dialogue_label)
	var hint := Label.new()
	hint.name = "DialogueHint"
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_color_override("font_color", Color("#b8d2c6"))
	hint.add_theme_font_size_override("font_size", 12)
	box.add_child(hint)
	dialogue_hint = hint
	dialogue_panel.hide()


func _label(parent: Node, node_name: String, text: String, at: Vector2, dimensions: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.position = at
	label.size = dimensions
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _build_menu() -> void:
	menu_layer = CanvasLayer.new()
	menu_layer.name = "Menu"
	add_child(menu_layer)
	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.12, 0.15, 0.68)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(shade)
	var card := PanelContainer.new()
	card.position = Vector2(440, 120)
	card.size = Vector2(400, 480)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("#fff9e9")
	card_style.set_corner_radius_all(18)
	card_style.content_margin_left = 30
	card_style.content_margin_right = 30
	card_style.content_margin_top = 24
	card_style.content_margin_bottom = 24
	card.add_theme_stylebox_override("panel", card_style)
	menu_layer.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	card.add_child(column)
	var heading := Label.new()
	heading.text = "PAUSED"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", Color("#143d47"))
	heading.add_theme_font_size_override("font_size", 28)
	column.add_child(heading)
	var progress_title := Label.new()
	progress_title.text = "DEMO PROGRESS"
	progress_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_title.add_theme_color_override("font_color", Color("#42636a"))
	progress_title.add_theme_font_size_override("font_size", 14)
	column.add_child(progress_title)
	demo_progress_bar = ProgressBar.new()
	demo_progress_bar.name = "DemoProgress"
	demo_progress_bar.min_value = 0.0
	demo_progress_bar.max_value = 100.0
	demo_progress_bar.value = _demo_progress_percent()
	demo_progress_bar.show_percentage = true
	demo_progress_bar.custom_minimum_size = Vector2(320, 22)
	var progress_background := StyleBoxFlat.new()
	progress_background.bg_color = Color("#e3e5d9")
	progress_background.set_corner_radius_all(8)
	demo_progress_bar.add_theme_stylebox_override("background", progress_background)
	var progress_fill := StyleBoxFlat.new()
	progress_fill.bg_color = Color("#5d9374")
	progress_fill.set_corner_radius_all(8)
	demo_progress_bar.add_theme_stylebox_override("fill", progress_fill)
	column.add_child(demo_progress_bar)
	var resume := _menu_button("Resume", "Resume", column)
	resume.pressed.connect(_close_menu)
	var home := _menu_button("Home", "Return to home", column)
	home.pressed.connect(func(): get_tree().change_scene_to_file("res://Scenes/main.tscn"))
	var save := _menu_button("Save", "Save game", column)
	save.pressed.connect(_on_save_pressed)
	menu_status_label = Label.new()
	menu_status_label.name = "SaveStatus"
	menu_status_label.text = "Saves locally and downloads an uploadable .sav backup in Web builds."
	menu_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_status_label.custom_minimum_size = Vector2(320, 34)
	menu_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_status_label.add_theme_color_override("font_color", Color("#42636a"))
	menu_status_label.add_theme_font_size_override("font_size", 12)
	column.add_child(menu_status_label)
	var quit := _menu_button("Quit", "Close application", column)
	quit.pressed.connect(func(): get_tree().quit())
	var esc_hint := Label.new()
	esc_hint.text = "ESC  Leave fullscreen"
	esc_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	esc_hint.add_theme_color_override("font_color", Color("#42636a"))
	column.add_child(esc_hint)
	menu_layer.hide()
	_update_demo_progress_bar()


func _demo_progress_percent() -> float:
	var progress := 0.0
	if sharon_checked_in:
		progress += 0.5
	if sam_intro_done:
		progress += 0.5
	if tour_phase >= 3:
		progress += 0.5
	if tour_phase >= 5:
		progress += 0.5
	if tour_phase >= 7 or maria_meeting_done:
		progress += 0.5
	if maria_meeting_done:
		progress += 1.0
	if student_lab_task_received:
		progress += 0.5
	var manager := get_node_or_null("/root/SaveManager")
	if intern_quarters_round >= 2:
		progress += 1.5
	if manager != null:
		if manager.is_student_lab_pipette_complete():
			progress += 0.5
		if manager.is_student_lab_dna_complete():
			progress += 0.5
		if manager.is_student_lab_data_complete():
			progress += 0.5
	if intern_quarters_round >= 2:
		progress += 0.5
	if farewell_done:
		progress += 0.5
	return minf(progress, 8.0)


func _update_demo_progress_bar() -> void:
	if is_instance_valid(demo_progress_bar):
		demo_progress_bar.value = _demo_progress_percent()


func _menu_button(node_name: String, text: String, parent: Node) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = Vector2(320, 44)
	button.add_theme_font_size_override("font_size", 18)
	parent.add_child(button)
	return button


func _on_save_pressed() -> void:
	var manager := get_node_or_null("/root/SaveManager")
	if manager == null:
		_on_save_status_changed("Save failed: save storage is unavailable.", true)
		return
	if OS.has_feature("web"):
		manager.export_save_to_file()
	else:
		manager.save_slot()


func _on_save_status_changed(message: String, is_error: bool) -> void:
	if menu_status_label == null:
		return
	menu_status_label.text = message
	menu_status_label.add_theme_color_override("font_color", Color("#a14f46") if is_error else Color("#42636a"))


func _interact() -> void:
	if farewell_done and player.global_position.distance_to(MAIN_ENTRANCE_EXIT_POSITION) <= INTERACT_DISTANCE:
		main_entry_open = true
		_refresh_map_door_art()
		_play_door_sound()
		await get_tree().create_timer(0.2).timeout
		get_tree().change_scene_to_file("res://Scenes/thank_you.tscn")
		return
	var nearby_door := _nearest_door()
	var enterable_door := _nearest_enterable_door()
	if not nearby_door.is_empty() and str(nearby_door.name) == "Talent Acquisition" and enterable_door.is_empty():
		_start_dialogue(_room_dialogue_for("Talent Acquisition"))
		return
	if not enterable_door.is_empty():
		open_door_name = str(enterable_door.name)
		_refresh_map_door_art()
		_play_door_sound()
		await get_tree().create_timer(0.2).timeout
		var save_manager := get_node_or_null("/root/SaveManager")
		if save_manager != null:
			save_manager.remember_room_entry_position(enterable_door.position + Vector2(0, 80))
		get_tree().change_scene_to_file("res://Scenes/Rooms/internship_room.tscn")
		return
	if not nearby_door.is_empty():
		var room_lines := _room_dialogue_for(str(nearby_door.name))
		if room_lines.is_empty():
			room_lines = ["This room is not available in the demo"]
		_start_dialogue(room_lines)
		return
	var target := _nearest_interactable()
	if target.is_empty():
		return
	if str(target.name) == "Sharon O'Riley":
		if not sharon_checked_in:
			_start_dialogue(["Sharon: Name? …Ah, right. The new intern? Hold on while I pull up your file…"], true)
		elif intern_quarters_round == 1 and student_lab_task_received and _intern_quarters_tasks_complete():
			dialogue_completes_second_task_list = true
			_start_dialogue([
				"Sharon: Done already?",
				"Sharon: Most interns (and some employees) usually take all day to get that stuff done",
				"Sharon: I suppose I could give you more to do",
				"Sharon: Come back to me once you finish everything on this new list"
			])
		elif intern_quarters_round >= 2 and student_lab_task_received and _intern_quarters_tasks_complete() and not farewell_done:
			_begin_sam_farewell_entrance()
		elif maria_meeting_done and not student_lab_task_received:
			dialogue_completes_student_lab_task = true
			_start_dialogue([
				"Sharon: I see Sam is finally done showing you around",
				"Sharon: Here's your task list for the day.",
				"Sharon: Go to the intern quarters to begin working"
			])
		else:
			_start_dialogue(["Sharon is busy right now"], false, true, "Sharon")
	elif str(target.name) == "Sam" and not tour_moving and tour_phase in [2, 4, 6]:
		dialogue_completes_tour_stop = true
		_start_dialogue(_tour_lines_for_phase(tour_phase), false, true, "Sam")
	else:
		_start_dialogue(target.lines)


func _start_dialogue(lines: Array, completes_checkin: bool = false, is_npc_dialogue: bool = false, speaker: String = "") -> void:
	dialogue_lines.clear()
	for line in lines:
		dialogue_lines.append(str(line))
	if dialogue_lines.is_empty():
		return
	dialogue_index = 0
	dialogue_completes_checkin = completes_checkin
	npc_dialogue_active = is_npc_dialogue
	dialogue_voice = speaker
	for line in dialogue_lines:
		for character in CHARACTER_VOICES:
			if line.begins_with(character + ":"):
				npc_dialogue_active = true
				if dialogue_voice.is_empty():
					dialogue_voice = character
				break
	dialogue_open = true
	dialogue_panel.show()
	_show_dialogue_line()


func _show_dialogue_line() -> void:
	dialogue_label.text = dialogue_lines[dialogue_index]
	for character in CHARACTER_VOICES:
		if dialogue_label.text.begins_with(character + ":"):
			dialogue_voice = character
			break
	if npc_dialogue_active:
		talking_audio.stop()
		var voice_path: String = CHARACTER_VOICES.get(dialogue_voice, "")
		if not voice_path.is_empty():
			talking_audio.stream = load(voice_path) as AudioStream
			talking_audio.play()
	dialogue_label.visible_characters = 0
	dialogue_type_progress = 0.0
	dialogue_typing = not dialogue_label.text.is_empty()
	dialogue_hint.text = "Click or press Enter to reveal" if dialogue_typing else "Click or press Enter to continue"


func _advance_dialogue() -> void:
	if dialogue_typing:
		dialogue_label.visible_characters = -1
		dialogue_typing = false
		talking_audio.stop()
		dialogue_hint.text = "Click or press Enter to continue"
		return
	if dialogue_index + 1 < dialogue_lines.size():
		dialogue_index += 1
		_show_dialogue_line()
	else:
		if dialogue_completes_checkin:
			sharon_checked_in = true
			dialogue_completes_checkin = false
			_begin_sam_entrance()
		if dialogue_completes_sam_intro:
			sam_intro_done = true
			dialogue_completes_sam_intro = false
			tour_phase = 1
			guide_label.text = "Follow Sam"
			guide_label.show()
			_begin_tour_walk()
		if dialogue_completes_tour_stop:
			dialogue_completes_tour_stop = false
			_begin_next_tour_leg()
		if dialogue_completes_maria_lines:
			dialogue_completes_maria_lines = false
			_begin_maria_exit()
		if dialogue_completes_sam_final_lines:
			dialogue_completes_sam_final_lines = false
			_begin_sam_exit()
		if dialogue_completes_student_lab_task:
			dialogue_completes_student_lab_task = false
			student_lab_task_received = true
			guide_label.text = _intern_quarters_task_text()
			guide_label.show()
			var save_manager := get_node_or_null("/root/SaveManager")
			if save_manager != null:
				save_manager.set_save_state(capture_save_state())
		if dialogue_completes_second_task_list:
			dialogue_completes_second_task_list = false
			intern_quarters_round = 2
			student_lab_task_received = true
			var save_manager := get_node_or_null("/root/SaveManager")
			if save_manager != null:
				save_manager.reset_intern_quarters_tasks()
			guide_label.text = "Go to the intern quarters"
			guide_label.show()
			if save_manager != null:
				save_manager.set_save_state(capture_save_state())
		if dialogue_completes_farewell:
			dialogue_completes_farewell = false
			_begin_sam_farewell_exit()
		_close_dialogue()


func _on_dialogue_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and dialogue_open:
		_advance_dialogue()
		dialogue_panel.accept_event()


func _begin_sam_entrance() -> void:
	if sam_entrance_active or sam_intro_done:
		return
	sam_entrance_active = true
	guide_label.text = "Sam is coming to meet you..."
	guide_label.show()
	interaction_hint.text = ""
	sam.position = Vector2(maxf(player.global_position.x + 360.0, 2320.0), player.global_position.y + 10.0)
	sam.show()
	_set_sam_walk_animation("walk_left")
	var target_position := Vector2(player.global_position.x + 58.0, player.global_position.y + 10.0)
	var walk_duration := maxf(0.8, sam.position.distance_to(target_position) / SAM_WALK_SPEED)
	var entrance := create_tween()
	entrance.tween_property(sam, "position", target_position, walk_duration)
	entrance.finished.connect(_on_sam_arrived)


func _on_sam_arrived() -> void:
	_set_sam_walk_animation("walk_left")
	sam_sprite.stop()
	sam_entrance_active = false
	dialogue_completes_sam_intro = true
	_start_dialogue([
		"Sam: I’ve got it from here, Sharon! Hey there, new hire!",
		"Sharon: She’s not here for a job, Sam. She’s here for the internship. And don’t you have work to be ignoring somewhere else?",
		"Sam: Oh I’m just joking around. Come on, follow me. I’m your official tour guide today!",
		"Sam: For today you'll only be using the intern quarters"
	])


func _begin_sam_farewell_entrance() -> void:
	if farewell_scene_active:
		return
	farewell_scene_active = true
	guide_label.text = "Sam is coming to say goodnight..."
	guide_label.show()
	interaction_hint.text = ""
	sam.position = Vector2(player.global_position.x + 520.0, player.global_position.y + 10.0)
	sam.show()
	_set_sam_walk_animation("walk_left")
	var target_position := Vector2(player.global_position.x + 58.0, player.global_position.y + 10.0)
	var arrival := create_tween()
	arrival.tween_property(sam, "position", target_position, maxf(0.8, sam.position.distance_to(target_position) / SAM_WALK_SPEED))
	arrival.finished.connect(_on_sam_farewell_arrived)


func _on_sam_farewell_arrived() -> void:
	_set_sam_walk_animation("walk_left")
	sam_sprite.stop()
	dialogue_completes_farewell = true
	_start_dialogue([
		"Sam: Phew, we survived. See you tomorrow!",
		"Sharon: Hmph. You didn’t break anything on day one. Better luck tomorrow. Goodnight."
	])


func _begin_sam_farewell_exit() -> void:
	var entrance_hall_position := Vector2(1800.0, sam.position.y)
	var inside_entry_position := Vector2(1800.0, 154.0)
	var outside_position := Vector2(1800.0, 48.0)
	_set_sam_walk_animation("walk_left")
	var exit_tween := create_tween()
	exit_tween.tween_property(sam, "position", entrance_hall_position, maxf(0.8, sam.position.distance_to(entrance_hall_position) / SAM_WALK_SPEED))
	exit_tween.tween_callback(_set_sam_walk_animation.bind("walk_back"))
	exit_tween.tween_property(sam, "position", inside_entry_position, maxf(0.8, absf(sam.position.y - inside_entry_position.y) / SAM_WALK_SPEED))
	exit_tween.tween_property(sam, "position", outside_position, 0.7)
	exit_tween.finished.connect(_on_sam_farewell_exit_finished)


func _on_sam_farewell_exit_finished() -> void:
	sam.hide()
	farewell_scene_active = false
	farewell_done = true
	guide_label.text = "Exit the building to go home"
	guide_label.show()
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null:
		save_manager.set_save_state(capture_save_state())
	_update_interaction_hint()


func _tour_lines_for_phase(phase: int) -> Array[String]:
	match phase:
		2:
			return [
				"Sam: In biotechnology, scientific discoveries can’t fund themselves! We need commercial and regulatory jobs to turn breakthroughs into real products.",
				"Sam: (Those federal agencies would be real upset if we couldn’t meet their standards)",
				"Sam: This is the East Wing, featuring non-scientific business & operational roles that maintain proper structure within a biotechnology company. Fundamental teams include Quality Assurance (QA), Regulatory Affairs (RA), Administration, and Marketing & Sales. These are important to the operations of these companies because they allow for the legal, financial, and safety compliances required to proceed with experimentation and production."
			]
		4:
			return [
				"Sam: This is the South Wing.",
				"Sam: There are many branches in biotechnology, all of which use living organisms or their processes to make products that help us.",
				"Sam: Some fields combat pollution. Others combat diseases. All are extremely important to improving the world."
			]
		6:
			return [
				"Sam: Finally, this is the West Wing. You will be doing all lab work in the Intern Quarters.",
				"Sam: Besides that, we also have a lab for the college students.",
				"Sam: And, if you ever want to find real-world opportunities near you, check out the Community Connections Center! You’ll be able to take your career exploration to the next level there."
			]
	return []


func _room_dialogue_for(room_name: String) -> Array[String]:
	match room_name:
		"Community Connections Center":
			return [
				"The Community Connections Center is a place where students of all ages can visit to find real-world job opportunities, information, and experiences! It allows players to explore real, postsecondary and career options in your community, learn from real professionals, and see what you can do in your future! Explore educational requirements and find your unique pathway to success.",
				"Currently locked for the demo."
			]
		"Talent Acquisition":
			return [
				"This is the door leading to the Interns’ Quarters.",
				"Shadow a lab technician, perform scientific procedures, and analyze data like a professional.",
				"The Interns’ Quarters allows players to get a feel for different procedures and roles they may play while shadowing a lab technician, or other related professionals in the field of experimental sciences!"
			]
		"Intern Quarters":
			return [
				"Currently locked.",
				"Shadow a lab technician, perform scientific procedures, and analyze data like a professional."
			]
		"College Lab":
			return [
				"This is the door leading to the Collegiate Lab Space.",
				"The Collegiate Lab Space is where college-level interns can experience more in-depth procedures that require more advanced levels of precision and knowledge. Collegiate interns use this space to complete their daily tasks, or prepare for higher-level job opportunities within the facility.",
				"Unauthorized access: player is not at collegiate level."
			]
		"Industrial":
			return [
				"This is the door leading to the Industrial Department.",
				"Our goal is to make sustainable products and energy.",
				"Research includes: bioremediation, bioplastics, and biofuels.",
				"Currently locked for the demo."
			]
		"Environmental":
			return [
				"This is the door leading to the Environmental Department.",
				"Our goal is to monitor and clean up environmental pollution for sustainable development.",
				"Research includes: bioremediation, wastewater treatment, climate management, and biosensors.",
				"Currently locked for the demo."
			]
		"Diagnostic Research":
			return [
				"This is the door leading to the Diagnostic Research Department.",
				"Our goal is to investigate and design biological tools that can detect, organize, and monitor diseases, conditions, or pathogens.",
				"Research includes DNA and protein synthesis and sequencing, forensics, and CRISPR/Cas technology.",
				"Currently locked for the demo."
			]
		"Aquatic":
			return [
				"This is the door leading to the Aquatic Department.",
				"Our goal is to develop sustainable solutions for medicine, food production, and the environment through living aquatic organisms.",
				"Research includes aquaculture, pharmaceuticals, and bioremediation.",
				"Currently locked for the demo."
			]
		"Agricultural":
			return [
				"This is the door leading to the Agricultural Department.",
				"Our goal is to modify living organisms and improve agricultural sustainability.",
				"Research includes: breeding livestock and plants, genetic engineering, and tissue cultures.",
				"Currently locked for the demo."
			]
		"Medical":
			return [
				"This is the door leading to the Medical Department.",
				"Our goal is to create products and technologies to prevent, diagnose, and treat human diseases.",
				"Research includes: medicines derived from plants, animals, and fungi, vaccine and gene therapy, and medicines from genetically engineered cells.",
				"Currently locked for the demo."
			]
		"Quality Control":
			return [
				"This is the door leading to the Quality Assurance Department.",
				"Quality Assurance is involved in regulating the final quality of a product. Focusing on the more internal systems of a company, this accounts for research required, clinical trial safety, and processes and system designs needed when producing a product",
				"Quality Assurance generally offers a clear entry path, plus a high, steady demand across manufacturing sites. However, it can be repetitive or involve more shift work, depending on the facility. This field is best if you enjoy routines, auditing, structure, and operational oversight with manufacturing and lab operations!"
			]
		"Regulatory Affairs":
			return [
				"This is the door leading to the Regulatory Affairs Department.",
				"Regulatory Affairs is the main connection between a Biotech company and government health agencies, like the FDA or EMA. Its primary focuses are working with legal compliances, negotiation with government scientists, strategizing for trials, and maintaining sight on post-market updates, such as usage of the product or acknowledgment of unexpected side effects.",
				"This pathway is fast paced, high pressure, and communication heavy. You must be strategic, because daily life can be unpredictable! There is generally a clear, linear progression when going through stages of this department that steers away from more scientific approaches."
			]
		"Administration":
			return [
				"This is the door leading to the Administration Department.",
				"The Administration Department includes sectors like HR, Finance, Legal, and Operations. It reflects more of a traditional corporate environment, with steady, well-defined hierarchical structure. This department also prioritizes stable, detail-oriented operations, like managing budgets and patents, or recruiting specialized personnel.",
				"Administrative jobs generally surround corporate operations, contract managements, budgeting, and collaborations with other departments. It typically involves a straightforward corporate career ladder that applies across several industries, though Intellectual Property (IP) lawyers or life-science recruiters may need specific knowledge in their domains."
			]
		"Marketing & Sales":
			return [
				"This is the door leading to the Marketing & Sales Department.",
				"Marketing & Sales professionals target scientists, healthcare professionals, corporate partners and investors. Every claim we make follows the strict guidelines set by federal agencies.",
				"We use credibility to translate scientific concepts to the public. It can take months to get products to the market, and purchasing decisions require Administration and Regulatory Affairs. Our goal is to prove the science behind our work, build partnerships, and increase market size."
			]
	return []


func _begin_tour_walk() -> void:
	if tour_moving:
		return
	tour_moving = true
	guide_label.text = "Follow Sam"
	guide_label.show()
	interaction_hint.text = ""
	var route: Array[Vector2] = []
	match tour_phase:
		1:
			route.append(Vector2(2770, 650))
		3:
			route.append(Vector2(1800, 650))
			route.append(Vector2(1800, 900))
			route.append(Vector2(1800, 1570))
		5:
			route.append(Vector2(1800, 900))
			route.append(Vector2(830, 900))
			route.append(Vector2(830, 650))
	if route.is_empty():
		tour_moving = false
		return
	var tour_tween := create_tween()
	var segment_start := sam.global_position
	for waypoint in route:
		var segment_delta := waypoint - segment_start
		var walk_animation := "walk_front"
		if absf(segment_delta.x) > absf(segment_delta.y):
			walk_animation = "walk_right" if segment_delta.x > 0.0 else "walk_left"
		else:
			walk_animation = "walk_front" if segment_delta.y > 0.0 else "walk_back"
		tour_tween.tween_callback(_set_sam_walk_animation.bind(walk_animation))
		tour_tween.tween_property(sam, "position", waypoint, maxf(0.4, segment_delta.length() / SAM_WALK_SPEED))
		segment_start = waypoint
	tour_tween.finished.connect(_on_tour_stop_arrived)


func _set_sam_walk_animation(animation_name: String) -> void:
	# Align each sheet's character bounds to the same feet point and center so turns don't snap.
	match animation_name:
		"walk_front": sam_sprite.position = Vector2(37, -32)
		"walk_right": sam_sprite.position = Vector2(79, -18)
		"walk_left": sam_sprite.position = Vector2(-79, -18)
		"walk_back": sam_sprite.position = Vector2(82, -9)
	sam_sprite.play(animation_name)


func _on_tour_stop_arrived() -> void:
	tour_moving = false
	sam_sprite.stop()
	sam_last_stop_position = sam.global_position
	tour_phase += 1
	if tour_phase == 6:
		_set_sam_walk_animation("walk_right")
		sam_sprite.stop()
	guide_label.text = "Talk to Sam"
	guide_label.show()
	_update_sam_interactable()


func _begin_next_tour_leg() -> void:
	if sam_last_stop_position != Vector2.ZERO:
		sam.global_position = sam_last_stop_position
	if tour_phase == 2:
		tour_phase = 3
	elif tour_phase == 4:
		tour_phase = 5
	elif tour_phase == 6:
		tour_phase = 7
		_begin_maria_scene()
		return
	_begin_tour_walk()


func _begin_maria_scene() -> void:
	if maria_meeting_done or maria_scene_active:
		return
	maria_scene_active = true
	guide_label.text = "Meet Maria"
	guide_label.show()
	interaction_hint.text = ""
	maria.position = Vector2(player.global_position.x + 520.0, player.global_position.y)
	maria.show()
	_set_maria_walk_animation("walk_left")
	var target_position := Vector2(player.global_position.x + 80.0, player.global_position.y)
	var arrival := create_tween()
	arrival.tween_property(maria, "position", target_position, maxf(0.8, maria.position.distance_to(target_position) / MARIA_WALK_SPEED))
	arrival.finished.connect(_on_maria_arrived)


func _set_maria_walk_animation(animation_name: String) -> void:
	maria_sprite.play(animation_name)


func _on_maria_arrived() -> void:
	maria_sprite.stop()
	dialogue_completes_maria_lines = true
	_start_dialogue([
		"Maria: Morning, Sam. Is this our new intern?",
		"Sam: Sure is! Fresh off onboarding.",
		"Maria: Welcome to BIOLOGIQ. I’m Dr. Valadez. I lead the doctoral department’s target-discovery team. We work on high-throughput screening and gene therapies. Demanding work, but it’s incredibly rewarding.",
		"Maria: I’ll let Sam get you settled at your station, but good luck on your first lab run today. I’m sure you’ll do great."
	])


func _begin_maria_exit() -> void:
	_set_maria_walk_animation("walk_right")
	var offscreen_position := Vector2(player.global_position.x + 1000.0, maria.position.y)
	var departure := create_tween()
	departure.tween_property(maria, "position", offscreen_position, maxf(0.8, maria.position.distance_to(offscreen_position) / MARIA_WALK_SPEED))
	departure.finished.connect(_on_maria_exit_finished)


func _on_maria_exit_finished() -> void:
	maria.hide()
	dialogue_completes_sam_final_lines = true
	_start_dialogue([
		"Sam: Man…she's awesome. Anyway! You should go to Sharon to pick up your task list.",
		"Sam: I’ll be waiting in the Intern Quarters for you after you talk to Sharon. I can’t let the new intern wander around the lab all by themselves!",
		"Sam: (Not again)"
	])


func _begin_sam_exit() -> void:
	_set_sam_walk_animation("walk_right")
	var offscreen_position := Vector2(player.global_position.x + 1100.0, sam.position.y)
	var departure := create_tween()
	departure.tween_property(sam, "position", offscreen_position, maxf(0.8, sam.position.distance_to(offscreen_position) / SAM_WALK_SPEED))
	departure.finished.connect(_on_sam_exit_finished)


func _on_sam_exit_finished() -> void:
	sam.hide()
	maria_meeting_done = true
	maria_scene_active = false
	guide_label.text = "Get to do list from Sharon"
	guide_label.show()
	_update_interaction_hint()


func _update_sam_interactable() -> void:
	if sam_interaction_index < 0 or not is_instance_valid(sam):
		return
	var sam_interaction: Dictionary = interactables[sam_interaction_index]
	sam_interaction["position"] = sam.global_position
	interactables[sam_interaction_index] = sam_interaction


func _close_dialogue() -> void:
	dialogue_open = false
	npc_dialogue_active = false
	talking_audio.stop()
	dialogue_completes_checkin = false
	dialogue_completes_sam_intro = false
	dialogue_completes_tour_stop = false
	dialogue_completes_maria_lines = false
	dialogue_completes_sam_final_lines = false
	dialogue_completes_student_lab_task = false
	dialogue_completes_second_task_list = false
	dialogue_completes_farewell = false
	dialogue_panel.hide()
	_update_interaction_hint()


func _setup_audio() -> void:
	talking_audio = AudioStreamPlayer.new()
	talking_audio.name = "NpcTalkingAudio"
	talking_audio.stream = load(TALKING_SOUND) as AudioStream
	talking_audio.volume_db = -14.0
	add_child(talking_audio)


func _play_door_sound() -> void:
	var sound := AudioStreamPlayer.new()
	sound.stream = load(DOOR_SOUND) as AudioStream
	sound.volume_db = -5.0
	get_tree().root.add_child(sound)
	sound.finished.connect(sound.queue_free)
	sound.play()


func _nearest_enterable_door() -> Dictionary:
	if not student_lab_task_received:
		return {}
	var door := _nearest_door()
	if not door.is_empty() and str(door.name) == "Talent Acquisition":
		return door
	return {}


func _intern_quarters_tasks_complete() -> bool:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null:
		return false
	return save_manager.is_student_lab_pipette_complete() \
		and save_manager.is_student_lab_dna_complete() \
		and save_manager.is_student_lab_data_complete()


func _intern_quarters_task_text() -> String:
	if _intern_quarters_tasks_complete():
		if intern_quarters_round == 1:
			return "Return to Sharon"
		return "Exit the building to go home" if farewell_done else "All tasks completed! Return to Sharon"
	return "Go to the intern quarters"


func _nearest_door() -> Dictionary:
	var closest: Dictionary = {}
	var closest_distance := INTERACT_DISTANCE
	for room in room_doors:
		var distance: float = player.global_position.distance_to(room.position)
		if distance < closest_distance:
			closest = room
			closest_distance = distance
	return closest


func _nearest_interactable() -> Dictionary:
	var closest: Dictionary = {}
	var closest_distance := INTERACT_DISTANCE
	for target in interactables:
		var distance: float = player.global_position.distance_to(target.position)
		if distance < closest_distance:
			closest = target
			closest_distance = distance
	return closest


func _is_walkable_position(at: Vector2) -> bool:
	for floor_region in get_node("MapArt/Floors").get_children():
		if not bool(floor_region.get_meta("walkable", false)):
			continue
		var floor_size: Vector2 = floor_region.get_meta("floor_size", Vector2.ZERO)
		if Rect2(Vector2.ZERO, floor_size).has_point(floor_region.to_local(at)):
			return true
	return false


func _update_interaction_hint() -> void:
	if dialogue_open or menu_open or sam_entrance_active or tour_moving or maria_scene_active or farewell_scene_active:
		interaction_hint.text = ""
		return
	if farewell_done and player.global_position.distance_to(MAIN_ENTRANCE_EXIT_POSITION) <= INTERACT_DISTANCE:
		interaction_hint.text = "E  Exit the building"
		return
	var enterable_door := _nearest_enterable_door()
	if not enterable_door.is_empty():
		interaction_hint.text = "E  Enter Talent Acquisition"
		return
	if not _nearest_door().is_empty():
		interaction_hint.text = "E  Check room availability"
		return
	var target := _nearest_interactable()
	if target.is_empty():
		interaction_hint.text = ""
	else:
		interaction_hint.text = "E  Talk to %s" % str(target.name)


func _update_player_animation(is_moving: bool) -> void:
	if player_sprite == null:
		return
	var animation := "front"
	match player_facing:
		"left": animation = "side_left"
		"right": animation = "side_right"
		"up": animation = "back"
	if is_moving:
		if player_sprite.animation != animation or not player_sprite.is_playing():
			player_sprite.play(animation)
	else:
		if player_sprite.animation != animation:
			player_sprite.play(animation)
		player_sprite.stop()
		player_sprite.frame = 0


func _toggle_menu() -> void:
	menu_open = not menu_open
	menu_layer.visible = menu_open
	_update_demo_progress_bar()
	_update_interaction_hint()


func _close_menu() -> void:
	menu_open = false
	menu_layer.hide()
	_update_interaction_hint()
