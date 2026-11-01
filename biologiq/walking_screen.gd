extends Node2D

const PLAYER_SHEET := "res://Art Assets/Player - Walking Animations (Front, Side, Back).png"
const WALK_DURATION := 2.6
const DOOR_PAUSE := 0.6
const GRASS_DARK := Color("#648d58")
const GRASS_MID := Color("#789f65")
const GRASS_LIGHT := Color("#91b574")
const NAVY := Color("#192787")
const CREAM := Color("#FAF5E6")

var elapsed := 0.0
var player: Node2D
var player_sprite: AnimatedSprite2D


func _ready() -> void:
	player = Node2D.new()
	player.name = "ArrivalPlayer"
	player.position = Vector2(590, 680)
	add_child(player)

	player_sprite = AnimatedSprite2D.new()
	player_sprite.name = "PlayerSprite"
	player_sprite.sprite_frames = _player_frames()
	player_sprite.scale = Vector2(0.19, 0.19)
	player_sprite.position = Vector2(0, -56)
	player.add_child(player_sprite)
	player_sprite.play("walk_away")
	queue_redraw()


func _draw() -> void:
	_draw_sky()
	_draw_grass()
	_draw_laboratory()
	_draw_sidewalk()
	_draw_landscaping()


func _draw_sky() -> void:
	draw_rect(Rect2(0, 0, 1280, 182), Color("#b9d9d4"))
	draw_rect(Rect2(0, 158, 1280, 24), Color("#a8ccbd"))
	# Stepped pixel clouds.
	for cloud in [Vector2(92, 55), Vector2(1050, 82), Vector2(580, 32)]:
		var cloud_color := Color("#e8f1df")
		draw_rect(Rect2(cloud + Vector2(16, 8), Vector2(64, 16)), cloud_color)
		draw_rect(Rect2(cloud + Vector2(32, 0), Vector2(40, 32)), cloud_color)
		draw_rect(Rect2(cloud, Vector2(24, 16)), cloud_color)
		draw_rect(Rect2(cloud + Vector2(72, 16), Vector2(24, 8)), cloud_color)


func _draw_laboratory() -> void:
	# Broad shadow, low wing, and central glass entry make the destination read as a building.
	draw_rect(Rect2(205, 436, 880, 28), Color("#526f54"))
	draw_rect(Rect2(190, 86, 900, 372), NAVY)
	draw_rect(Rect2(202, 98, 876, 360), Color("#e1e4c8"))
	draw_rect(Rect2(202, 98, 876, 18), Color("#5d9374"))
	draw_rect(Rect2(202, 424, 876, 34), Color("#c2caa8"))
	# Pixel trim across the facade.
	for x in range(218, 1064, 32):
		draw_rect(Rect2(x, 120, 16, 8), Color("#8bc8d8"))
		draw_rect(Rect2(x, 442, 16, 8), Color("#8bc8d8"))
	# Left laboratory windows.
	for window in [Rect2(258, 194, 126, 132), Rect2(414, 194, 126, 132), Rect2(570, 194, 104, 132)]:
		_draw_window(window)
	# Entry tower and sign.
	draw_rect(Rect2(706, 132, 344, 312), Color("#192787"))
	draw_rect(Rect2(718, 144, 320, 300), Color("#c8d9c5"))
	draw_rect(Rect2(740, 154, 276, 54), Color("#192787"))
	draw_rect(Rect2(748, 162, 260, 38), Color("#f3eedc"))
	draw_string(ThemeDB.fallback_font, Vector2(782, 187), "BIOLOGIQ", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, NAVY)
	draw_rect(Rect2(740, 214, 276, 12), Color("#d77a45"))
	# Glass doors and transom.
	draw_rect(Rect2(788, 244, 184, 22), NAVY)
	draw_rect(Rect2(796, 252, 168, 14), Color("#8bc8d8"))
	draw_rect(Rect2(780, 266, 200, 184), NAVY)
	draw_rect(Rect2(792, 278, 88, 160), Color("#6fabb1"))
	draw_rect(Rect2(880, 278, 88, 160), Color("#79b7bb"))
	draw_rect(Rect2(870, 278, 10, 160), Color("#f3eedc"))
	# Reflections, door rails, handles, and a clearly visible threshold.
	draw_rect(Rect2(804, 290, 12, 116), Color("#c5e2d5"))
	draw_rect(Rect2(824, 290, 8, 94), Color("#c5e2d5"))
	draw_rect(Rect2(900, 290, 12, 116), Color("#c5e2d5"))
	draw_rect(Rect2(940, 290, 8, 94), Color("#c5e2d5"))
	draw_rect(Rect2(854, 344, 6, 42), Color("#f3eedc"))
	draw_rect(Rect2(890, 344, 6, 42), Color("#f3eedc"))
	draw_rect(Rect2(766, 444, 228, 16), Color("#d77a45"))
	draw_rect(Rect2(758, 460, 244, 10), NAVY)
	# Wall lamps and planter ledges.
	for x in [228, 650, 1036]:
		draw_rect(Rect2(x, 236, 10, 40), NAVY)
		draw_rect(Rect2(x - 5, 228, 20, 12), Color("#f7d58b"))
		draw_rect(Rect2(x - 2, 276, 14, 6), Color("#d77a45"))
	draw_rect(Rect2(226, 338, 438, 12), Color("#8c6544"))
	draw_rect(Rect2(226, 350, 438, 8), NAVY)


