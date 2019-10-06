extends Node


#var genned = false


func _ready():
	start_game()

func start_game():
	var thrst = Thread.new()
	thrst.start($worldgen, "create_new_world", null)

func startworld():
	$world_loading_screen.visible = false
	$worldgen/customcamera.target_zoom = .5