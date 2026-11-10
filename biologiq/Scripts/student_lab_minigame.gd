extends Control

const FIRST_ROUND_TARGET := 250
const SECOND_ROUND_TARGET := 465
const TRANSFER_AMOUNTS: Array[int] = [5, 10, 25, 50, 75]
const FIRST_ROUND_MINIMUM_DROPS := 4
const SECOND_ROUND_MINIMUM_DROPS := 8
const PIPETTE_ART := "res://Art Assets/micropipette.png"
const PIPETTE_HOME := Vector2(640, 442)
const SOURCE_AREA := Rect2(285, 360, 225, 210)
const TARGET_AREA := Rect2(770, 360, 225, 210)
const PIPETTE_SIZE := Vector2(128, 128)
const CONTINUE_BUTTON := Rect2(430, 548, 200, 54)
const REPLAY_BUTTON := Rect2(650, 548, 200, 54)
const STUDENT_LAB_GUIDE := preload("res://Scripts/student_lab_guide.gd")

var pipette_texture: Texture2D
var pipette_position := PIPETTE_HOME
var dragging := false
var loaded := false
var selected_transfer_volume := 5
var loaded_volume := 0
var current_volume := 0
var drop_count := 0
var target_volume := FIRST_ROUND_TARGET
var minimum_drops := FIRST_ROUND_MINIMUM_DROPS
var earned_stars := 5
var completed := false
var student_guide: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null and save_manager.get_intern_quarters_round() >= 2:
		target_volume = SECOND_ROUND_TARGET
		minimum_drops = SECOND_ROUND_MINIMUM_DROPS
	var pipette_sheet := load(PIPETTE_ART) as Texture2D
	var micropipette := AtlasTexture.new()
	micropipette.atlas = pipette_sheet
	micropipette.region = Rect2(0, 0, 570, 665)
	pipette_texture = micropipette
	student_guide = STUDENT_LAB_GUIDE.new() as Control
	student_guide.call("configure", "Pipette Practice", "Choose a volume with keys 1–5, drag the micropipette to the source well and right-click to load it, then drag to the sample tube and right-click to dispense. Reach exactly %d μL with as few drops as possible." % target_volume)
	add_child(student_guide)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if student_guide != null and bool(student_guide.call("blocks_minigame_input")):
		accept_event()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and not completed:
		if SOURCE_AREA.has_point(event.position) and SOURCE_AREA.has_point(pipette_position) and not loaded:
			loaded = true
			loaded_volume = selected_transfer_volume
			queue_redraw()
			accept_event()
		elif TARGET_AREA.has_point(event.position) and TARGET_AREA.has_point(pipette_position) and loaded:
			loaded = false
			current_volume += loaded_volume
			drop_count += 1
			loaded_volume = 0
			if current_volume >= target_volume:
				completed = true
				earned_stars = maxi(0, 5 - maxi(0, drop_count - minimum_drops))
				if current_volume > target_volume:
					earned_stars = maxi(0, earned_stars - 1)
				var save_manager := get_node_or_null("/root/SaveManager")
				if save_manager != null:
					save_manager.complete_student_lab_pipette()
			queue_redraw()
			accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if completed:
				if CONTINUE_BUTTON.has_point(event.position):
					get_tree().change_scene_to_file("res://Scenes/Rooms/internship_room.tscn")
				accept_event()
				return
			if event.position.distance_to(pipette_position) <= 56.0:
				dragging = true
				accept_event()
		else:
			if dragging:
				dragging = false
				pipette_position = event.position
				queue_redraw()
				accept_event()
	elif event is InputEventMouseMotion and dragging:
		pipette_position = event.position
		queue_redraw()
		accept_event()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://Scenes/Rooms/internship_room.tscn")
	elif not completed and event.keycode in [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5]:
		selected_transfer_volume = TRANSFER_AMOUNTS[event.keycode - KEY_1]
		queue_redraw()


