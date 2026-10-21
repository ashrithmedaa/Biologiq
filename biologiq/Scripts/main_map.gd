extends Node2D

const SAM_SIDE := "res://Art Assets/Sam - Side walking spritesheet.png"
const SAM_FRONT := "res://Art Assets/Sam - Front walking spritesheet.png"
const SAM_BACK := "res://Art Assets/Sam walking - Back spritesheet.png"
const SHARON_SHEET := "res://Art Assets/Sharon O_Riley - Typing.png"
const PLAYER_SHEET := "res://Art Assets/Player - Walking Animations (Front, Side, Back).png"
const WALK_SPEED := 230.0
const INTERACT_DISTANCE := 78.0
const WORLD_WIDTH := 3600.0
const WORLD_HEIGHT := 1080.0
const DEGREE_RANK := {"Internship": 0, "High School": 1, "College": 2, "Bachelor's": 3, "Master's": 4, "Doctorate": 5}

var player: CharacterBody2D
var player_sprite: AnimatedSprite2D
var sam_character: Node2D
var sam_sprite: AnimatedSprite2D
var sam_interactable_index := -1
var sam_patrol_direction := 1.0
var camera: Camera2D
var dialogue_panel: PanelContainer
var dialogue_label: Label
var dialogue_hint: Label
var interaction_hint: Label
var inventory_label: Label
var floor_title: Label
var menu_layer: CanvasLayer
var dialogue_lines: Array[String] = []
var dialogue_choices: Array[String] = []
var choice_actions: Array[String] = []
var choice_buttons: Array[Button] = []
var selected_choice := 0
var dialogue_index := 0
var dialogue_open := false
var menu_open := false
var player_facing := "down"
var interactables: Array[Dictionary] = []
var inventory: Array[String] = []
var player_program := "Molecular Biology (Master's)"
var player_status := "Master's"
var hovered_object := -1
var sam_patrol_speed := 48.0
var sam_patrol_left := 700.0
var sam_patrol_right := 940.0


func _ready() -> void:
	_setup_input()
	_load_player_status()
	_build_map()
	_build_characters()
	_build_hud()
	_build_menu()
	_update_player_animation(false)


func _physics_process(_delta: float) -> void:
	_update_sam_patrol(_delta)
	if dialogue_open or menu_open:
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
	player.global_position.x = clampf(player.global_position.x, 44.0, WORLD_WIDTH - 44.0)
	player.global_position.y = clampf(player.global_position.y, 72.0, WORLD_HEIGHT - 60.0)
	_enforce_room_access(previous_position)
	_update_player_animation(direction.length_squared() > 0.0)
	_update_interaction_hint()
	if floor_title != null:
		floor_title.text = "BIOLOGIQ  /  FLOOR 2" if player.global_position.y > 540.0 else "BIOLOGIQ  /  FLOOR 1"


func _process(_delta: float) -> void:
	var hovered := _find_hovered_object()
	if hovered != hovered_object:
		hovered_object = hovered
		queue_redraw()


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
			if not dialogue_choices.is_empty():
				_choose_dialogue_option(selected_choice)
			else:
				_advance_dialogue()
		return
	if event.keycode == KEY_E and not dialogue_open and not menu_open:
		_interact()
		return
	if dialogue_open and not dialogue_choices.is_empty():
		if event.keycode == KEY_LEFT or event.keycode == KEY_A:
			_select_choice(maxi(0, selected_choice - 1))
		elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			_select_choice(mini(dialogue_choices.size() - 1, selected_choice + 1))


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
	inventory.assign(saved.get("inventory", []))


