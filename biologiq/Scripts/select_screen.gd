extends Control

const CREAM := Color("#FAF5E6")
const NAVY := Color("#192787")
const SAGE := Color("#5D9374")
const TERRACOTTA := Color("#D77A45")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_screen()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#8BAF75"))
	for x in range(0, int(size.x), 40):
		for y in range(0, int(size.y), 40):
			if (int(x / 40) + int(y / 40)) % 2 == 0:
				draw_rect(Rect2(x, y, 40, 40), Color(0.95, 0.93, 0.84, 0.12))
	draw_rect(Rect2(0, size.y - 92, size.x, 92), Color("#F3EEDC"))
	for x in range(0, int(size.x), 32):
		draw_rect(Rect2(x, size.y - 92, 32, 92), Color("#192787"), false, 1.0)
	draw_rect(Rect2(0, 0, size.x, 12), NAVY)


func _build_screen() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1000, 570)
	panel.add_theme_stylebox_override("panel", _panel_style(CREAM, NAVY, 5))
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 36)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 22)
	margin.add_child(content)
	content.add_child(_label("CHOOSE YOUR EXPERIENCE", 32, NAVY, HORIZONTAL_ALIGNMENT_CENTER))
	content.add_child(_label("Pick a way to explore BIOLOGIQ.", 17, Color("#42636a"), HORIZONTAL_ALIGNMENT_CENTER))
	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 24)
	content.add_child(cards)
	cards.add_child(_mode_card("STORY MODE", "Take your first day tour through the lab, meet the team, and try guided experiments.", "BEGIN STORY", false))
	cards.add_child(_mode_card("SANDBOX MODE", "Explore freely and choose any experiment whenever you like.", "COMING SOON", true))
	var back := Button.new()
	back.text = "←  BACK TO TITLE"
	back.custom_minimum_size = Vector2(200, 44)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.add_theme_font_size_override("font_size", 15)
	back.add_theme_color_override("font_color", NAVY)
	back.add_theme_stylebox_override("normal", _panel_style(Color("#E6E0D2"), NAVY, 2))
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://Scenes/main.tscn"))
	content.add_child(back)


func _mode_card(title: String, description_text: String, button_text: String, disabled: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(420, 330)
	card.add_theme_stylebox_override("panel", _panel_style(Color("#F3EEDC") if not disabled else Color("#E6E0D2"), SAGE if not disabled else Color("#9BA29A"), 3))
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	column.add_child(_label("01   /   STORY" if not disabled else "02   /   FREE PLAY", 13, SAGE if not disabled else Color("#7b8980")))
	column.add_child(_label(title, 25, NAVY if not disabled else Color("#6f7771")))
	var description := _label(description_text, 17, Color("#42636a") if not disabled else Color("#7b8980"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.y = 96
	column.add_child(description)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	var action := Button.new()
	action.text = button_text
	action.custom_minimum_size = Vector2(0, 54)
	action.disabled = disabled
	action.add_theme_font_size_override("font_size", 18)
	action.add_theme_color_override("font_color", CREAM)
	action.add_theme_stylebox_override("normal", _panel_style(SAGE if not disabled else Color("#9BA29A"), NAVY, 2))
	action.add_theme_stylebox_override("hover", _panel_style(TERRACOTTA, NAVY, 2))
	action.add_theme_stylebox_override("pressed", _panel_style(Color("#42636a"), NAVY, 2))
	if not disabled:
		action.pressed.connect(_on_story_mode_pressed)
	column.add_child(action)
	return card


func _label(text: String, font_size: int, color: Color, alignment: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	return label


func _panel_style(background: Color, outline: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = outline
	style.set_border_width_all(width)
	style.set_corner_radius_all(5)
	return style


func _on_story_mode_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/save_select_screen.tscn")
