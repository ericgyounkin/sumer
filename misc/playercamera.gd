extends Camera2D

# just trying to clear out all these 'declared but never emitted' warnings...
var emit_if_true = false

var startzoom = 8
var maxzoom = 15
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
	if emit_if_true:
		print(maxzoom)
		print(minzoom)
		print(zoomincrement)

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