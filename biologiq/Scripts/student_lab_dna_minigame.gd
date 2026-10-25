extends Control

const SEGMENTS := [
	{"art": "res://Art Assets/Dna.png", "bases": ["A", "C", "T", "G", "G", "A", "C", "T"]},
	{"art": "res://Art Assets/dna2.png", "bases": ["G", "T", "C", "A", "C", "T", "A", "G"]},
	{"art": "res://Art Assets/dna3.png", "bases": ["C", "T", "G", "G", "T", "C", "T", "A"]},
	{"art": "res://Art Assets/dna4.png", "bases": ["C", "A", "T", "C", "G", "G", "T", "A"]},
]
const BASE_ART := {
	"A": "res://Art Assets/red dna base (a).png",
	"T": "res://Art Assets/yellow dna base (t).png",
	"C": "res://Art Assets/blue dna base (c).png",
	"G": "res://Art Assets/green dna base (g).png",
}
const COMPLEMENT := {"A": "T", "T": "A", "C": "G", "G": "C"}
const BASE_LETTERS: Array[String] = ["A", "T", "C", "G"]
const DNA_RECT := Rect2(390, 112, 500, 500)
const DNA_SCALE := 5.0
const TARGET_ROW_Y := [25.0, 29.0, 33.0, 37.0, 64.0, 68.0, 72.0, 76.0]
const TARGET_CENTER_X := 60.0
const CARD_TOP := 550.0
const CARD_SIZE := Vector2(204, 80)
const CARD_GAP := 24.0
const CARD_START_X := 166.0
const ADVANCE_BUTTON := Rect2(480, 536, 320, 58)

var segment_textures: Array[Texture2D] = []
var base_icons: Dictionary = {}
var base_sequence: Array[String] = []
var placed_bases: Array[String] = []
var segment_index := 0
var dragging_base := ""
var drag_position := Vector2.ZERO
var round_complete := false
var feedback := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	for segment in SEGMENTS:
		segment_textures.append(load(str(segment.art)) as Texture2D)
	for base in BASE_ART:
		var atlas := AtlasTexture.new()
		atlas.atlas = load(str(BASE_ART[base])) as Texture2D
		atlas.region = Rect2(40, 40, 22, 3)
		base_icons[base] = atlas
	_load_segment(0)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if round_complete:
				if ADVANCE_BUTTON.has_point(event.position):
					if segment_index + 1 < SEGMENTS.size():
						_load_segment(segment_index + 1)
					else:
						get_tree().change_scene_to_file("res://Scenes/main_map.tscn")
				accept_event()
				return
			for base_index in BASE_ART.size():
				if _card_rect(base_index).has_point(event.position):
					dragging_base = BASE_LETTERS[base_index]
					drag_position = event.position
					feedback = "Drag %s to the matching open base position." % dragging_base
					queue_redraw()
					accept_event()
					return
		else:
			if dragging_base != "":
				var slot := _slot_at(event.position)
				if slot >= 0 and placed_bases[slot] == "":
					var expected := str(COMPLEMENT[base_sequence[slot]])
					if dragging_base == expected:
						placed_bases[slot] = dragging_base
						feedback = "%s pairs with %s. Nice work!" % [base_sequence[slot], dragging_base]
						if not placed_bases.has(""):
							round_complete = true
							if segment_index + 1 >= SEGMENTS.size():
								var save_manager := get_node_or_null("/root/SaveManager")
								if save_manager != null:
									save_manager.complete_student_lab_dna()
					else:
						feedback = "That pair does not match. %s pairs with %s." % [base_sequence[slot], expected]
				else:
					feedback = "Drop a base onto an open position on the strand."
				dragging_base = ""
				queue_redraw()
				accept_event()
	elif event is InputEventMouseMotion and dragging_base != "":
		drag_position = event.position
		queue_redraw()
		accept_event()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://Scenes/main_map.tscn")


func _load_segment(index: int) -> void:
	segment_index = index
	base_sequence.clear()
	for base in SEGMENTS[segment_index].bases:
		base_sequence.append(str(base))
	placed_bases.clear()
	for _slot in base_sequence.size():
		placed_bases.append("")
	round_complete = false
	dragging_base = ""
	feedback = "Complete all eight base pairs to earn this segment's star."
	queue_redraw()


func _card_rect(index: int) -> Rect2:
	return Rect2(Vector2(CARD_START_X + index * (CARD_SIZE.x + CARD_GAP), CARD_TOP), CARD_SIZE)


func _target_center(index: int) -> Vector2:
	return Vector2(DNA_RECT.position.x + TARGET_CENTER_X * DNA_SCALE, DNA_RECT.position.y + TARGET_ROW_Y[index] * DNA_SCALE)


func _slot_rect(index: int) -> Rect2:
	return Rect2(_target_center(index) - Vector2(64, 9), Vector2(128, 18))


