extends Node

var FONT: FontFile = preload("res://Art Assets/CascadiaMono.ttf")


func _ready() -> void:
	# Disable smoothing so the monospaced glyph edges stay crisp beside pixel art.
	FONT.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	FONT.oversampling = 1.0
