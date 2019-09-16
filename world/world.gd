extends Node2D

const N = 1
const E = 2
const S = 4
const W = 8

var cell_walls = {Vector2(0, -1): N, Vector2(1, 0): E, Vector2(0, 1): S, Vector2(-1, 0): W}

var tile_size
var width = 200
var height = 200

onready var Map = $TileMap

var skip_extra_wheel = false

func _ready():
	randomize()
	tile_size = Map.cell_size
	var hgtmap = generate_simplexnoise_heightmap()
	var hgtmap_tbl = generate_tile_lookup(hgtmap[2], hgtmap[1])
	$TextureRect.texture = build_world_texture(hgtmap_tbl, hgtmap[0])

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			if skip_extra_wheel and $customcamera.target_zoom >= general_global.minzoom:
				$customcamera.target_zoom -= general_global.zoomincrement
				skip_extra_wheel = false
			else:
				skip_extra_wheel = true
		elif event.button_index == BUTTON_WHEEL_DOWN:
			if skip_extra_wheel and $customcamera.target_zoom <= general_global.maxzoom:
				$customcamera.target_zoom += general_global.zoomincrement
				skip_extra_wheel = false
			else:
				skip_extra_wheel = true
		elif event.button_index == BUTTON_MIDDLE and event.pressed:
			$customcamera.enablemove = true
			$customcamera.target_move = get_global_mouse_position()

func check_neighbors(cell, unvisited):
	var list = []
	for n in cell_walls.keys():
		if cell + n in unvisited:
			list.append(cell + n)
	return list

func generate_simplexnoise_heightmap():
	var noise = OpenSimplexNoise.new()

	# Configure
	noise.seed = randi()
	noise.octaves = 5
	noise.period = 25.0
	noise.persistence = 0.5
	
	# Sample
	var maxval = -999.0
	var minval = 999.0
	var hgtmap = Array()
	hgtmap.resize(width)
	
	for x in range(width):
		hgtmap[x] = Array()
		hgtmap[x].resize(height)
		for y in range(height):
			hgtmap[x][y] = noise.get_noise_2d(x,y)
			if hgtmap[x][y] < minval:
				minval = hgtmap[x][y]
			if hgtmap[x][y] > maxval:
				maxval = hgtmap[x][y]
	
	return [hgtmap, minval, maxval]
	#var img = noise.get_image(1026,600)
	#var txture = ImageTexture.new()
	#txture.create_from_image(img)
	#return txture

func generate_tile_lookup(maxval, minval):
	# Want nine categories for the nine types of tiles
	var totalrange = maxval - minval

	var indx = totalrange / 9
	var lkup = Array()

	var wrkingval = minval
	
	for i in range(9):
		lkup.append(wrkingval)
		wrkingval += indx
	return lkup
	
func build_world_texture(hgtmaptable, hgtmap):
	Map.clear()
	var fnd = false
	var deeptiles = []
	var medtiles = []
	var shallowtiles = []

	# first pass build the basic terrain
	for x in range(width):
		for y in range(height):
			fnd = false
			for vl in hgtmaptable:
				if hgtmap[x][y] >= vl:
					Map.set_cellv(Vector2(x, y), hgtmaptable.bsearch(vl))
				else:
					# get here the time after you find the right tile to use, index - 1 is the right tile
					if hgtmaptable.bsearch(vl) - 1 == 0:
						deeptiles.append(Vector2(x, y))
					elif hgtmaptable.bsearch(vl) - 1 == 1:
						medtiles.append(Vector2(x, y))
					elif hgtmaptable.bsearch(vl) - 1 == 2:
						shallowtiles.append(Vector2(x, y))
					break

	# get the closest to the border deep tiles, 
	var brder_deepest = {'top': deeptiles[0], 'bottom': deeptiles[0], 'east': deeptiles[0], 'west': deeptiles[0]}
	for tls in deeptiles:
		if tls.y < brder_deepest['top'].y:
			brder_deepest['top'] = tls
		elif tls.y > brder_deepest['bottom'].y:
			brder_deepest['bottom'] = tls
		elif tls.x < brder_deepest['west'].x:
			brder_deepest['west'] = tls
		elif tls.x > brder_deepest['east'].x:
			brder_deepest['east'] = tls
	print(brder_deepest)
	
func make_maze():
	var unvisited = []
	var stack = []
	
	Map.clear()
	for x in range(width):
		for y in range(height):
			unvisited.append(Vector2(x, y))
			Map.set_cellv(Vector2(x, y), N|E|S|W)
	var current = Vector2(0, 0)
	unvisited.erase(current)
	
	# execute recursive backtracker algorithm
	while unvisited:
		var neighbors = check_neighbors(current, unvisited)
		if neighbors.size() > 0:
			var next = neighbors[randi() % neighbors.size()]
			stack.append(current)
			var dir = next-current    # direction vector for direction moved in
			var current_walls = Map.get_cellv(current) - cell_walls[dir]      # remove the wall for the direction moved into new cell
			var next_walls = Map.get_cellv(next) - cell_walls[-dir]         # remove the wall for the direction moved from old cell
			Map.set_cellv(current, current_walls)
			Map.set_cellv(next, next_walls)
			current = next
			unvisited.erase(current)
		elif stack:
			current = stack.pop_back()   # backtrack if there are no neighbors, use the cell behind
		yield(get_tree(), 'idle_frame')
