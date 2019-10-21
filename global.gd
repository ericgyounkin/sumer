extends Node

# game parameters
var width = 200
var height = 200
var start_zoom_level = 12
var river_width = width / 50

var start_location = Vector2(0, height * 16)

func _ready():
	start_zoom_level = start_zoom_level
	river_width = river_width
	start_location = start_location