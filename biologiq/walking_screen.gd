extends Node2D

const PLAYER_SHEET := "res://Art Assets/Player - Walking Animations (Front, Side, Back).png"
const WALK_DURATION := 2.6
const DOOR_PAUSE := 0.6

var elapsed := 0.0
var player: Node2D


func _ready() -> void:
	player = Node2D.new()
	player.name = "ArrivalPlayer"
	player.position = Vector2(590, 680)
	add_child(player)

	var sprite := AnimatedSprite2D.new()
	sprite.name = "PlayerSprite"
	sprite.sprite_frames = _player_frames()
	sprite.scale = Vector2(0.19, 0.19)
	sprite.position = Vector2(0, -56)
	player.add_child(sprite)
	sprite.play("side_right")


func _process(delta: float) -> void:
	elapsed += delta
	var progress := clampf(elapsed / WALK_DURATION, 0.0, 1.0)
	player.position = Vector2(590, 680).lerp(Vector2(880, 500), progress)
	if elapsed >= WALK_DURATION + DOOR_PAUSE:
		get_tree().change_scene_to_file("res://Scenes/main_map.tscn")


func _player_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	_add_strip(frames, "side_right", 4, 4)
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
