extends Node2D

const PROGRAMS := [
	"Molecular Biology (Master's)",
	"Biomedical Engineering (Master's)",
	"Biochemistry (Master's)",
]
const ARTICLE_PAGES := [
	{"title": "Inside BIOLOGIQ", "body": "BIOLOGIQ is a biotechnology company where research teams turn careful experiments into tools that help people. Your first day begins at the reception desk."},
	{"title": "How the lab works", "body": "Every room has a training level. Read the plaques outside each door. Some spaces are open to new interns; advanced research rooms need additional credentials."},
	{"title": "Your first day", "body": "Walk with WASD or the arrow keys. Press E near people, objects, and plaques. Use Enter to continue a conversation. You can carry up to two objects."},
]

var step := 0
var selected_program := -1
var article_index := 0
var typewriter_progress := 0.0
var full_intro := "Welcome to BIOLOGIQ. You are joining a biotechnology team for your first day. Before you enter the lab, choose your area of graduate study."
var screen_text: Label
var title_label: Label
var continue_button: Button
var program_buttons: Array[Button] = []
var program_note: Label


func _ready() -> void:
	_build_ui()
	_update_screen()


func _process(delta: float) -> void:
	if step == 0 and typewriter_progress < full_intro.length():
		typewriter_progress = minf(full_intro.length(), typewriter_progress + delta * 48.0)
		screen_text.text = full_intro.substr(0, int(typewriter_progress))
		if int(typewriter_progress) >= full_intro.length():
			continue_button.show()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if step == 0 and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
		if int(typewriter_progress) < full_intro.length():
			typewriter_progress = full_intro.length()
			screen_text.text = full_intro
			continue_button.show()
		else:
			_show_programs()
	elif step == 1:
		if event.keycode >= KEY_1 and event.keycode <= KEY_3:
			_select_program(int(event.keycode - KEY_1))
		elif event.keycode == KEY_UP or event.keycode == KEY_LEFT:
			_select_program(maxi(0, selected_program - 1))
		elif event.keycode == KEY_DOWN or event.keycode == KEY_RIGHT:
			_select_program(mini(2, selected_program + 1))
		elif (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER) and selected_program >= 0:
			_begin_article()
	elif step == 2 and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
		_advance_article()


func _build_ui() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	title_label = Label.new()
	title_label.position = Vector2(292, 150)
	title_label.size = Vector2(696, 42)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color("#94dbc4"))
	hud.add_child(title_label)
	screen_text = Label.new()
	screen_text.position = Vector2(335, 217)
	screen_text.size = Vector2(610, 180)
	screen_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	screen_text.add_theme_font_size_override("font_size", 22)
	screen_text.add_theme_color_override("font_color", Color("#f4f4e8"))
	hud.add_child(screen_text)
	program_note = Label.new()
	program_note.position = Vector2(335, 383)
	program_note.size = Vector2(610, 52)
	program_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	program_note.add_theme_font_size_override("font_size", 14)
	program_note.add_theme_color_override("font_color", Color("#bed7ca"))
	hud.add_child(program_note)
	for index in 3:
		var button := Button.new()
		button.position = Vector2(332, 280 + index * 52)
		button.size = Vector2(616, 48)
		button.toggle_mode = true
		button.add_theme_font_size_override("font_size", 17)
		button.pressed.connect(_select_program.bind(index))
		hud.add_child(button)
		program_buttons.append(button)
	continue_button = Button.new()
	continue_button.position = Vector2(538, 445)
	continue_button.size = Vector2(204, 48)
	continue_button.add_theme_font_size_override("font_size", 17)
	continue_button.pressed.connect(_on_continue_pressed)
	hud.add_child(continue_button)


