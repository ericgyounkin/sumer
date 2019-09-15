extends Node2D

const N = 1
const E = 2
const S = 4
const W = 8

var cell_walls = {Vector2(0, -1): N, Vector2(1, 0): E, Vector2(0, 1): S, Vector2(-1, 0): W}

var tile_size = 32
var width = 64
var height = 64

onready var Map = $TileMap


func _ready():
	randomize()
	tile_size = Map.cell_size
	var hgtmap = generate_simplexnoise_heightmap()
	var hgtmap_tbl = generate_tile_lookup(hgtmap[2], hgtmap[1])
	$TextureRect.texture = build_world_texture(hgtmap_tbl, hgtmap[0])

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
	noise.period = 64.0
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
	for x in range(width):
		for y in range(height):
			for vl in hgtmaptable:
				if hgtmap[x][y] >= vl:
					Map.set_cellv(Vector2(x, y), hgtmaptable.bsearch(vl))

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
