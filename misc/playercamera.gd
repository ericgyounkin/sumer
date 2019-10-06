extends Camera2D


var startzoom = 8
var maxzoom = 8
var minzoom = .5
var convzoom = 1.75
var zoomincrement = 0.25

var smooth_zoom = startzoom
var target_zoom = startzoom

var target_move = offset

const ZOOM_SPEED = 5
const MOVE_SPEED = 5

var priorzoom = 0
var enablemove = false


func _ready():
	set_zoom(Vector2(startzoom, startzoom))

func _process(delta):
	if smooth_zoom != target_zoom:
		smooth_zoom = lerp(smooth_zoom, target_zoom, ZOOM_SPEED * delta)
		set_zoom(Vector2(smooth_zoom, smooth_zoom))
	if offset != target_move and enablemove:
		offset = offset.linear_interpolate(target_move, MOVE_SPEED * delta)
	elif enablemove and offset == target_move:
		enablemove = false
		
func conv_zoomin():
	priorzoom = target_zoom
	target_zoom = convzoom
	
func conv_zoomout():
	target_zoom = priorzoom
	priorzoom = 0