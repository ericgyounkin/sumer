extends Node

# game parameters
var width = 700
var height = 700
var start_zoom_level = 12
var river_width = width / 60
var spaced_out_factor = 10
var rdp_epsilon = 4

var start_location = Vector2(0, height * 16)

func _ready():
	start_zoom_level = start_zoom_level
	river_width = river_width
	start_location = start_location