extends Control

const LOGO_ART := "res://Art Assets/BIOLOGIQ Logo.png"
const LOGO_FRAME_SIZE := Vector2(100, 100)

var logo_atlas: AtlasTexture
var logo_display: TextureRect
var logo_frame := 0
var frame_elapsed := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modulate = Color(1, 1, 1, 0)
	_build_screen()
	var fade_in := create_tween()
	fade_in.tween_property(self, "modulate", Color(1, 1, 1, 1), 1.2)


func _process(delta: float) -> void:
	frame_elapsed += delta
	if frame_elapsed >= 0.32:
		frame_elapsed = 0.0
		logo_frame = (logo_frame + 1) % 2
		logo_atlas.region = Rect2(Vector2(logo_frame * LOGO_FRAME_SIZE.x, 0), LOGO_FRAME_SIZE)


func _build_screen() -> void:
	var background := ColorRect.new()
	background.color = Color("#e9e4d4")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var top_rule := ColorRect.new()
	top_rule.color = Color("#5D9374")
	top_rule.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_rule.offset_bottom = 12
	top_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_rule)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 20)
	center.add_child(stack)

	var thank_you := Label.new()
	thank_you.text = "Thank you for playing the biologiq demo!"
	thank_you.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	thank_you.add_theme_font_size_override("font_size", 28)
	thank_you.add_theme_color_override("font_color", Color("#192787"))
	stack.add_child(thank_you)

	logo_display = TextureRect.new()
	logo_atlas = AtlasTexture.new()
	logo_atlas.atlas = load(LOGO_ART) as Texture2D
	logo_atlas.region = Rect2(Vector2.ZERO, LOGO_FRAME_SIZE)
	logo_display.texture = logo_atlas
	logo_display.custom_minimum_size = Vector2(280, 280)
	logo_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stack.add_child(logo_display)

	var see_you := Label.new()
	see_you.text = "See you next time!"
	see_you.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	see_you.add_theme_font_size_override("font_size", 25)
	see_you.add_theme_color_override("font_color", Color("#D77A45"))
	stack.add_child(see_you)
