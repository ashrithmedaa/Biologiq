extends Node
@onready var animatedSprite2d = $AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animatedSprite2d.play("default")



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/select_screen.tscn")