func _update_screen() -> void:
	for button in program_buttons:
		button.hide()
	program_note.hide()
	continue_button.hide()
	match step:
		0:
			title_label.text = "BIOLOGIQ  /  NEW EMPLOYEE ORIENTATION"
			screen_text.text = ""
			program_note.text = ""
			continue_button.text = "Choose a program"
			if int(typewriter_progress) >= full_intro.length():
				screen_text.text = full_intro
				continue_button.show()
		1:
			title_label.text = "SELECT YOUR MASTER'S PROGRAM"
			screen_text.position = Vector2(335, 210)
			screen_text.size = Vector2(610, 68)
			screen_text.text = "For this demo, your starting education is set at a master's degree level. Choose one of three primary study programs."
			program_note.text = "A full version would let players start in high school and choose from a wider range of degrees."
			program_note.position = Vector2(335, 438)
			program_note.size = Vector2(610, 42)
			program_note.show()
			for index in 3:
				program_buttons[index].text = PROGRAMS[index]
				program_buttons[index].show()
			continue_button.position = Vector2(538, 485)
			continue_button.text = "Continue to article"
			if selected_program >= 0:
				continue_button.show()
		2:
			screen_text.position = Vector2(335, 217)
			screen_text.size = Vector2(610, 180)
			program_note.position = Vector2(335, 383)
			program_note.size = Vector2(610, 52)
			continue_button.position = Vector2(538, 445)
			var page: Dictionary = ARTICLE_PAGES[article_index]
			title_label.text = str(page.title).to_upper()
			screen_text.text = str(page.body)
			program_note.text = "ARTICLE  %d / %d     ·     Press ENTER to continue" % [article_index + 1, ARTICLE_PAGES.size()]
			program_note.show()
			continue_button.text = "Enter the lab" if article_index == ARTICLE_PAGES.size() - 1 else "Continue"
			continue_button.show()


func _select_program(index: int) -> void:
	selected_program = clampi(index, 0, PROGRAMS.size() - 1)
	for button_index in program_buttons.size():
		program_buttons[button_index].button_pressed = button_index == selected_program
	program_note.text = "Selected: %s. This demo begins at master's level; the full version would offer more degrees." % PROGRAMS[selected_program]
	continue_button.show()


func _on_continue_pressed() -> void:
	if step == 0:
		_show_programs()
	elif step == 1:
		if selected_program >= 0:
			_begin_article()
	else:
		_advance_article()


func _show_programs() -> void:
	step = 1
	_update_screen()


func _begin_article() -> void:
	if selected_program < 0:
		return
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null:
		var data: Dictionary = save_manager.get_save_state()
		data["degree_program"] = PROGRAMS[selected_program]
		data["degree_status"] = "Master's"
		data["inventory"] = []
		save_manager.set_save_state(data)
	article_index = 0
	step = 2
	_update_screen()


func _advance_article() -> void:
	if article_index + 1 < ARTICLE_PAGES.size():
		article_index += 1
		_update_screen()
	else:
		get_tree().change_scene_to_file("res://Scenes/main_map.tscn")


func _draw() -> void:
	var screen := get_viewport_rect().size
	# First-person desk, sunset window, and a quiet town silhouette.
	for stripe in 12:
		var y := stripe * 34.0
		draw_rect(Rect2(0, y, screen.x, 410.0 / 12.0), Color("#" + ["f7c08a", "f4b184", "ed9c7f", "dc8a82", "c87983", "a66f83", "7e6379", "63596f", "4e5365", "3f4b5a", "35434f", "2e3d47"][stripe]))
	# Town roofs and window lights sit in the sunset outside the laptop.
	draw_rect(Rect2(0, 325, 220, 95), Color("#44535c"))
	draw_rect(Rect2(1020, 300, 260, 120), Color("#44535c"))
	for house in 5:
		var x := 238.0 + house * 170.0
		draw_rect(Rect2(x, 350 + (house % 2) * 18, 116, 72), Color("#4c5760"))
		draw_colored_polygon(PackedVector2Array([Vector2(x - 8, 352), Vector2(x + 58, 309), Vector2(x + 124, 352)]), Color("#594c57"))
		draw_rect(Rect2(x + 20, 372, 14, 18), Color("#f6d29a"))
		draw_rect(Rect2(x + 78, 372, 14, 18), Color("#f6d29a"))
	draw_rect(Rect2(0, 415, screen.x, 305), Color("#634d49"))
	# Laptop bezel and screen.
	var bezel := StyleBoxFlat.new()
	bezel.bg_color = Color("#17252c")
	bezel.set_corner_radius_all(18)
	draw_style_box(bezel, Rect2(204, 95, 872, 470))
	var screen_box := StyleBoxFlat.new()
	screen_box.bg_color = Color("#20343b")
	screen_box.set_corner_radius_all(12)
	draw_style_box(screen_box, Rect2(222, 113, 836, 436))
	draw_colored_polygon(PackedVector2Array([Vector2(122, 565), Vector2(1158, 565), Vector2(1080, 635), Vector2(200, 635)]), Color("#9da9a5"))
	draw_rect(Rect2(525, 579, 230, 10), Color("#778985"))
	draw_rect(Rect2(0, 634, screen.x, 86), Color("#73574e"))
