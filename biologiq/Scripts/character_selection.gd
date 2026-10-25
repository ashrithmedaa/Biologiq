extends Control

const PLAYER_ART := "res://Art Assets/Player - Walking Animations (Front, Side, Back).png"
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
	panel.custom_minimum_size = Vector2(1000, 590)
	panel.add_theme_stylebox_override("panel", _panel_style(CREAM, NAVY, 5))
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 34)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	margin.add_child(content)
	content.add_child(_label("CHOOSE YOUR RESEARCHER", 30, NAVY, HORIZONTAL_ALIGNMENT_CENTER))
	content.add_child(_label("One profile is ready for your first day at BIOLOGIQ.", 16, Color("#42636a"), HORIZONTAL_ALIGNMENT_CENTER))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 32)
	content.add_child(columns)
	columns.add_child(_portrait_card())
	columns.add_child(_profile_card())


func _portrait_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(340, 430)
	card.add_theme_stylebox_override("panel", _panel_style(Color("#8BC8D8"), NAVY, 3))
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 10)
	card.add_child(column)
	var portrait := TextureRect.new()
	var frame := AtlasTexture.new()
	frame.atlas = load(PLAYER_ART) as Texture2D
	frame.region = Rect2(0, 0, 306, 646)
	portrait.texture = frame
	portrait.custom_minimum_size = Vector2(220, 365)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	column.add_child(portrait)
	var badge := _label("PLAYER 01  ·  READY", 14, NAVY, HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(badge)
	return card


func _profile_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _panel_style(Color("#F3EEDC"), SAGE, 3))
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	column.add_child(_label("SELECTED RESEARCHER", 14, SAGE))
	column.add_child(_label("Lab Trainee", 34, NAVY))
	var description := _label("Your BIOLOGIQ story begins at the front door. Meet the team, explore each room, and learn by doing.", 17, Color("#42636a"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.y = 82
	column.add_child(description)
	var divider := ColorRect.new()
	divider.color = SAGE
	divider.custom_minimum_size = Vector2(0, 3)
	column.add_child(divider)
	var program_name := "Molecular Biology (Master's)"
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null:
		program_name = str(save_manager.get_save_state().get("degree_program", program_name))
	column.add_child(_label("AREA OF STUDY", 13, SAGE))
	column.add_child(_label(program_name, 18, NAVY))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	var start := _button("ENTER BIOLOGIQ", Vector2(0, 58), SAGE)
	start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start.pressed.connect(func(): get_tree().change_scene_to_file("res://walking.tscn"))
	column.add_child(start)
	var back := Button.new()
	back.text = "←  RETURN TO TITLE"
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.add_theme_font_size_override("font_size", 14)
	back.add_theme_color_override("font_color", NAVY)
	back.add_theme_stylebox_override("normal", _panel_style(Color("#E6E0D2"), NAVY, 2))
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://Scenes/main.tscn"))
	column.add_child(back)
	return card


func _label(text: String, font_size: int, color: Color, alignment: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	return label


func _button(text: String, dimensions: Vector2, base_color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = dimensions
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_stylebox_override("normal", _panel_style(base_color, NAVY, 2))
	button.add_theme_stylebox_override("hover", _panel_style(TERRACOTTA, NAVY, 2))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("#42636a"), NAVY, 2))
	return button


func _panel_style(background: Color, outline: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = outline
	style.set_border_width_all(width)
	style.set_corner_radius_all(5)
	return style
