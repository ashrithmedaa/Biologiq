extends Node2D

const SHARON_SHEET := "res://Art Assets/Sharon O_Riley - Typing.png"
const PLAYER_SHEET := "res://Art Assets/Player - Walking Animations (Front, Side, Back).png"
const SAM_FRONT_SHEET := "res://Art Assets/Sam - Front walking spritesheet transparent.png"
const SAM_SIDE_SHEET := "res://Art Assets/Sam - Side walking spritesheet.png"
const SAM_BACK_SHEET := "res://Art Assets/Sam walking - Back spritesheet.png"
const MAIN_ENTRANCE_POSITION := Vector2(1800, 390)
const WALK_SPEED := 230.0
const SAM_WALK_SPEED := 250.0
const DIALOGUE_CHARACTERS_PER_SECOND := 38.0
const INTERACT_DISTANCE := 78.0
const WORLD_WIDTH := 3600.0
const WORLD_HEIGHT := 2400.0
const DOOR_HEIGHT := 148.0
const SIDE_DOOR_HEIGHT := 80.0

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
var floor_title: Label
var menu_layer: CanvasLayer
var menu_status_label: Label
var dialogue_lines: Array[String] = []
var dialogue_index := 0
var dialogue_open := false
var dialogue_typing := false
var dialogue_type_progress := 0.0
var dialogue_completes_checkin := false
var dialogue_completes_sam_intro := false
var sharon_checked_in := false
var sam_intro_done := false
var sam_entrance_active := false
var tour_phase := 0
var tour_moving := false
var dialogue_completes_tour_stop := false
var menu_open := false
var player_facing := "down"
var interactables: Array[Dictionary] = []
var room_doors: Array[Dictionary] = []
var player_program := "Research Shadowing"
var player_status := "Master's"
var side_door_texture: Texture2D


func _ready() -> void:
	_setup_input()
	_load_player_status()
	_build_map()
	_build_characters()
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null:
		save_manager.register_state_provider(self)
		restore_save_state(save_manager.get_save_state())
		save_manager.take_room_return_position(MAIN_ENTRANCE_POSITION)
	player.global_position = MAIN_ENTRANCE_POSITION
	if sam_intro_done and tour_phase == 0:
		tour_phase = 1
		if sam_last_stop_position == Vector2.ZERO:
			sam.global_position = player.global_position + Vector2(58, 10)
	_build_hud()
	_build_menu()
	if sharon_checked_in and not sam_intro_done:
		_begin_sam_entrance()
	elif sam_intro_done:
		sam.show()
		if tour_phase in [1, 3, 5]:
			_begin_tour_walk()
		elif tour_phase in [2, 4, 6]:
			guide_label.text = "Talk to Sam"
			guide_label.show()
		elif tour_phase >= 7:
			guide_label.text = "Tour complete"
			guide_label.show()
	if save_manager != null:
		save_manager.status_changed.connect(_on_save_status_changed)
	_update_player_animation(false)


