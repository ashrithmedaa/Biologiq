extends Control

const SAM_SHEET := "res://Art Assets/Sam - Front walking spritesheet transparent.png"
const NAVY := Color("#192787")
const CREAM := Color("#FAF5E6")
const SAGE := Color("#5D9374")
const INK := Color("#42636a")
const QUESTIONS: Array[String] = [
	"What do you do at Biologiq?",
	"Why is your work important?",
	"What will I be doing as an intern?",
]
const ANSWERS: Array[String] = [
	"I’m a laboratory technician from the diagnostic research department! I work with biological samples, prepare experiments, work with laboratory equipment, and collaborate with other researchers to collect data.",
	"Accurate results can help healthcare professionals with identifying diseases early on, and allow informed decisions about the patient to be made.",
	"You will be learning the fundamental techniques that people like me use in the lab every day. This includes preparing samples, running tests, and documenting results. Organization is just as important as the experiments themselves!",
]

var activity_title := "Lab Activity"
var activity_instructions := ""
var show_briefing := true
var enable_dialogue := false
var briefing_open := true
var dialogue_open := false
var briefing_layer: Control
var dialogue_layer: Control
var dialogue_answer: Label


func configure(title: String, instructions: String, show_instructions: bool = true, allow_sam_dialogue: bool = false) -> void:
	activity_title = title
	activity_instructions = instructions
	show_briefing = show_instructions
	enable_dialogue = allow_sam_dialogue


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	briefing_open = show_briefing
	if show_briefing:
		_build_briefing()
	if enable_dialogue:
		_build_dialogue()


func blocks_minigame_input() -> bool:
	return briefing_open or dialogue_open


func open_dialogue() -> void:
	if not enable_dialogue:
		return
	dialogue_open = true
	dialogue_layer.show()
	dialogue_answer.text = "Choose a question and I’ll explain."


func _build_briefing() -> void:
	briefing_layer = Control.new()
	briefing_layer.name = "Instructions"
	briefing_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	briefing_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	briefing_layer.z_index = 20
	add_child(briefing_layer)
	_add_rect(briefing_layer, "Backdrop", Rect2(Vector2.ZERO, Vector2(1280, 720)), Color(0.035, 0.07, 0.20, 0.84))
	_add_panel(briefing_layer, "InstructionCard", Rect2(160, 110, 960, 500))
	_add_rect(briefing_layer, "PanelTrim", Rect2(164, 114, 952, 10), SAGE)
	_add_label(briefing_layer, "ActivityTitle", Rect2(210, 156, 860, 48), activity_title, 28, NAVY)
	_add_label(briefing_layer, "ActivityInstructions", Rect2(210, 225, 860, 190), activity_instructions, 19, INK, true)
	_add_label(briefing_layer, "StartHint", Rect2(210, 435, 860, 30), "When you’re ready, start the activity.", 15, SAGE, false, HORIZONTAL_ALIGNMENT_CENTER)
	var start_button := _add_button(briefing_layer, "StartActivity", Rect2(470, 500, 340, 54), "START ACTIVITY", SAGE, CREAM, 17)
	start_button.pressed.connect(_start_activity)


func _build_dialogue() -> void:
	dialogue_layer = Control.new()
	dialogue_layer.name = "SamDialogue"
	dialogue_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialogue_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	dialogue_layer.z_index = 30
	dialogue_layer.visible = false
	add_child(dialogue_layer)
	_add_rect(dialogue_layer, "Scrim", Rect2(Vector2.ZERO, Vector2(1280, 720)), Color(0.035, 0.07, 0.20, 0.72))
	_add_panel(dialogue_layer, "DialogueCard", Rect2(630, 65, 600, 590))
	_add_rect(dialogue_layer, "PanelTrim", Rect2(634, 69, 592, 10), SAGE)
	_add_label(dialogue_layer, "Heading", Rect2(660, 94, 400, 38), "TALK TO SAM", 24, NAVY)
	var close_button := _add_button(dialogue_layer, "Close", Rect2(1168, 84, 44, 38), "X", Color("#D8D2C3"), NAVY, 15)
	close_button.pressed.connect(_close_dialogue)
	_add_sam_portrait(dialogue_layer, Rect2(1070, 132, 120, 205))
	_add_label(dialogue_layer, "SamCaption", Rect2(1056, 342, 148, 30), "Sam  ·  Lab Technician", 12, NAVY, false, HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(dialogue_layer, "QuestionPrompt", Rect2(660, 140, 390, 28), "What would you like to ask?", 14, SAGE)
	_add_questions(dialogue_layer, 660, 174, 390, 54, "Question")
	_add_panel(dialogue_layer, "AnswerBox", Rect2(660, 382, 550, 238), Color("#E6E0D2"), SAGE, 2)
	dialogue_answer = _add_label(dialogue_layer, "Answer", Rect2(678, 398, 514, 206), "Choose a question and I’ll explain.", 15, Color("#303856"), true)


func _add_questions(parent: Control, x: float, y: float, width: float, height: float, prefix: String) -> void:
	for index in QUESTIONS.size():
		var button := _add_button(
			parent,
			"%s%d" % [prefix, index + 1],
			Rect2(x, y + index * (height + 8.0), width, height),
			QUESTIONS[index],
			Color("#F3EEDC"),
			Color("#303856"),
			14
		)
		button.pressed.connect(_show_answer.bind(index))


func _add_sam_portrait(parent: Control, area: Rect2) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = load(SAM_SHEET) as Texture2D
	atlas.region = Rect2(430, 285, 350, 700)
	var portrait := TextureRect.new()
	portrait.name = "SamPortrait"
	portrait.position = area.position
	portrait.size = area.size
	portrait.texture = atlas
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(portrait)


func _add_rect(parent: Control, node_name: String, area: Rect2, fill: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = node_name
	rect.position = area.position
	rect.size = area.size
	rect.color = fill
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	return rect


func _add_panel(parent: Control, node_name: String, area: Rect2, fill: Color = CREAM, border: Color = NAVY, border_width: int = 4) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.position = area.position
	panel.size = area.size
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel


func _add_label(parent: Control, node_name: String, area: Rect2, text: String, font_size: int, color: Color, wrap: bool = false, alignment: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = area.position
	label.size = area.size
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	label.add_theme_font_override("font", GameFont.FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _add_button(parent: Control, node_name: String, area: Rect2, text: String, fill: Color, text_color: Color, font_size: int) -> Button:
	var button := Button.new()
	button.name = node_name
	button.position = area.position
	button.size = area.size
	button.text = text
	button.add_theme_font_override("font", GameFont.FONT)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_stylebox_override("normal", _button_style(fill, NAVY))
	button.add_theme_stylebox_override("hover", _button_style(fill.lightened(0.08), NAVY))
	button.add_theme_stylebox_override("pressed", _button_style(fill.darkened(0.06), NAVY))
	button.add_theme_stylebox_override("focus", _button_style(fill, NAVY))
	parent.add_child(button)
	return button


func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	return style


func _show_answer(index: int) -> void:
	dialogue_answer.text = ANSWERS[index]


func _start_activity() -> void:
	briefing_open = false
	briefing_layer.hide()


func _close_dialogue() -> void:
	dialogue_open = false
	dialogue_layer.hide()


func _input(event: InputEvent) -> void:
	if dialogue_open and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_close_dialogue()
		get_viewport().set_input_as_handled()