func _draw_window(area: Rect2) -> void:
	draw_rect(area.grow(6), NAVY)
	draw_rect(area, Color("#78b8bb"))
	draw_rect(Rect2(area.position + Vector2(8, 10), Vector2(18, area.size.y - 20)), Color("#c5e2d5"))
	draw_rect(Rect2(area.position.x + area.size.x * 0.5 - 4, area.position.y, 8, area.size.y), Color("#e1e4c8"))
	draw_rect(Rect2(area.position.x, area.position.y + area.size.y * 0.64, area.size.x, 8), Color("#e1e4c8"))
	draw_rect(Rect2(area.position.x + 8, area.end.y - 28, area.size.x - 16, 18), Color("#5d9374"))


func _draw_grass() -> void:
	draw_rect(Rect2(0, 182, 1280, 538), GRASS_MID)
	# Soft square patches and tiny pixel tufts keep the lawn textured without a checkerboard.
	for x in range(16, 1280, 64):
		for y in range(188, 720, 64):
			var seed := (x * 17 + y * 31) % 13
			if seed < 5:
				draw_rect(Rect2(x + seed * 2, y + (seed % 3) * 5, 28 + seed, 10 + seed % 4), GRASS_DARK)
			elif seed < 9:
				draw_rect(Rect2(x + 14, y + 18, 30, 8), GRASS_LIGHT)
			if (x + y) % 3 == 0:
				draw_rect(Rect2(x + 6, y + 34, 3, 8), Color("#527d4b"))
				draw_rect(Rect2(x + 10, y + 30, 3, 12), Color("#5d8950"))
				draw_rect(Rect2(x + 14, y + 35, 3, 7), Color("#527d4b"))


