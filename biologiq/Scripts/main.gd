extends Control

const LOGO_ART := "res://Art Assets/BIOLOGIQ Logo.png"
const CREAM := Color("#FAF5E6")
const NAVY := Color("#192787")
const SAGE := Color("#5D9374")
const TERRACOTTA := Color("#D77A45")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_menu()
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


func _build_menu() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1060, 560)
	panel.add_theme_stylebox_override("panel", _panel_style(CREAM, NAVY, 5))
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 42)
	margin.add_child(columns)

	var logo_card := PanelContainer.new()
	logo_card.custom_minimum_size = Vector2(300, 0)
	logo_card.add_theme_stylebox_override("panel", _panel_style(Color("#8BC8D8"), NAVY, 3))
	columns.add_child(logo_card)
	var logo_column := VBoxContainer.new()
	logo_column.alignment = BoxContainer.ALIGNMENT_CENTER
	logo_column.add_theme_constant_override("separation", 16)
	logo_card.add_child(logo_column)
	var logo := TextureRect.new()
	var logo_atlas := AtlasTexture.new()
	logo_atlas.atlas = load(LOGO_ART) as Texture2D
	logo_atlas.region = Rect2(0, 0, 100, 100)
	logo.texture = logo_atlas
	logo.custom_minimum_size = Vector2(220, 220)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo_column.add_child(logo)
	var logo_caption := _label("BIOTECHNOLOGY  ·  RESEARCH  ·  DISCOVERY", 14, NAVY)
	logo_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo_column.add_child(logo_caption)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 12)
	columns.add_child(copy)
	copy.add_child(_label("WELCOME TO THE LAB", 16, SAGE))
	copy.add_child(_label("BIOLOGIQ", 52, NAVY))
	copy.add_child(_label("A new day. A world of discovery.", 25, TERRACOTTA))
	var rule := ColorRect.new()
	rule.color = SAGE
	rule.custom_minimum_size = Vector2(500, 4)
	copy.add_child(rule)
	var description := _label("Explore a living biotechnology lab, meet its researchers, and try hands-on experiments as you find your place on the team.", 19, Color("#42636a"))
	description.custom_minimum_size = Vector2(560, 92)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(description)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 18
	copy.add_child(spacer)
	var start_button := _button("START YOUR STORY", Vector2(430, 62), SAGE)
	start_button.pressed.connect(_on_start_pressed)
	copy.add_child(start_button)
	var footer := _label("A PIXEL-ART LAB ADVENTURE", 13, Color("#42636a"))
	copy.add_child(footer)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text: String, dimensions: Vector2, base_color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = dimensions
	button.add_theme_font_size_override("font_size", 20)
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


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/select_screen.tscn")