func _build_map() -> void:
	# Floor one: reception and training rooms run along the east-west hall.
	_add_room("Internship", "Reception", "Sharon O'Riley", 0, Rect2(250, 145, 230, 145), Vector2(360, 300), Vector2(360, 310), "reception_room.tscn")
	_add_room("Internship", "Intern Quarters", "Internship Program", 0, Rect2(510, 145, 210, 145), Vector2(615, 300), Vector2(615, 310), "internship_room.tscn")
	_add_room("High School", "Student Lab", "Dr. Eli Warren", 1, Rect2(760, 145, 210, 145), Vector2(865, 300), Vector2(865, 310), "student_lab_room.tscn")
	_add_room("College", "College Lab", "Dr. Nia Brooks", 2, Rect2(1010, 145, 220, 145), Vector2(1120, 300), Vector2(1120, 310), "college_lab_room.tscn")
	_add_room("College", "Low College Lab", "Dr. Samir Lee", 2, Rect2(1270, 145, 220, 145), Vector2(1380, 300), Vector2(1380, 310), "low_college_room.tscn")
	_add_room("College", "Job Quarters", "College Team", 2, Rect2(1510, 145, 200, 145), Vector2(1610, 300), Vector2(1610, 310), "job_quarters_room.tscn")

	# Floor two starts beyond the stairwell and continues down the long hall.
	_add_room("Bachelor's", "Bachelor's Lab", "Dr. Jun Park", 3, Rect2(1850, 510, 200, 145), Vector2(1950, 665), Vector2(1950, 675), "bachelors_room.tscn")
	_add_room("Master's", "Molecular Biology", "Dr. Maria-Rose Valdez", 4, Rect2(2090, 510, 230, 145), Vector2(2205, 665), Vector2(2205, 675), "molecular_biology_room.tscn")
	_add_room("Master's", "Biochemistry", "Dr. Valdez's Team", 4, Rect2(2360, 510, 220, 145), Vector2(2470, 665), Vector2(2470, 675), "biochemistry_room.tscn")
	_add_room("Master's", "Masters Suite", "Dr. Maria-Rose Valdez", 4, Rect2(2620, 810, 220, 145), Vector2(2730, 796), Vector2(2730, 790), "masters_suite_room.tscn")
	_add_room("Doctorate", "Advanced Research", "Dr. Ravi Shah", 5, Rect2(2880, 510, 220, 145), Vector2(2990, 665), Vector2(2990, 675), "advanced_research_room.tscn")
	_add_room("Doctorate", "Graduate Suite", "Dr. Ravi Shah", 5, Rect2(3140, 810, 220, 145), Vector2(3250, 796), Vector2(3250, 790), "graduate_suite_room.tscn")

	_add_object("Reception desk", Vector2(335, 250), "A tidy reception desk. Sharon is sorting today's visitor badges.", "inspect")
	_add_object("Visitor badge", Vector2(390, 250), "A visitor badge with a clip and a blank name strip.", "pickup", "Pick up", "Leave")
	_add_object("Large succulent", Vector2(180, 445), "It's quite a large succulent. The leaves look healthy and glossy.", "inspect")
	_add_object("Gel electrophoresis box", Vector2(2470, 745), "A gel electrophoresis box. Begin a sample-preparation minigame?", "minigame", "Start minigame", "Not now")
	_add_object("Lab notebook", Vector2(3370, 745), "A lab notebook with several pages of careful observations.", "pickup", "Pick up", "Leave")
	_add_object("Stairwell", Vector2(1740, 550), "The stairwell links the first-floor hall to the second-floor research wing.", "inspect")
	_add_object("Exit", Vector2(100, 370), "The front entrance leads back to the walkway and the town.", "inspect")
	queue_redraw()


func _add_room(status: String, room_name: String, owner: String, rank: int, room_rect: Rect2, plaque_position: Vector2, entrance_position: Vector2, scene_file: String) -> void:
	interactables.append({
		"name": room_name, "position": entrance_position, "plaque_position": plaque_position, "kind": "room",
		"description": room_name + " — " + owner + ".", "status": status, "rank": rank,
		"owner": owner, "room_rect": room_rect,
		"scene_path": "res://Scenes/Rooms/" + scene_file,
	})


func _add_object(object_name: String, at: Vector2, description: String, kind: String, first_choice: String = "", second_choice: String = "") -> void:
	var entry := {"name": object_name, "position": at, "kind": kind, "description": description}
	if first_choice != "":
		entry["choices"] = [first_choice, second_choice]
	interactables.append(entry)


func _build_characters() -> void:
	# One receptionist, scaled to the desk and standing in the open space behind it.
	var sharon := _make_npc("Sharon", Vector2(345, 274), _sharon_frames(), 0.42)
	sharon.get_node("Sprite").play("typing")
	_add_character_interaction("Sharon O'Riley", sharon.position, ["SHARON: Welcome to BIOLOGIQ. Please check in before exploring.", "SHARON: Your orientation packet is ready. The room plaques show the training level for each lab."])

	sam_character = _make_npc("Sam", Vector2(792, 312), _sam_frames(), 0.14)
	sam_sprite = sam_character.get_node("Sprite") as AnimatedSprite2D
	sam_sprite.play("front")
	var sam_key_shader := Shader.new()
	sam_key_shader.code = """
shader_type canvas_item;
void fragment() {
	vec4 color = texture(TEXTURE, UV) * COLOR;
	if (color.r > 0.96 && color.g > 0.96 && color.b > 0.96) {
		color.a = 0.0;
	}
	COLOR = color;
}
"""
	var sam_material := ShaderMaterial.new()
	sam_material.shader = sam_key_shader
	sam_sprite.material = sam_material
	sam_interactable_index = _add_character_interaction("Sam", sam_character.position, ["SAM: Hey, welcome in. This is test dialogue. The labs are split by training level.", "SAM: I'm doing an extremely important hallway lap. Ask me again later for more test dialogue."])

	player = CharacterBody2D.new()
	player.name = "Player"
	player.position = Vector2(200, 380)
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