func _draw_sidewalk() -> void:
	# A straight landing in front of the door joins a perspective walkway to the camera.
	draw_rect(Rect2(0, 466, 1280, 86), Color("#8a8c7c"))
	draw_rect(Rect2(0, 466, 1280, 8), Color("#e2d9bd"))
	draw_rect(Rect2(0, 544, 1280, 8), Color("#626d61"))
	draw_colored_polygon(PackedVector2Array([Vector2(510, 720), Vector2(1110, 720), Vector2(1000, 552), Vector2(760, 552)]), Color("#bcb8a0"))
	draw_colored_polygon(PackedVector2Array([Vector2(532, 720), Vector2(1088, 720), Vector2(986, 560), Vector2(774, 560)]), Color("#d7cfb6"))
	# Paver joints follow the walkway's perspective.
	for y: float in [580.0, 612.0, 650.0, 696.0]:
		var t: float = (y - 560.0) / 160.0
		var left := lerpf(774.0, 532.0, t)
		var right := lerpf(986.0, 1088.0, t)
		draw_line(Vector2(left, y), Vector2(right, y), Color("#b4ad96"), 3.0)
	for t: float in [0.22, 0.48, 0.74]:
		var top_x := lerpf(774.0, 986.0, t)
		var bottom_x := lerpf(532.0, 1088.0, t)
		draw_line(Vector2(top_x, 560), Vector2(bottom_x, 720), Color("#b4ad96"), 3.0)
	# Broad, uneven slabs across the landing.
	for x in range(0, 1280, 112):
		draw_line(Vector2(x, 474), Vector2(x + 12, 544), Color("#777d71"), 2.0)
	draw_line(Vector2(0, 510), Vector2(1280, 510), Color("#777d71"), 2.0)
	# Curb blocks and tactile edge at the lawn.
	for x in range(0, 1280, 48):
		draw_rect(Rect2(x, 548, 42, 8), Color("#e8dfc4"))
		draw_rect(Rect2(x + 42, 548, 6, 8), Color("#8a8c7c"))


func _draw_landscaping() -> void:
	# Foundation planting beds and clipped pixel shrubs frame the entrance.
	for bed in [Rect2(244, 366, 214, 34), Rect2(476, 366, 188, 34), Rect2(1004, 366, 52, 34)]:
		draw_rect(bed, Color("#8b6547"))
		draw_rect(Rect2(bed.position.x, bed.position.y, bed.size.x, 8), Color("#5c7949"))
		for x in range(int(bed.position.x + 8), int(bed.end.x - 12), 32):
			_draw_shrub(x, 360)
	# A pair of planters beside the approach.
	for x in [442, 1032]:
		draw_rect(Rect2(x, 494, 58, 42), Color("#a85f43"))
		draw_rect(Rect2(x - 5, 488, 68, 10), Color("#192787"))
		for leaf in range(4):
			draw_rect(Rect2(x + 8 + leaf * 11, 470 - (leaf % 2) * 8, 8, 24 + (leaf % 2) * 8), Color("#4f824e"))
	# Small flowers dot the lawn edges.
	for flower in [Vector2(116, 610), Vector2(276, 674), Vector2(1164, 622), Vector2(1210, 682), Vector2(350, 582)]:
		draw_rect(Rect2(flower, Vector2(5, 10)), Color("#4f824e"))
		draw_rect(Rect2(flower + Vector2(-4, -4), Vector2(5, 5)), Color("#f6d58e"))
		draw_rect(Rect2(flower + Vector2(4, -4), Vector2(5, 5)), Color("#f6d58e"))
		draw_rect(Rect2(flower + Vector2(0, -8), Vector2(5, 5)), Color("#f6d58e"))


func _draw_shrub(x: int, y: int) -> void:
	draw_rect(Rect2(x, y, 24, 15), Color("#4e7b4e"))
	draw_rect(Rect2(x + 4, y - 7, 16, 10), Color("#679450"))
	draw_rect(Rect2(x + 8, y - 3, 6, 5), Color("#89ac5d"))


func _process(delta: float) -> void:
	elapsed += delta
	var progress := clampf(elapsed / WALK_DURATION, 0.0, 1.0)
	player.position = Vector2(590, 680).lerp(Vector2(880, 500), progress)
	player_sprite.scale = Vector2.ONE * lerpf(0.19, 0.15, progress)
	if elapsed >= WALK_DURATION + DOOR_PAUSE:
		get_tree().change_scene_to_file("res://Scenes/main_map.tscn")


func _player_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	_add_strip(frames, "walk_away", 12, 4)
	return frames


func _add_strip(frames: SpriteFrames, animation: StringName, start_frame: int, count: int) -> void:
	frames.add_animation(animation)
	frames.set_animation_loop(animation, true)
	frames.set_animation_speed(animation, 8.0)
	var texture := load(PLAYER_SHEET) as Texture2D
	for index in count:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(Vector2((start_frame + index) * 306, 0), Vector2(306, 646))
		frames.add_frame(animation, atlas)
