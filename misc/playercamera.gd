extends Camera2D

var smooth_zoom = general_global.startzoom
var target_zoom = general_global.startzoom

const ZOOM_SPEED = 5

var priorzoom = 0


func _ready():
	set_zoom(Vector2(general_global.startzoom, general_global.startzoom))

func _process(delta):
	if smooth_zoom != target_zoom:
		smooth_zoom = lerp(smooth_zoom, target_zoom, ZOOM_SPEED * delta)
		set_zoom(Vector2(smooth_zoom, smooth_zoom))
		
func conv_zoomin():
	priorzoom = target_zoom
	target_zoom = general_global.convzoom
	
func conv_zoomout():
	target_zoom = priorzoom
	priorzoom = 0