func _slot_at(at: Vector2) -> int:
	for index in placed_bases.size():
		if _slot_rect(index).has_point(at):
			return index
	return -1


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#192787"))
	draw_rect(Rect2(20, 20, size.x - 40, size.y - 40), Color("#FAF5E6"))
	draw_rect(Rect2(20, 20, size.x - 40, 10), Color("#5D9374"))
	draw_string(ThemeDB.fallback_font, Vector2(64, 72), "STUDENT LAB  /  DNA MATCHING", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color("#192787"))
	draw_string(ThemeDB.fallback_font, Vector2(64, 100), "SEGMENT %d OF %d" % [segment_index + 1, SEGMENTS.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#5D9374"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 106), "Drag the complementary base from its box onto each open rung.", HORIZONTAL_ALIGNMENT_CENTER, int(size.x), 16, Color("#42636a"))
	_draw_star_progress()

	var strand: Texture2D = segment_textures[segment_index]
	draw_texture_rect(strand, DNA_RECT, false)
	draw_string(ThemeDB.fallback_font, Vector2(478, 152), "TEMPLATE BASE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#42636a"))
	draw_string(ThemeDB.fallback_font, Vector2(642, 152), "ADD COMPLEMENT", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#42636a"))
	var hovered_slot: int = _slot_at(drag_position) if dragging_base != "" else -1
	for index in base_sequence.size():
		var center := _target_center(index)
		if placed_bases[index] == "":
			var slot_fill := Color("#E6E0D2")
			var slot_outline := Color("#8BAF75")
			if index == hovered_slot:
				slot_fill = Color("#DCEBD9")
				slot_outline = Color("#D77A45")
			draw_rect(_slot_rect(index), slot_fill)
			draw_rect(_slot_rect(index), slot_outline, false, 3.0 if index == hovered_slot else 2.0)
		else:
			_draw_base_icon(placed_bases[index], center, Vector2(96, 15))

	for card_index in BASE_ART.size():
		_draw_base_card(card_index)
	draw_string(ThemeDB.fallback_font, Vector2(0, 650), feedback, HORIZONTAL_ALIGNMENT_CENTER, int(size.x), 15, Color("#42636a"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 684), "ESC  Leave lab", HORIZONTAL_ALIGNMENT_CENTER, int(size.x), 12, Color("#7b8980"))
	if dragging_base != "":
		_draw_base_icon(dragging_base, drag_position, Vector2(120, 18))
		draw_string(ThemeDB.fallback_font, drag_position + Vector2(14, -14), dragging_base, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#192787"))
	if round_complete:
		_draw_round_complete()


func _draw_base_card(index: int) -> void:
	var base: String = BASE_LETTERS[index]
	var rect := _card_rect(index)
	draw_rect(rect, Color("#F3EEDC"))
	draw_rect(rect, _base_color(base), false, 3.0)
	var icon_center := Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + 22)
	_draw_base_icon(base, icon_center, Vector2(94, 14))
	draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, rect.position.y + 67), "%s  /  %s" % [base, _base_name(base)], HORIZONTAL_ALIGNMENT_CENTER, int(rect.size.x), 16, Color("#192787"))


func _draw_base_icon(base: String, center: Vector2, dimensions: Vector2) -> void:
	var icon: Texture2D = base_icons[base]
	draw_texture_rect(icon, Rect2(center - dimensions / 2.0, dimensions), false)


func _draw_star_progress() -> void:
	for index in SEGMENTS.size():
		var star_center := Vector2(1044 + index * 42, 68)
		_draw_star(star_center, 15.0, Color("#D77A45") if index < segment_index or (index == segment_index and round_complete) else Color("#D8D2C3"))


func _draw_round_complete() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.07, 0.12, 0.28, 0.82))
	draw_rect(Rect2(300, 180, 680, 430), Color("#FAF5E6"))
	draw_rect(Rect2(300, 180, 680, 12), Color("#5D9374"))
	var final_segment := segment_index + 1 >= SEGMENTS.size()
	var heading := "ALL DNA SEGMENTS MATCHED!" if final_segment else "DNA SEGMENT %d COMPLETE!" % [segment_index + 1]
	draw_string(ThemeDB.fallback_font, Vector2(0, 254), heading, HORIZONTAL_ALIGNMENT_CENTER, int(size.x), 30, Color("#192787"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 295), "Eight complementary pairs placed correctly.", HORIZONTAL_ALIGNMENT_CENTER, int(size.x), 17, Color("#42636a"))
	for index in SEGMENTS.size():
		_draw_star(Vector2(544 + index * 48, 372), 22.0, Color("#D77A45") if index <= segment_index else Color("#D8D2C3"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 427), "%d of 4 segment stars earned" % [segment_index + 1], HORIZONTAL_ALIGNMENT_CENTER, int(size.x), 16, Color("#5D9374"))
	if final_segment:
		draw_string(ThemeDB.fallback_font, Vector2(0, 464), "Return to the Student Lab to begin data verification.", HORIZONTAL_ALIGNMENT_CENTER, int(size.x), 15, Color("#42636a"))
	_draw_action_button(ADVANCE_BUTTON, "CONTINUE" if final_segment else "NEXT SEGMENT")


func _draw_action_button(rect: Rect2, label: String) -> void:
	draw_rect(rect, Color("#5D9374"))
	draw_rect(rect, Color("#192787"), false, 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, rect.position.y + 36), label, HORIZONTAL_ALIGNMENT_CENTER, int(rect.size.x), 17, Color("#FAF5E6"))


func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for point_index in 10:
		var angle := -PI / 2.0 + point_index * PI / 5.0
		var point_radius := radius if point_index % 2 == 0 else radius * 0.46
		points.append(center + Vector2(cos(angle), sin(angle)) * point_radius)
	draw_colored_polygon(points, color)
	for edge in 10:
		draw_line(points[edge], points[(edge + 1) % 10], Color("#192787"), 1.5)


func _base_color(base: String) -> Color:
	match base:
		"A": return Color("#b52424")
		"T": return Color("#b7cc14")
		"C": return Color("#115293")
		_: return Color("#5D9374")


func _base_name(base: String) -> String:
	match base:
		"A": return "ADENINE"
		"T": return "THYMINE"
		"C": return "CYTOSINE"
		_: return "GUANINE"