func _draw() -> void:
	# The lab card fills the room with the same navy, cream, sage, and terracotta palette.
	draw_rect(Rect2(Vector2.ZERO, size), Color("#192787"))
	draw_rect(Rect2(20, 20, size.x - 40, size.y - 40), Color("#FAF5E6"))
	draw_rect(Rect2(20, 20, size.x - 40, 10), Color("#5D9374"))
	draw_string(GameFont.FONT, Vector2(64, 82), "INTERN QUARTERS  /  PIPETTE PRACTICE", HORIZONTAL_ALIGNMENT_LEFT, -1, 27, Color("#192787"))
	draw_string(GameFont.FONT, Vector2(64, 116), "Dial the pipette volume with number keys. Reach exactly %d μL using as few drops as possible." % target_volume, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#42636a"))

	_draw_station(SOURCE_AREA, "SOURCE WELL", "Position pipette here, then right-click to collect", Color("#D77A45"))
	_draw_station(TARGET_AREA, "SAMPLE TUBE", "Position loaded pipette here, then right-click to dispense", Color("#5D9374"))
	_draw_well(Vector2(397, 472), Color("#D77A45"), 0.82)
	_draw_beaker(Vector2(882, 425), current_volume / float(target_volume))

	draw_rect(Rect2(514, 276, 252, 54), Color("#E6E0D2"))
	draw_rect(Rect2(514, 276, 252 * clampf(current_volume / float(target_volume), 0.0, 1.0), 54), Color("#5D9374"))
	draw_rect(Rect2(514, 276, 252, 54), Color("#192787"), false, 3.0)
	draw_string(GameFont.FONT, Vector2(564, 311), "%d / %d μL" % [current_volume, target_volume], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#192787"))

	var progress_mark_count := ceili(float(target_volume) / 25.0)
	var marker_spacing := 220.0 / float(maxi(1, progress_mark_count - 1))
	for transfer in progress_mark_count:
		var pip := Vector2(530 + transfer * marker_spacing, 350)
		draw_circle(pip, 7, Color("#5D9374") if transfer < int(current_volume / 25.0) else Color("#D8D2C3"))

	if not completed:
		if pipette_texture != null:
			draw_texture_rect(pipette_texture, Rect2(pipette_position - PIPETTE_SIZE / 2.0, PIPETTE_SIZE), false, Color.WHITE if loaded else Color("#DCE7E5"))
		if loaded:
			draw_circle(pipette_position + Vector2(44, 42), 11, Color("#D77A45"))
			draw_string(GameFont.FONT, pipette_position + Vector2(-24, -72), "%d μL" % loaded_volume, HORIZONTAL_ALIGNMENT_CENTER, 72, 14, Color("#192787"))
		draw_string(GameFont.FONT, Vector2(0, 612), "VOLUME DIAL:  1 = 5 μL     2 = 10 μL     3 = 25 μL     4 = 50 μL     5 = 75 μL", HORIZONTAL_ALIGNMENT_CENTER, int(size.x), 15, Color("#192787"))
		draw_string(GameFont.FONT, Vector2(0, 638), "Selected: %d μL. LEFT-DRAG pipette; RIGHT-CLICK source to draw, then sample tube to dispense." % selected_transfer_volume, HORIZONTAL_ALIGNMENT_CENTER, int(size.x), 13, Color("#42636a"))
		draw_string(GameFont.FONT, Vector2(0, 660), "Minimum %d drops = 5 stars; each extra drop costs a star. Overfilling costs one more. ESC returns to workstation." % minimum_drops, HORIZONTAL_ALIGNMENT_CENTER, int(size.x), 13, Color("#42636a"))
	else:
		_draw_completion()


func _draw_station(area: Rect2, heading: String, instruction: String, accent: Color) -> void:
	draw_rect(area, Color("#F3EEDC"))
	draw_rect(area, accent, false, 4.0)
	draw_string(GameFont.FONT, area.position + Vector2(18, 32), heading, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#192787"))
	draw_string(GameFont.FONT, area.position + Vector2(18, 58), instruction, HORIZONTAL_ALIGNMENT_LEFT, area.size.x - 32, 12, Color("#42636a"))


func _draw_well(center: Vector2, liquid_color: Color, fill_ratio: float) -> void:
	draw_rect(Rect2(center - Vector2(52, 42), Vector2(104, 92)), Color("#FAF5E6"))
	draw_rect(Rect2(center - Vector2(46, 30) + Vector2(0, 60 * (1.0 - fill_ratio)), Vector2(92, 60 * fill_ratio)), liquid_color)
	draw_rect(Rect2(center - Vector2(52, 42), Vector2(104, 92)), Color("#192787"), false, 4.0)
	draw_rect(Rect2(center - Vector2(58, 48), Vector2(116, 12)), Color("#192787"))
	draw_string(GameFont.FONT, center + Vector2(-34, 72), "LIQUID", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#192787"))


func _draw_beaker(center: Vector2, fill_ratio: float) -> void:
	var top_left := center + Vector2(-45, 5)
	var liquid_height := 102.0 * fill_ratio
	draw_rect(Rect2(center + Vector2(-37, 20 + (102.0 - liquid_height)), Vector2(74, liquid_height)), Color("#8BC8D8"))
	draw_line(top_left, center + Vector2(-45, 133), Color("#192787"), 5.0)
	draw_line(center + Vector2(-45, 133), center + Vector2(45, 133), Color("#192787"), 5.0)
	draw_line(center + Vector2(45, 133), center + Vector2(45, 5), Color("#192787"), 5.0)
	draw_line(center + Vector2(-50, 5), center + Vector2(50, 5), Color("#192787"), 5.0)
	for mark in 1:
		var y := center.y + 122.0 - mark * 102.0
		draw_line(Vector2(center.x + 21, y), Vector2(center.x + 42, y), Color("#192787"), 2.0)
	draw_string(GameFont.FONT, center + Vector2(-38, 158), "%d μL" % current_volume, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#192787"))
	draw_string(GameFont.FONT, center + Vector2(-38, 181), "TARGET %d μL" % target_volume, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#5D9374"))


func _draw_completion() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.07, 0.12, 0.28, 0.82))
	draw_rect(Rect2(300, 126, 680, 490), Color("#FAF5E6"))
	draw_rect(Rect2(300, 126, 680, 12), Color("#5D9374"))
	draw_string(GameFont.FONT, Vector2(0, 208), "PRACTICAL COMPLETE!", HORIZONTAL_ALIGNMENT_CENTER, int(size.x), 34, Color("#192787"))
	draw_string(GameFont.FONT, Vector2(0, 250), "%d μL in %d drops (minimum: %d)" % [current_volume, drop_count, minimum_drops], HORIZONTAL_ALIGNMENT_CENTER, int(size.x), 18, Color("#42636a"))
	if current_volume > target_volume:
		draw_string(GameFont.FONT, Vector2(0, 278), "Overfilled: one star lost.", HORIZONTAL_ALIGNMENT_CENTER, int(size.x), 14, Color("#a14f46"))
	for star_index in 5:
		var star_center := Vector2(464 + star_index * 88, 354)
		var points := PackedVector2Array()
		for point_index in 10:
			var angle := -PI / 2.0 + point_index * PI / 5.0
			var radius := 43.0 if point_index % 2 == 0 else 19.0
			points.append(star_center + Vector2(cos(angle), sin(angle)) * radius)
		draw_colored_polygon(points, Color("#D77A45") if star_index < earned_stars else Color("#D8D2C3"))
		for edge in 10:
			draw_line(points[edge], points[(edge + 1) % 10], Color("#192787"), 2.0)
	_draw_button(CONTINUE_BUTTON, "CONTINUE", Color("#5D9374"), Color("#FAF5E6"))
	_draw_button(REPLAY_BUTTON, "PLAY AGAIN", Color("#D8D2C3"), Color("#898d86"))
	draw_string(GameFont.FONT, Vector2(0, 630), "%d / 5 stars. Return to the workstation for your next task." % earned_stars, HORIZONTAL_ALIGNMENT_CENTER, int(size.x), 15, Color("#FAF5E6"))


func _draw_button(area: Rect2, label: String, fill: Color, text_color: Color) -> void:
	draw_rect(area, fill)
	draw_rect(area, Color("#192787"), false, 3.0)
	draw_string(GameFont.FONT, Vector2(area.position.x, area.position.y + 34), label, HORIZONTAL_ALIGNMENT_CENTER, int(area.size.x), 16, text_color)