func _physics_process(_delta: float) -> void:
	if dialogue_open or menu_open or sam_entrance_active:
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
		dialogue_hint.text = "Click or press Enter to continue"


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		elif dialogue_open:
			_close_dialogue()
		elif menu_open:
			_close_menu()
		return
	if event.keycode == KEY_F and not dialogue_open:
		_toggle_menu()
		return
	if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		if dialogue_open:
			_advance_dialogue()
		return
	if event.keycode == KEY_E and not dialogue_open and not menu_open:
		if sam_entrance_active:
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
	# First-floor rooms form the broad crossbar, with the entrance centered below the sign.
	_add_room("Intern Quarters", Rect2(320, 210, 300, 240), Vector2(470, 450))
	_add_room("Student Lab", Rect2(660, 210, 300, 240), Vector2(810, 450))
	_add_room("Reception", Rect2(1000, 210, 300, 240), Vector2(1150, 450))
	_add_room("College Lab", Rect2(2300, 210, 300, 240), Vector2(2450, 450))
	_add_room("Low College Lab", Rect2(2640, 210, 300, 240), Vector2(2790, 450))
	_add_room("Job Quarters", Rect2(2980, 210, 300, 240), Vector2(3130, 450))

	# The research wing forms the long stem below the first-floor crossbar.
	_add_room("Bachelor's Lab", Rect2(900, 1120, 500, 250), Vector2(1400, 1330), "right")
	_add_room("Molecular Biology", Rect2(900, 1420, 500, 250), Vector2(1400, 1630), "right")
	_add_room("Biochemistry", Rect2(900, 1720, 500, 250), Vector2(1400, 1930), "right")
	_add_room("Masters Suite", Rect2(2200, 1120, 500, 250), Vector2(2200, 1330), "left")
	_add_room("Advanced Research", Rect2(2200, 1420, 500, 250), Vector2(2200, 1630), "left")
	_add_room("Graduate Suite", Rect2(2200, 1720, 500, 250), Vector2(2200, 1930), "left")

	_add_object("Large succulent", Vector2(1510, 740), "A healthy succulent brightens the reception hall.", "inspect")
	_add_object("Stairwell", Vector2(1800, 960), "The stairwell connects the first-floor cross hall to the research wing.", "inspect")
	_build_side_door_sprites()
	queue_redraw()


func _add_room(room_name: String, room_rect: Rect2, door_position: Vector2, door_side: String = "bottom") -> void:
	room_doors.append({"name": room_name, "room_rect": room_rect, "position": door_position, "side": door_side})


func _build_side_door_sprites() -> void:
	side_door_texture = _make_side_door_texture()
	for room in room_doors:
		var side := str(room.get("side", "bottom"))
		if side != "left" and side != "right":
			continue
		var door: Vector2 = room.position
		var sprite := Sprite2D.new()
		sprite.name = "%sClosedDoor" % str(room.name).replace(" ", "")
		sprite.texture = side_door_texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.flip_h = side == "left"
		sprite.position = Vector2(door.x + 10.0 if side == "right" else door.x - 10.0, door.y)
		add_child(sprite)


