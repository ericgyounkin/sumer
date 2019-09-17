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
	var hgtmap_tbl = generate_desert_tile_lookup(hgtmap[2], hgtmap[1])
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


func generate_simplexnoise_heightmap():
	var noise = OpenSimplexNoise.new()

	# Configure
	noise.seed = randi()
	noise.octaves = 10
	noise.period = 65.0
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
	
	# we might want to actually use these numbers direct, let's reference them to a made up datum
	#   Result := ((Input - InputLow) / (InputHigh - InputLow)) * (OutputHigh - OutputLow) + OutputLow;
	var outputlow = -15
	var outputhigh = 60
	for x in range(width):
		for y in range(height):
			hgtmap[x][y] = ((hgtmap[x][y] - minval) / (maxval - minval)) * (outputhigh - outputlow) + outputlow
	
	return [hgtmap, outputlow, outputhigh]
	#var img = noise.get_image(1026,600)
	#var txture = ImageTexture.new()
	#txture.create_from_image(img)
	#return txture

func generate_oasis_tile_lookup(maxval, minval):
	# Want nine categories for the nine types of tiles
	var totalrange = maxval - minval

	var indx = (totalrange / 9) * 2
	var lkup = Array()

	var wrkingval = minval
	
	for i in range(9):
		lkup.append(wrkingval)
		wrkingval += indx
		indx /= 2
	return lkup
	
func generate_desert_tile_lookup(maxval, minval):
	# Want nine categories for the nine types of tiles
	var totalrange = maxval - minval

	var indx = (totalrange / 9) / 1.9
	var lkup = Array()

	var wrkingval = minval
	
	for i in range(9):
		lkup.append(wrkingval)
		indx += (indx / 5)
		wrkingval += indx
	
	print(lkup)
	return lkup
	
func first_pass_terrain(hgtmaptable, hgtmap):
	var deeptiles = []
	var medtiles = []
	var shallowtiles = []
	
	# first pass build the basic terrain
	for x in range(width):
		for y in range(height):
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
	return [deeptiles, medtiles, shallowtiles]

func get_border_deepest(deeptiles, medtiles, shallowtiles):
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
			
	# need some kind of arbitrary dist to edge to prevent 'east' being in the middle of the map or something
	#    if it isn't border-y enough, switch to a shallower tileset
	if brder_deepest['top'].y > 5:
		for tls in medtiles:
			if tls.y < brder_deepest['top'].y:
				brder_deepest['top'] = tls
		if brder_deepest['top'].y > 5:
			for tls in shallowtiles:
				if tls.y < brder_deepest['top'].y:
					brder_deepest['top'] = tls
	
	if (height - brder_deepest['bottom'].y) > 5:
		for tls in medtiles:
			if tls.y > brder_deepest['bottom'].y:
				brder_deepest['bottom'] = tls
		if (height - brder_deepest['bottom'].y) > 5:
			for tls in shallowtiles:
				if tls.y > brder_deepest['bottom'].y:
					brder_deepest['bottom'] = tls
					
	if brder_deepest['west'].x > 5:
		for tls in medtiles:
			if tls.x < brder_deepest['west'].x:
				brder_deepest['west'] = tls
		if brder_deepest['west'].x > 5:
			for tls in shallowtiles:
				if tls.x < brder_deepest['west'].x:
					brder_deepest['west'] = tls
					
	if (width - brder_deepest['east'].x) > 5:
		for tls in medtiles:
			if tls.x > brder_deepest['east'].x:
				brder_deepest['east'] = tls
		if (width - brder_deepest['east'].x) > 5:
			for tls in medtiles:
				if tls.x > brder_deepest['east'].x:
					brder_deepest['east'] = tls
	
	print(brder_deepest)
	return brder_deepest
	
func get_nondeepwater_neighbors(pt):
	# get all the neighbors for startpt, just the orthogonal
	var neighbors = {'N': pt + Vector2(0, 1), 'E': pt + Vector2(1, 0),
	                 'W': pt + Vector2(-1, 0), 'S': pt + Vector2(0, -1)}
	# neighbors can't be outside the bounds of the map
	var offenders = []
	for nbr in neighbors:
		if (neighbors[nbr].x < 0) or (neighbors[nbr].x >= width) or (neighbors[nbr].y < 0) or (neighbors[nbr].y >= height):
			offenders.append(nbr)
	for off in offenders:
		neighbors.erase(off)
		
	# make sure neighbors aren't deep water (so you don't just create pools in river algorithm
	#for pt in neighbors.keys():
	#	if Map.get_cellv(neighbors[pt]) == 0:
	#		neighbors.erase(pt)
	return neighbors
	