func _sam_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	_add_strip(frames, "front", SAM_FRONT, 0, 4, Vector2(1600, 1600), true, 5.0)
	_add_strip(frames, "side", SAM_SIDE, 0, 6, Vector2(1600, 1600), true, 5.0)
	_add_strip(frames, "back", SAM_BACK, 0, 4, Vector2(100, 100), true, 5.0)
	return frames


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
		atlas.region = Rect2(Vector2(index * 200, 0), Vector2(100, 100))
		frames.add_frame("typing", atlas)
	return frames


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
	var status := _label(hud, "PlayerStatus", "%s  ·  %s" % [player_program, player_status], Vector2(24, 51), Vector2(760, 30), 14, Color("#42636a"))
	status.add_theme_font_size_override("font_size", 14)
	interaction_hint = _label(hud, "InteractionHint", "", Vector2(270, 645), Vector2(740, 32), 17, Color("#143d47"))
	interaction_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inventory_label = _label(hud, "Inventory", _inventory_text(), Vector2(875, 20), Vector2(380, 34), 14, Color("#42636a"))
	inventory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var controls := _label(hud, "Controls", "WASD / Arrows Move   E Interact   Enter Continue   F Menu", Vector2(25, 688), Vector2(750, 25), 13, Color("#42636a"))
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
	hud.add_child(dialogue_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	dialogue_panel.add_child(box)
	dialogue_label = Label.new()
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.add_theme_color_override("font_color", Color("#fff9e9"))
	dialogue_label.add_theme_font_size_override("font_size", 18)
	dialogue_label.custom_minimum_size = Vector2(810, 50)
	box.add_child(dialogue_label)
	var choice_row := HBoxContainer.new()
	choice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	choice_row.add_theme_constant_override("separation", 18)
	box.add_child(choice_row)
	for index in 2:
		var button := Button.new()
		button.custom_minimum_size = Vector2(260, 38)
		button.add_theme_font_size_override("font_size", 15)
		button.pressed.connect(_choose_dialogue_option.bind(index))
		choice_row.add_child(button)
		choice_buttons.append(button)
	var hint := Label.new()
	hint.name = "DialogueHint"
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
	card.position = Vector2(440, 170)
	card.size = Vector2(400, 360)
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
	var save := _menu_button("Save", "Save game  ·  coming soon", column)
	save.disabled = true
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


func _interact() -> void:
	var target := _nearest_interactable()
	if target.is_empty():
		return
	var kind := str(target.kind)
	if kind == "room":
		if int(target.rank) > int(DEGREE_RANK.get(player_status, 0)):
			_start_dialogue(["UNAUTHORIZED ACCESS: %s required." % _required_status_text(str(target.status))])
		else:
			var error := get_tree().change_scene_to_file(str(target.scene_path))
			if error != OK:
				_start_dialogue(["The %s room could not be opened." % str(target.name)])
		return
	if kind == "person":
		_start_dialogue(target.lines)
		return
	var choices: Array[String] = []
	var actions: Array[String] = []
	if kind == "pickup":
		if inventory.size() >= 2:
			_start_dialogue(["You can carry only two objects. Your inventory is full."])
			return
		choices = ["Pick up", "Leave"]
		actions = ["pickup", "leave"]
	elif kind == "minigame":
		choices = ["Start minigame", "Not now"]
		actions = ["minigame", "leave"]
	_start_dialogue([str(target.description)], choices, actions)


func _start_dialogue(lines: Array, choices: Array[String] = [], actions: Array[String] = []) -> void:
	dialogue_lines.clear()
	for line in lines:
		dialogue_lines.append(str(line))
	dialogue_choices = choices.duplicate()
	choice_actions = actions.duplicate()
	selected_choice = 0
	if dialogue_lines.is_empty():
		return
	dialogue_index = 0
	dialogue_open = true
	dialogue_panel.show()
	_show_dialogue_line()


func _show_dialogue_line() -> void:
	dialogue_label.text = dialogue_lines[dialogue_index]
	for index in choice_buttons.size():
		var visible_choice := index < dialogue_choices.size()
		choice_buttons[index].visible = visible_choice
		if visible_choice:
			choice_buttons[index].text = dialogue_choices[index]
			choice_buttons[index].modulate = Color.WHITE if index == selected_choice else Color(0.76, 0.82, 0.8)
		var hint := "← / → choose   ENTER select   ESC close" if not dialogue_choices.is_empty() else "ENTER continue"
		dialogue_hint.text = hint


func _select_choice(index: int) -> void:
	selected_choice = index
	_show_dialogue_line()


func _choose_dialogue_option(index: int) -> void:
	if index < 0 or index >= choice_actions.size():
		return
	var action := choice_actions[index]
	var object_name := ""
	var target := _nearest_interactable()
	if not target.is_empty():
		object_name = str(target.name)
	match action:
		"pickup":
			if inventory.size() >= 2:
				_close_dialogue()
				_start_dialogue(["You can carry only two objects. Your inventory is full."])
				return
			inventory.append(object_name)
			inventory_label.text = _inventory_text()
			_save_inventory()
			interactables.erase(target)
			queue_redraw()
			_close_dialogue()
			_start_dialogue(["%s added to your inventory." % object_name])
		"minigame":
			_close_dialogue()
			_start_dialogue(["The gel electrophoresis minigame is a test placeholder and is not available yet."])
		_:
			_close_dialogue()


func _advance_dialogue() -> void:
	if dialogue_index + 1 < dialogue_lines.size():
		dialogue_index += 1
		_show_dialogue_line()
	else:
		_close_dialogue()


func _close_dialogue() -> void:
	dialogue_open = false
	dialogue_panel.hide()
	dialogue_choices.clear()
	choice_actions.clear()
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


func _enforce_room_access(previous_position: Vector2) -> void:
	for room in interactables:
		if str(room.kind) != "room" or int(room.rank) <= int(DEGREE_RANK.get(player_status, 0)):
			continue
		if room.room_rect.has_point(player.global_position):
			player.global_position = previous_position
			return


func _find_hovered_object() -> int:
	var mouse_position := get_global_mouse_position()
	for index in interactables.size():
		var hover_position: Vector2 = interactables[index].get("plaque_position", interactables[index].position)
		if mouse_position.distance_to(hover_position) < 28.0:
			return index
	return -1


func _update_interaction_hint() -> void:
	if dialogue_open or menu_open:
		interaction_hint.text = ""
		return
	var target := _nearest_interactable()
	if target.is_empty():
		interaction_hint.text = ""
	elif str(target.kind) == "room" and int(target.rank) <= int(DEGREE_RANK.get(player_status, 0)):
		interaction_hint.text = "Enter %s?   Press E to enter" % str(target.name)
	elif str(target.kind) == "room":
		interaction_hint.text = "%s room   ·   E to check access" % str(target.name)
	else:
		interaction_hint.text = "E  Interact with %s" % str(target.name)


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


func _update_sam_patrol(delta: float) -> void:
	if sam_character == null or dialogue_open or menu_open:
		return
	sam_character.position.x += sam_patrol_direction * sam_patrol_speed * delta
	if sam_character.position.x >= sam_patrol_right:
		sam_character.position.x = sam_patrol_right
		sam_patrol_direction = -1.0
	elif sam_character.position.x <= sam_patrol_left:
		sam_character.position.x = sam_patrol_left
		sam_patrol_direction = 1.0
	sam_sprite.flip_h = sam_patrol_direction < 0.0
	if sam_sprite.animation != "side" or not sam_sprite.is_playing():
		sam_sprite.play("side")
	if sam_interactable_index >= 0:
		interactables[sam_interactable_index]["position"] = sam_character.position


func _toggle_menu() -> void:
	menu_open = not menu_open
	menu_layer.visible = menu_open
	_update_interaction_hint()


func _close_menu() -> void:
	menu_open = false
	menu_layer.hide()
	_update_interaction_hint()


func _inventory_text() -> String:
	return "Inventory  ·  " + (", ".join(PackedStringArray(inventory)) if not inventory.is_empty() else "empty")


func _required_status_text(status: String) -> String:
	match status:
		"Master's": return "Master's degree"
		"Bachelor's": return "Bachelor's degree"
		"Doctorate": return "Doctoral degree"
		"College": return "College enrollment"
		"High School": return "High school enrollment"
		_: return status


func _save_inventory() -> void:
	var manager := get_node_or_null("/root/SaveManager")
	if manager == null:
		return
	var saved: Dictionary = manager.get_save_state()
	saved["inventory"] = inventory.duplicate()
	manager.set_save_state(saved)


func _draw() -> void:
	# Pixel-art campus palette: cream tile, sage walls, navy outlines and terracotta details.
	draw_rect(Rect2(0, 0, WORLD_WIDTH, WORLD_HEIGHT), Color("#8BAF75"))
	for x in range(0, int(WORLD_WIDTH), 32):
		for y in range(0, int(WORLD_HEIGHT), 32):
			if (x / 32 + y / 32) % 2 == 0:
				draw_rect(Rect2(x, y, 32, 32), Color("#86A873"))
	_draw_hallway()
	_draw_room_zones()
	_draw_stairwell_and_walkway()
	_draw_furniture_and_objects()
	if hovered_object >= 0 and hovered_object < interactables.size():
		var hovered: Dictionary = interactables[hovered_object]
		var at: Vector2 = hovered.get("plaque_position", hovered.position)
		draw_circle(at, 28, Color(0.94, 0.76, 0.31, 0.17))
		draw_arc(at, 25, 0.0, TAU, 40, Color("#edaa42"), 3.0, true)


func _draw_hallway() -> void:
	# Two connected, clearly separated wings with consistent 16 px wall and tile rhythm.
	_draw_pixel_panel(Rect2(54, 92, 1660, 475), Color("#192787"), Color("#FAF5E6"))
	_draw_pixel_panel(Rect2(1780, 444, 1760, 520), Color("#192787"), Color("#FAF5E6"))
	_draw_tile_floor(Rect2(72, 290, 1624, 248))
	_draw_tile_floor(Rect2(1798, 638, 1724, 146))
	for x in range(88, 1680, 32):
		for y in range(306, 536, 32):
			if (x / 32 + y / 32) % 2 == 0:
				draw_rect(Rect2(x, y, 32, 32), Color("#F3EEDC"))
	for x in range(1814, 3500, 32):
		for y in range(654, 782, 32):
			if (x / 32 + y / 32) % 2 == 0:
				draw_rect(Rect2(x, y, 32, 32), Color("#F3EEDC"))
	draw_string(ThemeDB.fallback_font, Vector2(92, 132), "01  /  FIRST FLOOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#192787"))
	draw_string(ThemeDB.fallback_font, Vector2(1818, 484), "02  /  SECOND FLOOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#192787"))
	draw_string(ThemeDB.fallback_font, Vector2(92, 156), "WELCOME • TRAINING • STUDENT LABS", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#5D9374"))
	draw_string(ThemeDB.fallback_font, Vector2(1818, 508), "RESEARCH • GRADUATE STUDIES", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#5D9374"))


func _draw_pixel_panel(rect: Rect2, outline: Color, fill: Color) -> void:
	draw_rect(rect, outline)
	draw_rect(Rect2(rect.position + Vector2(12, 12), rect.size - Vector2(24, 24)), fill)
	# Repeating inset blocks give the walls a crisp pixel-art trim.
	for x in range(int(rect.position.x + 16), int(rect.end.x - 16), 32):
		draw_rect(Rect2(x, rect.position.y + 4, 16, 8), Color("#8BC8D8"))
		draw_rect(Rect2(x, rect.end.y - 12, 16, 8), Color("#8BC8D8"))


func _draw_tile_floor(rect: Rect2) -> void:
	draw_rect(rect, Color("#FAF5E6"))
	for x in range(int(rect.position.x), int(rect.end.x), 32):
		for y in range(int(rect.position.y), int(rect.end.y), 32):
			draw_rect(Rect2(x, y, 32, 32), Color("#F3EEDC"), false, 1.0)


func _draw_room_zones() -> void:
	for target in interactables:
		if str(target.kind) != "room":
			continue
		var rect: Rect2 = target.room_rect
		var locked := int(target.rank) > int(DEGREE_RANK.get(player_status, 0))
		draw_rect(rect, Color("#8BC8D8") if not locked else Color("#E6E0D2"))
		draw_rect(rect.grow(5), Color("#192787") if not locked else Color("#D77A45"), false, 5.0)
		draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 12), Color("#5D9374") if not locked else Color("#D77A45"))
		draw_rect(Rect2(rect.position.x + 12, rect.position.y + 24, rect.size.x - 24, 4), Color("#FAF5E6"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(14, 54), str(target.name).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28, 14, Color("#192787"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(14, 78), str(target.status) + "  /  ACCESS", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28, 11, Color("#5D9374"))
		if locked:
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(14, 96), "LOCKED  ·  " + _required_status_text(str(target.status)), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24, 10, Color("#a14f46"))
		# Doorway, threshold, and marker on corridor-facing wall.
		var door: Vector2 = target["position"]
		draw_rect(Rect2(door - Vector2(27, 7), Vector2(54, 18)), Color("#FAF5E6"))
		draw_rect(Rect2(door + Vector2(-27, -8), Vector2(6, 16)), Color("#192787"))
		draw_rect(Rect2(door + Vector2(21, -8), Vector2(6, 16)), Color("#192787"))
	_draw_room_plaques()


func _draw_stairwell_and_walkway() -> void:
	_draw_pixel_panel(Rect2(1650, 390, 160, 260), Color("#192787"), Color("#FAF5E6"))
	for tread in 10:
		var y := 410 + tread * 22
		draw_rect(Rect2(1680, y, 100, 6), Color("#8BC8D8"))
	draw_string(ThemeDB.fallback_font, Vector2(1690, 535), "STAIRS", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#192787"))
	_draw_pixel_panel(Rect2(0, 330, 104, 82), Color("#192787"), Color("#FAF5E6"))
	draw_string(ThemeDB.fallback_font, Vector2(12, 375), "EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#192787"))
	draw_string(ThemeDB.fallback_font, Vector2(112, 324), "ENTRANCE / EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#192787"))