func _make_side_door_texture() -> ImageTexture:
	var image := Image.create(20, int(SIDE_DOOR_HEIGHT), false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_image_rect(image, Rect2i(0, 0, 8, int(SIDE_DOOR_HEIGHT)), Color("#81563b"))
	_image_rect(image, Rect2i(2, 0, 3, int(SIDE_DOOR_HEIGHT)), Color("#a87550"))
	for y in [8, 38, 69]:
		_image_rect(image, Rect2i(0, y, 8, 3), Color("#704932"))
	for y in range(56, 63):
		for x in range(10, 17):
			if Vector2(x - 13, y - 59).length_squared() <= 10.0:
				image.set_pixel(x, y, Color("#f3d28a"))
	return ImageTexture.create_from_image(image)


func _image_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			image.set_pixel(x, y, color)


func _add_object(object_name: String, at: Vector2, description: String, kind: String) -> void:
	interactables.append({"name": object_name, "position": at, "kind": kind, "description": description})


func _build_characters() -> void:
	# Use only the seated figure from each sprite-sheet frame; the standing pose is a separate figure in the same cell.
	var sharon := _make_npc("Sharon", Vector2(2070, 590), _sharon_frames(), 3.4)
	var sharon_sprite := sharon.get_node("Sprite") as AnimatedSprite2D
	sharon_sprite.position = Vector2(0, -72)
	sharon_sprite.play("typing")
	_add_character_interaction("Sharon O'Riley", sharon.position, [])
	sam = _make_npc("Sam", Vector2(2320, 690), _sam_frames(), 0.19)
	sam_sprite = sam.get_node("Sprite") as AnimatedSprite2D
	_set_sam_walk_animation("walk_left")
	sam_sprite.stop()
	sam.hide()
	sam_interaction_index = _add_character_interaction("Sam", sam.position, [])
	var desk_collider := StaticBody2D.new()
	desk_collider.name = "ReceptionDeskCollider"
	desk_collider.position = Vector2(2075, 594)
	var desk_shape := CollisionShape2D.new()
	var desk_rectangle := RectangleShape2D.new()
	desk_rectangle.size = Vector2(190, 48)
	desk_shape.shape = desk_rectangle
	desk_collider.add_child(desk_shape)
	add_child(desk_collider)

	player = CharacterBody2D.new()
	player.name = "Player"
	player.position = Vector2(1800, 650)
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
	for index in 6:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		# The 200 px cell shows both standing and seated poses. Crop only the seated figure's head and torso.
		atlas.region = Rect2(Vector2(index * 200 + 65, 0), Vector2(35, 36))
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
	var source := Image.load_from_file(SAM_BACK_SHEET)
	var enlarged := Image.create(6400, 1600, false, Image.FORMAT_RGBA8)
	enlarged.fill(Color(0, 0, 0, 0))
	for index in 4:
		var frame := source.get_region(Rect2i(index * 100, 0, 100, 100))
		frame.resize(1600, 1600, Image.INTERPOLATE_NEAREST)
		enlarged.blit_rect(frame, Rect2i(0, 0, 1600, 1600), Vector2i(index * 1600, 0))
	return ImageTexture.create_from_image(enlarged)


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
	var controls := _label(hud, "Controls", "WASD / Arrows Move   E Talk / Inspect   Enter Continue   F Menu", Vector2(25, 688), Vector2(790, 25), 13, Color("#42636a"))
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
	card.position = Vector2(440, 155)
	card.size = Vector2(400, 410)
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
	var target := _nearest_interactable()
	if target.is_empty():
		return
	var kind := str(target.kind)
	if kind == "person":
		if str(target.name) == "Sharon O'Riley" and not sharon_checked_in:
			_start_dialogue(["Sharon: Name? …Ah, right. The new intern? Hold on while I pull up your file…"], true)
		elif str(target.name) == "Sam" and not tour_moving and tour_phase in [2, 4, 6]:
			dialogue_completes_tour_stop = true
			_start_dialogue(_tour_lines_for_phase(tour_phase))
		else:
			_start_dialogue(target.lines)
		return
	_start_dialogue([str(target.description)])


func _start_dialogue(lines: Array, completes_checkin: bool = false) -> void:
	dialogue_lines.clear()
	for line in lines:
		dialogue_lines.append(str(line))
	if dialogue_lines.is_empty():
		return
	dialogue_index = 0
	dialogue_completes_checkin = completes_checkin
	dialogue_open = true
	dialogue_panel.show()
	_show_dialogue_line()


func _show_dialogue_line() -> void:
	dialogue_label.text = dialogue_lines[dialogue_index]
	dialogue_label.visible_characters = 0
	dialogue_type_progress = 0.0
	dialogue_typing = not dialogue_label.text.is_empty()
	dialogue_hint.text = "Click or press Enter to reveal" if dialogue_typing else "Click or press Enter to continue"


func _advance_dialogue() -> void:
	if dialogue_typing:
		dialogue_label.visible_characters = -1
		dialogue_typing = false
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
		"Sam: Oh I’m just joking around. Come on, follow me. I’m your official tour guide today!"
	])


