extends Node


onready var wlscreen = $CanvasLayer/world_loading_screen
onready var custcamera = $worldgen/customcamera
onready var wrld = $worldgen

onready var zig = load('res://Building/Ziggurat.tscn')

var worldgenthread


func _ready():
	wrld.width = global.width
	wrld.height = global.height
	wrld.riverwidth = global.river_width
	custcamera.offset = global.start_location
	custcamera.target_zoom = global.start_zoom_level
	start_game()

func start_game():
	# run on starting the game, kicks off the world generation
	
	worldgenthread = Thread.new()
	worldgenthread.start(wrld, "create_new_world", null)

func startworld():
	# gets here when you are ready to interact with the world
	
	wlscreen.visible = false
	custcamera.target_zoom = .5
	
	var new_ziggurat = zig.instance()
	#new_ziggurat.global_position = global.start_location
	global.start_location = wrld.return_highest_point()
	print('start location')
	print(global.start_location)
	new_ziggurat.global_position = global.start_location
	custcamera.offset = global.start_location
	$buildings.add_child(new_ziggurat)
	