func _draw_furniture_and_objects() -> void:
	# Single, broad pixel counter in front of Sharon: the only receptionist sprite on the map.
	draw_rect(Rect2(252, 238, 184, 48), Color("#192787"))
	draw_rect(Rect2(260, 238, 168, 10), Color("#D77A45"))
	draw_rect(Rect2(268, 248, 152, 30), Color("#115293"))
	draw_rect(Rect2(256, 278, 176, 8), Color("#192787"))
	draw_rect(Rect2(385, 218, 24, 12), Color("#FAF5E6"))
	draw_rect(Rect2(390, 214, 8, 4), Color("#D77A45"))
	# A few square planters and research props, kept outside the walking lane.
	draw_rect(Rect2(164, 432, 32, 28), Color("#D77A45"))
	draw_rect(Rect2(168, 416, 8, 16), Color("#5D9374"))
	draw_rect(Rect2(180, 408, 8, 24), Color("#5D9374"))
	draw_rect(Rect2(188, 420, 8, 12), Color("#5D9374"))
	draw_rect(Rect2(2398, 742, 144, 28), Color("#115293"))
	draw_rect(Rect2(2410, 770, 8, 24), Color("#192787"))
	draw_rect(Rect2(2520, 770, 8, 24), Color("#192787"))
	draw_rect(Rect2(3328, 734, 48, 32), Color("#D77A45"))
	draw_rect(Rect2(3338, 722, 26, 14), Color("#FAF5E6"))
	draw_string(ThemeDB.fallback_font, Vector2(3315, 717), "NOTEBOOK", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#192787"))
	draw_string(ThemeDB.fallback_font, Vector2(277, 232), "RECEPTION", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#FAF5E6"))
	draw_string(ThemeDB.fallback_font, Vector2(2400, 734), "ELECTROPHORESIS", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#192787"))


func _draw_room_plaques() -> void:
	for target in interactables:
		if str(target.kind) != "room":
			continue
		var at: Vector2 = target.plaque_position
		var locked := int(target.rank) > int(DEGREE_RANK.get(player_status, 0))
		draw_rect(Rect2(at - Vector2(52, 9), Vector2(104, 18)), Color("#D77A45") if locked else Color("#192787"))
		var plaque_text := "UNAUTH. " + str(target.status).to_upper() if locked else str(target.owner).replace("Dr. ", "")
		draw_string(ThemeDB.fallback_font, at + Vector2(-48, 3), plaque_text, HORIZONTAL_ALIGNMENT_LEFT, 96, 8, Color("#FAF5E6"))


func _draw_string_small(text: String, at: Vector2) -> void:
	draw_string(ThemeDB.fallback_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#42636a"))
