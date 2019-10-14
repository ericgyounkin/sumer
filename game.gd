extends Node


onready var wlscreen = $CanvasLayer/world_loading_screen
onready var custcamera = $worldgen/customcamera
onready var wrld = $worldgen

var worldgenthread


func _ready():
	wrld.width = global.width
	wrld.height = global.height
	wrld.riverwidth = global.river_width
	custcamera.offset = Vector2(0, global.height * 16)
	custcamera.target_zoom = global.start_zoom_level
	start_game()

func start_game():
	worldgenthread = Thread.new()
	worldgenthread.start(wrld, "create_new_world", null)

func startworld():
	wlscreen.visible = false
	custcamera.target_zoom = .5