func _tour_lines_for_phase(phase: int) -> Array[String]:
	match phase:
		2:
			return [
				"This is the college and Job Quarters wing.",
				"The College Lab and Low College Lab are along this hallway.",
				"The Job Quarters are at this end of the hall."
			]
		4:
			return [
				"This is our research and graduate wing.",
				"On this side are the Bachelor's Lab, Molecular Biology, and Biochemistry.",
				"Across the hall are the Master's Suite, Advanced Research, and Graduate Suite."
			]
		6:
			return [
				"This hallway has the Intern Quarters, Student Lab, and Reception.",
				"Reception is where you checked in.",
				"The Student Lab and Intern Quarters are down this wing."
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
			route.append(Vector2(3300, 650))
		3:
			route.append(Vector2(1800, 650))
			route.append(Vector2(1800, 900))
			route.append(Vector2(1800, 2180))
		5:
			route.append(Vector2(1800, 900))
			route.append(Vector2(400, 900))
			route.append(Vector2(400, 650))
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
		guide_label.text = "Tour complete"
		guide_label.show()
		return
	_begin_tour_walk()


func _update_sam_interactable() -> void:
	if sam_interaction_index < 0 or not is_instance_valid(sam):
		return
	var sam_interaction: Dictionary = interactables[sam_interaction_index]
	sam_interaction["position"] = sam.global_position
	interactables[sam_interaction_index] = sam_interaction


func _close_dialogue() -> void:
	dialogue_open = false
	dialogue_completes_checkin = false
	dialogue_completes_sam_intro = false
	dialogue_completes_tour_stop = false
	dialogue_panel.hide()
	_update_interaction_hint()


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
	# The player can move through the halls and stairwell. Room doors stay closed.
	var walkable_zones: Array[Rect2] = [
		Rect2(260, 450, 3080, 480),
		Rect2(1542, 140, 516, 310),
		Rect2(1400, 850, 800, 300),
		Rect2(1400, 1090, 800, 1120),
	]
	for zone in walkable_zones:
		if zone.has_point(at):
			return true
	return false


func _update_interaction_hint() -> void:
	if dialogue_open or menu_open or sam_entrance_active or tour_moving:
		interaction_hint.text = ""
		return
	var target := _nearest_interactable()
	if target.is_empty():
		interaction_hint.text = ""
	elif str(target.kind) == "person":
		interaction_hint.text = "E  Talk to %s" % str(target.name)
	else:
		interaction_hint.text = "E  Inspect %s" % str(target.name)


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
	_update_interaction_hint()


func _close_menu() -> void:
	menu_open = false
	menu_layer.hide()
	_update_interaction_hint()


func _draw() -> void:
	# Campus lawn uses broad color patches and pixel tufts instead of a hard checker pattern.
	draw_rect(Rect2(0, 0, WORLD_WIDTH, WORLD_HEIGHT), Color("#789b61"))
	for x in range(0, int(WORLD_WIDTH), 96):
		for y in range(0, int(WORLD_HEIGHT), 96):
			var seed := (x * 17 + y * 31) % 17
			if seed < 6:
				draw_rect(Rect2(x + 12 + seed * 3, y + 14, 34 + seed, 14), Color("#6d9159"))
				draw_rect(Rect2(x + 22 + seed * 2, y + 22, 18, 10), Color("#73975d"))
			elif seed < 11:
				draw_rect(Rect2(x + 42, y + 50, 28, 12), Color("#88a96c"))
			if (x / 96 + y / 96) % 3 == 0:
				draw_line(Vector2(x + 74, y + 38), Vector2(x + 78, y + 28), Color("#597f50"), 3.0)
				draw_line(Vector2(x + 78, y + 38), Vector2(x + 84, y + 30), Color("#628a52"), 3.0)
				draw_line(Vector2(x + 82, y + 38), Vector2(x + 86, y + 32), Color("#597f50"), 3.0)
	_draw_hallway()
	_draw_room_zones()
	_draw_stairwell_and_walkway()
	_draw_furniture_and_objects()


func _draw_hallway() -> void:
	# A wide first-floor crossbar joined to a narrower research wing below forms the T plan.
	_draw_pixel_panel(Rect2(240, 140, 3120, 820), Color("#192787"), Color("#d6dfc2"))
	_draw_pixel_panel(Rect2(880, 920, 1840, 1320), Color("#192787"), Color("#d6dfc2"))
	_draw_tile_floor(Rect2(260, 450, 3080, 480))
	_draw_tile_floor(Rect2(1400, 930, 800, 180))
	_draw_tile_floor(Rect2(1400, 1090, 800, 1120))
	draw_rect(Rect2(260, 438, 3080, 12), Color("#5D9374"))
	draw_rect(Rect2(260, 922, 3080, 10), Color("#8c6544"))
	draw_rect(Rect2(1400, 1080, 800, 10), Color("#5D9374"))
	draw_rect(Rect2(1400, 2200, 800, 10), Color("#8c6544"))
	# Hall lights repeat along each axis and lead the eye through the T.
	for x in range(500, 3300, 300):
		if x < 1500 or x > 2100:
			draw_rect(Rect2(x, 650, 120, 10), Color("#f7f0d9"))
			draw_rect(Rect2(x + 8, 652, 104, 3), Color("#fffbea"))
	for y in range(1220, 2180, 220):
		draw_rect(Rect2(1740, y, 120, 10), Color("#f7f0d9"))
		draw_rect(Rect2(1748, y + 2, 104, 3), Color("#fffbea"))


func _draw_pixel_panel(rect: Rect2, outline: Color, fill: Color) -> void:
	draw_rect(rect, outline)
	draw_rect(Rect2(rect.position + Vector2(12, 12), rect.size - Vector2(24, 24)), fill)
	# Thick baseboards and stepped wall caps echo the exterior laboratory art.
	draw_rect(Rect2(rect.position.x + 12, rect.position.y + 12, rect.size.x - 24, 12), Color("#5D9374"))
	draw_rect(Rect2(rect.position.x + 12, rect.end.y - 24, rect.size.x - 24, 12), Color("#8c6544"))
	for x in range(int(rect.position.x + 20), int(rect.end.x - 20), 64):
		draw_rect(Rect2(x, rect.position.y + 14, 32, 5), Color("#8BC8D8"))


func _draw_tile_floor(rect: Rect2) -> void:
	draw_rect(rect, Color("#e8e2cc"))
	for row in range(0, int(rect.size.y), 40):
		var y := rect.position.y + row
		var offset := 0 if (row / 40) % 2 == 0 else 32
		for x in range(int(rect.position.x) + offset, int(rect.end.x), 64):
			var tile := Rect2(x, y, 62, 38)
			draw_rect(tile, Color("#f2edda") if (x / 64 + row / 40) % 3 != 0 else Color("#e4ddc7"))
			draw_rect(tile, Color("#c9c5ae"), false, 1.0)
			draw_rect(Rect2(x + 4, y + 3, 54, 2), Color("#faf6e7"))


func _draw_room_zones() -> void:
	for room in room_doors:
		var rect: Rect2 = room.room_rect
		# Low sage walls define each room without boxing in the door artwork.
		draw_rect(rect.grow(4), Color("#5D9374"))
		draw_rect(rect, Color("#dedfc9"))
		for x in range(int(rect.position.x + 8), int(rect.end.x - 8), 40):
			draw_line(Vector2(x, rect.position.y + 8), Vector2(x, rect.end.y - 8), Color("#d2d6c0"), 1.0)
		for y in range(int(rect.position.y + 8), int(rect.end.y - 8), 40):
			draw_line(Vector2(rect.position.x + 8, y), Vector2(rect.end.x - 8, y), Color("#d2d6c0"), 1.0)
		draw_rect(Rect2(rect.position.x + 8, rect.position.y + 8, rect.size.x - 16, 8), Color("#5D9374"))
		draw_rect(Rect2(rect.position.x + 12, rect.position.y + 18, 26, 4), Color("#8BC8D8"))
		_draw_closed_door(room)


func _draw_closed_door(room: Dictionary) -> void:
	var door: Vector2 = room.position
	var room_name := str(room.name).to_upper()
	var side := str(room.get("side", "bottom"))
	if side == "left" or side == "right":
		# Side doors are independent sprites; this pass only draws their labels.
		var label_y := door.y - SIDE_DOOR_HEIGHT * 0.5 - 10.0
		draw_string(ThemeDB.fallback_font, Vector2(door.x - 82, label_y), room_name, HORIZONTAL_ALIGNMENT_CENTER, 164, 12, Color("#192787"))
	else:
		# The lower edge of each tall door meets the bottom wall of its room.
		var door_rect := Rect2(door.x - 34, door.y - DOOR_HEIGHT, 68.0, DOOR_HEIGHT)
		_draw_door_leaf(door_rect, false)
		var label_y := door_rect.position.y - 10.0
		draw_string(ThemeDB.fallback_font, Vector2(door.x - 82, label_y), room_name, HORIZONTAL_ALIGNMENT_CENTER, 164, 12, Color("#192787"))


func _draw_door_leaf(door: Rect2, hinges_on_right: bool) -> void:
	# Slim jambs, inset panels, hinges, and a brass handle make a closed wooden door.
	draw_rect(door, Color("#704932"))
	var inset := door.grow(-5.0)
	draw_rect(inset, Color("#9b6949"))
	var panel_height := (inset.size.y - 24.0) * 0.5
	for index in 2:
		var panel := Rect2(inset.position.x + 8.0, inset.position.y + 8.0 + index * (panel_height + 8.0), inset.size.x - 16.0, panel_height)
		draw_rect(panel, Color("#81563b"))
		draw_rect(panel.grow(-4.0), Color("#a87550"))
		draw_rect(Rect2(panel.position.x + 4.0, panel.position.y + 4.0, panel.size.x - 8.0, 2.0), Color("#c18b62"))
	var hardware_x := door.end.x - 7.0 if hinges_on_right else door.position.x + 2.0
	var handle_x := door.position.x + 14.0 if hinges_on_right else door.end.x - 14.0
	for hinge_y in [door.position.y + 12.0, door.end.y - 16.0]:
		draw_rect(Rect2(hardware_x, hinge_y, 5.0, 9.0), Color("#d7b66e"))
	draw_circle(Vector2(handle_x, door.position.y + door.size.y * 0.78), 4.0, Color("#f3d28a"))


func _draw_stairwell_and_walkway() -> void:
	# Entrance forecourt, closed front door, and a broad central stair connecting both floors.
	draw_rect(Rect2(1540, 0, 520, 140), Color("#aaa98e"))
	draw_rect(Rect2(1552, 0, 496, 140), Color("#d7cfb6"))
	for y in range(16, 140, 32):
		draw_line(Vector2(1552, y), Vector2(2048, y), Color("#b4ad96"), 2.0)
	for x in range(1584, 2048, 64):
		draw_line(Vector2(x, 0), Vector2(x, 140), Color("#b4ad96"), 2.0)
	_draw_tile_floor(Rect2(1542, 140, 516, 298))
	draw_rect(Rect2(1530, 140, 12, 298), Color("#5D9374"))
	draw_rect(Rect2(2058, 140, 12, 298), Color("#5D9374"))
	_draw_main_glass_entry()
	_draw_pixel_panel(Rect2(1400, 850, 800, 250), Color("#192787"), Color("#d6dfc2"))
	draw_rect(Rect2(1412, 862, 776, 226), Color("#e8e2cc"))
	for tread in 12:
		var y := 882 + tread * 17
		draw_rect(Rect2(1510, y, 580, 5), Color("#8c6544"))
		draw_rect(Rect2(1518, y - 4, 564, 4), Color("#f2edda"))
	draw_rect(Rect2(1494, 870, 10, 200), Color("#5D9374"))
	draw_rect(Rect2(2096, 870, 10, 200), Color("#5D9374"))


func _draw_main_glass_entry() -> void:
	# The shorter glazed double door sits at the building's outer edge in the vestibule opening.
	var left := 1542.0
	var top := 64.0
	var width := 516.0
	var height := 76.0
	draw_rect(Rect2(left, top, width, height), Color("#192787"))
	draw_rect(Rect2(left + 6, top + 6, width - 12, height - 12), Color("#6fabb1"))
	# Side lights and reflections frame the two central glass leaves.
	for x in [left + 18, left + 96, left + 174, left + 342, left + 420, left + 498]:
		draw_rect(Rect2(x, top + 10, 4, height - 20), Color("#d5eee0"))
		draw_rect(Rect2(x + 8, top + 14, 2, height - 28), Color("#9bd0c8"))
	# Central double leaves, meeting stile, and paired pull handles.
	draw_rect(Rect2(1694, top + 6, 106, height - 12), Color("#8bc8d8"))
	draw_rect(Rect2(1800, top + 6, 106, height - 12), Color("#79b7bb"))
	draw_rect(Rect2(1796, top + 6, 8, height - 12), Color("#192787"))
	draw_rect(Rect2(1778, top + 36, 5, 22), Color("#f3d28a"))
	draw_rect(Rect2(1810, top + 36, 5, 22), Color("#f3d28a"))
	for x in [left, 1690.0, 1904.0, left + width - 6]:
		draw_rect(Rect2(x, top, 6, height), Color("#5D9374"))
	draw_rect(Rect2(left, top + height - 4, width, 4), Color("#d77a45"))
	draw_string(ThemeDB.fallback_font, Vector2(1600, top - 10), "MAIN ENTRANCE", HORIZONTAL_ALIGNMENT_CENTER, 400, 12, Color("#192787"))


func _draw_furniture_and_objects() -> void:
	# Blue countertop is solid; the separate lower front panel remains removed.
	draw_rect(Rect2(1980, 570, 190, 48), Color("#192787"))
	draw_rect(Rect2(1988, 570, 174, 10), Color("#D77A45"))
	draw_rect(Rect2(1996, 580, 158, 30), Color("#115293"))
	draw_rect(Rect2(1984, 610, 182, 8), Color("#192787"))
	# No plant image is present in Art Assets, so use matching code-drawn pixel plants.
	for plant_base: Vector2 in [Vector2(276, 700), Vector2(3324, 700), Vector2(420, 900), Vector2(1320, 900), Vector2(2280, 900), Vector2(3180, 900), Vector2(1418, 1380), Vector2(2182, 1380), Vector2(1418, 2000), Vector2(2182, 2000)]:
		_draw_potted_plant(plant_base)


func _draw_potted_plant(base: Vector2) -> void:
	# Pot bottoms sit flush to wall/baseboard edges; layered leaves add the missing plant art.
	draw_rect(Rect2(base + Vector2(-14, 20), Vector2(28, 4)), Color("#526f54"))
	draw_rect(Rect2(base + Vector2(-15, 5), Vector2(30, 5)), Color("#192787"))
	var pot := PackedVector2Array([
		base + Vector2(-12, 9), base + Vector2(12, 9),
		base + Vector2(9, 23), base + Vector2(-9, 23),
	])
	draw_colored_polygon(pot, Color("#b66d4a"))
	draw_polyline(PackedVector2Array([pot[0], pot[1], pot[2], pot[3], pot[0]]), Color("#7c4f3b"), 2.0, true)
	draw_line(base + Vector2(0, 9), base + Vector2(0, -15), Color("#477748"), 4.0)
	_draw_plant_leaf(base + Vector2(-1, 3), base + Vector2(-22, -31), 8.0, Color("#4d814b"), Color("#80a85b"))
	_draw_plant_leaf(base + Vector2(0, 0), base + Vector2(-9, -46), 8.0, Color("#5d9251"), Color("#91b76a"))
	_draw_plant_leaf(base + Vector2(1, 2), base + Vector2(11, -43), 9.0, Color("#477748"), Color("#82a95b"))
	_draw_plant_leaf(base + Vector2(2, 5), base + Vector2(24, -27), 8.0, Color("#57884a"), Color("#9bbb69"))
	_draw_plant_leaf(base + Vector2(-1, 7), base + Vector2(-25, -14), 7.0, Color("#648e4c"), Color("#a4bd70"))


func _draw_plant_leaf(root: Vector2, tip: Vector2, width: float, fill: Color, highlight: Color) -> void:
	var axis := (tip - root).normalized()
	var side := Vector2(-axis.y, axis.x) * width
	var shoulder := root.lerp(tip, 0.42)
	var leaf := PackedVector2Array([root, shoulder + side, tip, shoulder - side])
	draw_colored_polygon(leaf, fill)
	draw_line(root.lerp(tip, 0.18), tip, highlight, 2.0)
