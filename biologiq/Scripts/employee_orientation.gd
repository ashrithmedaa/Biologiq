extends Node2D

const ARTICLE_PAGES := [
	{"title": "Inside BIOLOGIQ", "body": "BIOLOGIQ is a biotechnology company where research teams turn careful experiments into tools that help people. Your first day begins at the reception desk."},
	{"title": "How the lab works", "body": "Every room has a training level. Read the plaques outside each door. Some spaces are open to new interns; advanced research rooms need additional credentials."},
	{"title": "Your first day", "body": "Walk with WASD or the arrow keys. Press E near people, objects, and plaques. Use Enter to continue a conversation. You can carry up to two objects."},
]

var step := 0
var article_index := 0
var typewriter_progress := 0.0
var full_intro := "Welcome to BIOLOGIQ. You are here to shadow a researcher, follow their work, and get a feel for life in a biotechnology lab."
var screen_text: Label
var title_label: Label
var continue_button: Button


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
			_show_articles()
	elif step == 1 and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
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
	continue_button = Button.new()
	continue_button.position = Vector2(538, 445)
	continue_button.size = Vector2(204, 48)
	continue_button.add_theme_font_size_override("font_size", 17)
	continue_button.pressed.connect(_on_continue_pressed)
	hud.add_child(continue_button)


func _update_screen() -> void:
	continue_button.hide()
	match step:
		0:
			title_label.text = "BIOLOGIQ  /  NEW EMPLOYEE ORIENTATION"
			screen_text.text = ""
			continue_button.text = "Continue"
			if int(typewriter_progress) >= full_intro.length():
				screen_text.text = full_intro
				continue_button.show()
		1:
			screen_text.position = Vector2(335, 217)
			screen_text.size = Vector2(610, 180)
			continue_button.position = Vector2(538, 445)
			var page: Dictionary = ARTICLE_PAGES[article_index]
			title_label.text = str(page.title).to_upper()
			screen_text.text = str(page.body)
			continue_button.text = "Enter the lab" if article_index == ARTICLE_PAGES.size() - 1 else "Continue"
			continue_button.show()


func _on_continue_pressed() -> void:
	if step == 0:
		_show_articles()
	else:
		_advance_article()


func _show_articles() -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null:
		var data: Dictionary = save_manager.get_save_state()
		data["degree_program"] = "Research Shadowing"
		data["degree_status"] = "Master's"
		data["inventory"] = []
		save_manager.set_save_state(data)
	article_index = 0
	step = 1
	_update_screen()


func _advance_article() -> void:
	if article_index + 1 < ARTICLE_PAGES.size():
		article_index += 1
		_update_screen()
	else:
		get_tree().change_scene_to_file("res://chararter_selection_fr.tscn")


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
