extends Control

const DATA_PATTERNS: Array[String] = [
	"RBGY", "GYRB", "BYGR", "YRBG", "GBRY", "RYGB",
	"BGYR", "YGRB", "BRYG", "GRYB", "YBGR", "RGBY",
]
const PATTERN_COLORS := {
	"R": Color("#D77A45"),
	"B": Color("#115293"),
	"G": Color("#5D9374"),
	"Y": Color("#D7B833"),
}
const OPTION_COUNT := 6
const CARD_SIZE := Vector2(300, 112)
const CARD_GAP := 25.0
const CARD_START_X := 165.0
const CARD_START_Y := 340.0
const CONTINUE_BUTTON := Rect2(500, 542, 280, 58)

var option_patterns: Array[String] = []
var target_pattern := ""
var round_number := 0
var points := 0
var time_remaining := 60.0
var game_over := false
var feedback := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_load_next_pattern()
	queue_redraw()


func _process(delta: float) -> void:
	if game_over:
		return
	time_remaining = maxf(0.0, time_remaining - delta)
	if time_remaining <= 0.0:
		game_over = true
		feedback = "Time is up. Here is your verification score."
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if game_over:
			if CONTINUE_BUTTON.has_point(event.position):
				get_tree().change_scene_to_file("res://Scenes/main_map.tscn")
			accept_event()
			return
		for index in OPTION_COUNT:
			if _card_rect(index).has_point(event.position):
				if option_patterns[index] == target_pattern:
					points += 1
					round_number += 1
					feedback = "Correct match! The next verification pattern is ready."
					_load_next_pattern()
				else:
					feedback = "Pattern mismatch. Try another record."
				queue_redraw()
				accept_event()
				return


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://Scenes/main_map.tscn")


func _load_next_pattern() -> void:
	target_pattern = DATA_PATTERNS[round_number % DATA_PATTERNS.size()]
	option_patterns.clear()
	for offset in OPTION_COUNT:
		option_patterns.append(DATA_PATTERNS[(round_number + offset) % DATA_PATTERNS.size()])
	option_patterns.shuffle()


func _card_rect(index: int) -> Rect2:
	var column := index % 3
	var row := floori(float(index) / 3.0)
	return Rect2(Vector2(CARD_START_X + column * (CARD_SIZE.x + CARD_GAP), CARD_START_Y + row * 138.0), CARD_SIZE)


func _earned_stars() -> int:
	return mini(5, floori(float(points) / 4.0))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#192787"))
	draw_rect(Rect2(20, 20, size.x - 40, size.y - 40), Color("#FAF5E6"))
	draw_rect(Rect2(20, 20, size.x - 40, 10), Color("#5D9374"))
	draw_string(ThemeDB.fallback_font, Vector2(64, 76), "STUDENT LAB  /  DATA VERIFICATION", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#192787"))
	draw_string(ThemeDB.fallback_font, Vector2(64, 109), "RECORD %02d  ·  MATCH THE COLOR ORDER" % [round_number + 1], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#5D9374"))
	var seconds_left := ceili(time_remaining)
	draw_string(ThemeDB.fallback_font, Vector2(927, 76), "TIME  %02d:%02d" % [int(seconds_left / 60.0), seconds_left % 60], HORIZONTAL_ALIGNMENT_LEFT, 230, 20, Color("#192787"))
	draw_string(ThemeDB.fallback_font, Vector2(927, 109), "POINTS  %d" % points, HORIZONTAL_ALIGNMENT_LEFT, 230, 16, Color("#42636a"))

	draw_rect(Rect2(370, 140, 540, 148), Color("#F3EEDC"))
	draw_rect(Rect2(370, 140, 540, 148), Color("#192787"), false, 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(0, 176), "VERIFY THIS DATA PATTERN", HORIZONTAL_ALIGNMENT_CENTER, int(size.x), 17, Color("#42636a"))
	_draw_pattern(target_pattern, Vector2(640, 235), 52.0, 12.0)
	draw_rect(Rect2(340, 304, 600, 12), Color("#E6E0D2"))
	draw_rect(Rect2(340, 304, 600 * time_remaining / 60.0, 12), Color("#5D9374"))

	for index in OPTION_COUNT:
		_draw_option_card(index)
	draw_string(ThemeDB.fallback_font, Vector2(0, 628), "Click the matching record to earn a point and reveal the next pattern.", HORIZONTAL_ALIGNMENT_CENTER, int(size.x), 14, Color("#42636a"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 658), "STAR GUIDE   4 matches = 1 star   ·   8 = 2   ·   12 = 3   ·   16 = 4   ·   20 = 5", HORIZONTAL_ALIGNMENT_CENTER, int(size.x), 13, Color("#5D9374"))
	if game_over:
		_draw_results()


func _draw_pattern(pattern: String, center: Vector2, tile_size: float, gap: float) -> void:
	var total_width := pattern.length() * tile_size + (pattern.length() - 1) * gap
	var start_x := center.x - total_width * 0.5
	for index in pattern.length():
		var tile := Rect2(Vector2(start_x + index * (tile_size + gap), center.y - tile_size * 0.5), Vector2(tile_size, tile_size))
		draw_rect(tile, PATTERN_COLORS[pattern.substr(index, 1)])
		draw_rect(tile, Color("#192787"), false, 3.0)


func _draw_option_card(index: int) -> void:
	var rect := _card_rect(index)
	draw_rect(rect, Color("#F3EEDC"))
	draw_rect(rect, Color("#8BAF75"), false, 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, rect.position.y + 25), "RECORD %02d" % [index + 1], HORIZONTAL_ALIGNMENT_CENTER, int(rect.size.x), 13, Color("#42636a"))
	_draw_pattern(option_patterns[index], Vector2(rect.get_center().x, rect.position.y + 73), 34.0, 8.0)


func _draw_results() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.07, 0.12, 0.28, 0.84))
	draw_rect(Rect2(300, 150, 680, 460), Color("#FAF5E6"))
	draw_rect(Rect2(300, 150, 680, 12), Color("#5D9374"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 232), "VERIFICATION COMPLETE", HORIZONTAL_ALIGNMENT_CENTER, int(size.x), 31, Color("#192787"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 278), "%d matching patterns" % points, HORIZONTAL_ALIGNMENT_CENTER, int(size.x), 21, Color("#42636a"))
	var stars := _earned_stars()
	for index in 5:
		_draw_star(Vector2(544 + index * 48, 370), 22.0, Color("#D77A45") if index < stars else Color("#D8D2C3"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 423), "%d / 5 stars" % stars, HORIZONTAL_ALIGNMENT_CENTER, int(size.x), 19, Color("#5D9374"))
	draw_rect(CONTINUE_BUTTON, Color("#5D9374"))
	draw_rect(CONTINUE_BUTTON, Color("#192787"), false, 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(CONTINUE_BUTTON.position.x, CONTINUE_BUTTON.position.y + 36), "CONTINUE", HORIZONTAL_ALIGNMENT_CENTER, int(CONTINUE_BUTTON.size.x), 17, Color("#FAF5E6"))


func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	var points_array := PackedVector2Array()
	for point_index in 10:
		var angle := -PI / 2.0 + point_index * PI / 5.0
		var point_radius := radius if point_index % 2 == 0 else radius * 0.46
		points_array.append(center + Vector2(cos(angle), sin(angle)) * point_radius)
	draw_colored_polygon(points_array, color)
	for edge in 10:
		draw_line(points_array[edge], points_array[(edge + 1) % 10], Color("#192787"), 1.5)
