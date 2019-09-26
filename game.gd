extends Node

var progress
var genned = false


func _ready():
	start_game()


func start_game():
	#var thread = Thread.new()
	#thread.start($worldgen, "create_new_world", null)
	$worldgen.create_new_world(null)