func get_neighbor_heights(neighbors, hgtmap):
	var neighbor_hts = {}

	for pt in neighbors.keys():
		var loc = neighbors[pt]
		var hgt = hgtmap[loc.x][loc.y]
		neighbor_hts[hgt] = pt
	return neighbor_hts
	
func river_wander(hgtmap, startpt, endpt):
	var new_startpt = startpt
	var moved_to = Vector2()
	var history = []
	var override_hgts = 5
	
	while moved_to != endpt:
	#for i in range(200):
		moved_to = Vector2()
		
		# get all the neighbors for startpt, just the orthogonal
		var neighbors = get_nondeepwater_neighbors(new_startpt)
		var neighbor_hts = get_neighbor_heights(neighbors, hgtmap)
		
		# force direction towards endpt
		var ideal_direction = new_startpt.direction_to(endpt).normalized().round()
		# no diagonals!
		if ideal_direction.x and ideal_direction.y:
			if randi() % 2:
				ideal_direction = Vector2(ideal_direction.x, 0)
			else:
				ideal_direction = Vector2(0, ideal_direction.y)
					
		# move to the lowest height
		var htsarr = []
		for hts in neighbor_hts:
			 htsarr.append(hts)
		htsarr.sort()
		
		#  cant be a pt youve moved to before
		if override_hgts != 0:
			for hts in htsarr:
				var possible_pt = neighbors[neighbor_hts[hts]]
				if !(possible_pt in history):
					moved_to = possible_pt
					# to prevent just pooling up in deep areas, override every fifth iteration
					override_hgts -= 1
					break
		else:
			override_hgts = 7
			
		# ok, if you get here, just move one tile towards the endpt
		if moved_to == Vector2():
			moved_to = new_startpt + ideal_direction

		new_startpt = moved_to
		Map.set_cellv(moved_to, 0)
		history.append(moved_to)

	
func build_world_texture(hgtmaptable, hgtmap):
	Map.clear()
	
	var tls = first_pass_terrain(hgtmaptable, hgtmap)
	var deeptiles = tls[0]
	var medtiles = tls[1]
	var shallowtiles = tls[2]
	
	
	if deeptiles:
		var brder_deepest = get_border_deepest(deeptiles, medtiles, shallowtiles)
		# start on the side that has the closest to the border tile
		# end at the second closest
		var distfromedge = {'top': brder_deepest['top'].y, 'bottom': height - brder_deepest['bottom'].y,
		                    'west': brder_deepest['west'].x, 'east': width - brder_deepest['east'].x}
		var start_pt = 'top'
		var end_pt = 'top'
		for brder in distfromedge.keys():
			if distfromedge[brder] < distfromedge[start_pt]:
				start_pt =  brder
		if start_pt == 'top':
			end_pt = 'bottom'
		elif start_pt == 'bottom':
			end_pt = 'top'
		elif start_pt == 'west':
			end_pt = 'east'
		elif start_pt == 'east':
			end_pt = 'west'
			
		start_pt = brder_deepest[start_pt]
		end_pt = brder_deepest[end_pt]
		print('start ' + str(start_pt))
		print('end ' + str(end_pt))
		
		# then just connect them following the height map
		river_wander(hgtmap, start_pt, end_pt)
		
		
		# get the three biggest concentrations of deepwater
		var temphgt = []
		var deepest_tls = []
		var deepest_tls_sorted = []
		var deepest_tls_location = []
	    # get the deepest three spots first
		for tls in deeptiles:
			temphgt = hgtmap[tls.x][tls.y]
			deepest_tls.append(temphgt)
			
		deepest_tls_sorted = deepest_tls.duplicate()
		deepest_tls_sorted.sort()
			#for spts in deepspots:
				# check if deeptile is deeper than previously logged deepspots and also separated from them
			#	if (temphgt < hgtmap[spts.x][spts.y]) and tls.distance_to(spts) > 5:
					

func check_neighbors(cell, unvisited):
	var list = []
	for n in cell_walls.keys():
		if cell + n in unvisited:
			list.append(cell + n)
	return list
	
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
