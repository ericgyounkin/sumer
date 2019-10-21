extends Node2D

var debug = false
var benchmark = true

const N = 1
const E = 2
const S = 4
const W = 8

var cell_walls = {Vector2(0, -1): N, Vector2(1, 0): E, Vector2(0, 1): S, Vector2(-1, 0): W}

var tile_size
var width
var height
var riverwidth

onready var Map = $TileMap
onready var WLS = get_parent().get_node('CanvasLayer/world_loading_screen')

var progress = true

var skip_extra_wheel = false

#signal updateprogbars
signal worldcreated

#var genned = false
var hgtmap
var hgtmap_tbl
var noise
var maxval
var minval

# first pass terrain generates these and doesnt show
var starttils

var deeptiles = []
var medtiles = []
var shallowtiles = []

var rivertiles = []
var greentiles = []
var deeprivtiles = []
var medrivtiles = []
var shallrivtiles = []


func _ready():
	randomize()
	tile_size = Map.cell_size
	#if WLS:
		#connect("updateprogbars", WLS, "updatebars")
	var status = connect('worldcreated', get_parent(), 'startworld')
	print('world_created_status ' + str(status))

func create_new_world(placeholder):
	if placeholder != null:
		print('attempting to use unexpected argument in create_new_world')
	
	var thread_simp = Thread.new()
	thread_simp.start(self, "generate_simplexnoise_heightmap", null)
	thread_simp.wait_to_finish()
	
	var thread_des = Thread.new()
	thread_des.start(self, "generate_desert_tile_lookup", null)
	thread_des.wait_to_finish()
	
	var thread_world = Thread.new()
	thread_world.start(self, "build_world_texture", null)
	thread_world.wait_to_finish()
	
	emit_signal('worldcreated')
	return

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			if skip_extra_wheel and $customcamera.target_zoom >= $customcamera.minzoom:
				$customcamera.target_zoom -= $customcamera.zoomincrement
				skip_extra_wheel = false
			else:
				skip_extra_wheel = true
		elif event.button_index == BUTTON_WHEEL_DOWN:
			if skip_extra_wheel and $customcamera.target_zoom <= $customcamera.maxzoom:
				$customcamera.target_zoom += $customcamera.zoomincrement
				skip_extra_wheel = false
			else:
				skip_extra_wheel = true
		elif event.button_index == BUTTON_MIDDLE and event.pressed:
			$customcamera.enablemove = true
			$customcamera.target_move = get_global_mouse_position()

func check_tile_in_map(til):
	if (til.x < width) and (til.x >= 0) and (til.y < height) and (til.y >= 0):
		return true
	else:
		return false

func find_tile_neighbors_same_type(til, override_tile_type=null):
	var tiletype = 0
	if !(override_tile_type == null):
		tiletype = override_tile_type
	else:
		tiletype = Map.get_cellv(til)
	var neighbors = {'N': til + Vector2(0, 1), 'E': til + Vector2(1, 0),
	                 'W': til + Vector2(-1, 0), 'S': til + Vector2(0, -1),
					 'NE': til + Vector2(1, 1), 'SW': til + Vector2(-1, -1),
	                 'NW': til + Vector2(-1, 1), 'SE': til + Vector2(1, -1)}
	# search tiles and if they exist return the number of tiles that match the tiletype
	var sametype = []
	for nbr in neighbors:
		if check_tile_in_map(neighbors[nbr]) == true:
			if Map.get_cellv(neighbors[nbr]) == tiletype:
				sametype.append(nbr)
	return sametype
	
func is_neighboring_a_river(til):
	var neighbors = {'N': til + Vector2(0, 1), 'E': til + Vector2(1, 0),
	                 'W': til + Vector2(-1, 0), 'S': til + Vector2(0, -1),
					 'NE': til + Vector2(1, 1), 'SW': til + Vector2(-1, -1),
	                 'NW': til + Vector2(-1, 1), 'SE': til + Vector2(1, -1)}
	# search tiles and if they exist return the number of tiles that match the tiletype
	for nbr in neighbors:
		if rivertiles.has(nbr):
			print('neighbor!')
			return true
	return false
	
func generate_simplexnoise_heightmap(placeholder):
	if placeholder != null:
		print('attempting to use unexpected argument in create_new_world')
	if progress:
		WLS.call_deferred('setup_heightmap_bar', 'Generate Heightmap', 0, width * 2)
		#WLS.setup_heightmap_bar('Generate Heightmap', 0, width * height * 2)
	noise = OpenSimplexNoise.new()

	# Configure
	noise.seed = randi()
	noise.octaves = 10
	noise.period = 65.0
	noise.persistence = 0.5
	
	# Sample
	maxval = -999.0
	minval = 999.0
	hgtmap = Array()
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
		if progress:
			WLS.call_deferred('increment_heightmap_bar')
	
	# we might want to actually use these numbers direct, let's reference them to a made up datum
	#   Result := ((Input - InputLow) / (InputHigh - InputLow)) * (OutputHigh - OutputLow) + OutputLow;
	var outputlow = -15
	var outputhigh = 60
	for x in range(width):
		for y in range(height):
			hgtmap[x][y] = ((hgtmap[x][y] - minval) / (maxval - minval)) * (outputhigh - outputlow) + outputlow
		if progress:
			WLS.call_deferred('increment_heightmap_bar')
	if progress:
		#WLS.call_deferred('hack_fill_heightmap_bar')
		pass
	hgtmap = [hgtmap, outputlow, outputhigh]
	
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
		# have to use 'i' to get it out of the errors list...
		if i == 100000:
			print(i)
			
	return lkup
	
func generate_desert_tile_lookup(placeholder):
	if placeholder != null:
		print('attempting to use unexpected argument in create_new_world')
	var maxval = hgtmap[2]
	var minval = hgtmap[1]
	
	if progress:
		WLS.call_deferred('setup_lookup_bar', 'Generate Lookup Table', 0, 9)
		
	# Want nine categories for the nine types of tiles
	var totalrange = maxval - minval

	var indx = (totalrange / 9) / 4.9
	var lkup = Array()

	var wrkingval = minval
	
	for i in range(9):
		lkup.append(wrkingval)
		indx += (indx / 5)
		wrkingval += indx
		if progress:
			WLS.call_deferred('increment_lookup_bar')
		# have to use 'i' to get it out of the errors list...
		if i == 100000:
			print(i)
			
	if progress:
		#WLS.call_deferred('hack_fill_lookup_bar')
		pass
	print(lkup)
	hgtmap_tbl = lkup
	
func first_pass_terrain(placeholder):
	if placeholder != null:
		print('attempting to use unexpected argument in create_new_world')
	if progress:
		WLS.call_deferred('setup_firstpass_bar', 'Initial Terrain Generation', 0, width * height)
	
	# first pass build the basic terrain
	starttils = Array()
	starttils.resize(width)
	for x in range(width):
		starttils[x] = Array()
		starttils[x].resize(height)
		for y in range(height):
			if progress:
				WLS.call_deferred('increment_firstpass_bar')
			for vl in hgtmap_tbl:
				if hgtmap[0][x][y] >= vl:
					Map.call_deferred('set_cellv', Vector2(x, y), 8)
					starttils[x][y] = hgtmap_tbl.bsearch(vl)
				else:
					# get here the time after you find the right tile to use, index - 1 is the right tile
					if hgtmap_tbl.bsearch(vl) - 1 == 0:
						deeptiles.append(Vector2(x, y))
					elif hgtmap_tbl.bsearch(vl) - 1 == 1:
						medtiles.append(Vector2(x, y))
					elif hgtmap_tbl.bsearch(vl) - 1 == 2:
						shallowtiles.append(Vector2(x, y))
					break
	if progress:
		#WLS.call_deferred('hack_fill_firstpass_bar')
		pass

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
					
	# now force border deepest selections to actually be at the border regardless
	brder_deepest['top'].y = 0
	brder_deepest['bottom'].y = height - 1
	brder_deepest['west'].x = 0
	brder_deepest['east'].x = width - 1
	
	print(brder_deepest)
	return brder_deepest
	
func get_nondeepwater_neighbors(pt):
	# get all the neighbors for startpt, just the orthogonal
	var neighbors = {'N': pt + Vector2(0, 1), 'E': pt + Vector2(1, 0),
	                 'W': pt + Vector2(-1, 0), 'S': pt + Vector2(0, -1)}
	# neighbors can't be outside the bounds of the map
	var offenders = []
	for nbr in neighbors:
		if check_tile_in_map(neighbors[nbr]) == false:
			offenders.append(nbr)
	for off in offenders:
		neighbors.erase(off)
		
	# make sure neighbors aren't deep water (so you don't just create pools in river algorithm
	#for pt in neighbors.keys():
		#if Map.get_cellv(neighbors[pt]) == 0:
			#neighbors.erase(pt)
	return neighbors
	
func get_neighbor_heights(neighbors, hgtmap):
	var neighbor_hts = {}

	for pt in neighbors.keys():
		var loc = neighbors[pt]
		var hgt = hgtmap[loc.x][loc.y]
		neighbor_hts[hgt] = pt
	return neighbor_hts
	
func return_highest_point():
	var max_height = -999
	var max_height_loc = Vector2()
	for x in range(width * .25, width * .75):
		for y in range(height * .25, height * .75):
			if hgtmap[0][x][y] > max_height and !rivertiles.has(Vector2(x, y)):
				max_height = hgtmap[0][x][y]
				max_height_loc = Vector2(x, y)
	return $TileMap.map_to_world(max_height_loc)

func rdp_point_line_distance(point, start, end):
	var dx = end.x - start.x
	var dy = end.y - start.y
	
	#Normalize
	var mag = pow(pow(dx, 2.0) + pow(dy, 2.0), 0.5)
	if mag > 0.0:
		dx = dx / mag
		dy = dy / mag
	
	var pvx = point.x - start.x
	var pvy = point.y - start.y
	
	var pvdot = dx * pvx + dy * pvy
	
	var dsx = pvdot * dx
	var dsy = pvdot * dy
	
	var ax = pvx - dsx
	var ay = pvy - dsy
	
	return pow(pow(ax, 2.0) + pow(ay, 2.0), 0.5)

func rdp(pts, epsilon=3):
	# Ramer-Douglas-Peucker algorithm https://github.com/sebleier/RDP/blob/master/__init__.py
	"""
    Reduces a series of points to a simplified version that loses detail, but
    maintains the general shape of the series.
    """
	
	if len(pts) < 2:
		print('need more than two points!')
		return
	
	var dmax = 0.0
	var index = 0
	var end = len(pts) - 1
	var d
	var results
	
	for i in range(1, end):
		d = rdp_point_line_distance(pts[i], pts[0], pts[end])
		if d > dmax:
			index = i
			dmax = d
	if dmax >= epsilon:
		var newpts = Array()
		for i in range(0, index + 1):
			newpts.append(pts[i])
		var newptstwo = Array()
		for i in range(index, end):
			newptstwo.append(pts[i])
		results = rdp(newpts, epsilon) + rdp(newptstwo, epsilon)
	else:
		results = [pts[0], pts[-1]]
	return results

func spaced_out_pts(pts, max_distance=5):
	# Just to get all points within the same distance of each other
	var newpts = []
	var newpt
	var dist = 0
	var direct = Vector2()

	var ct = 1
	for pt in pts:
		newpts.append(pt)
		if ct == (len(pts) - 1):
			break
		dist = pt.distance_to(pts[ct])
		direct = pt.direction_to(pts[ct]).normalized()
		newpt = pt
		while dist > max_distance:
			newpt = newpt + (direct * max_distance).round()
			newpts.append(newpt)
			dist = newpt.distance_to(pts[ct])
		ct += 1
	return newpts

func river_wander(pts):
	var startpt = pts[0]
	var endpt = pts[1]
	var simplify = pts[2]
	
	var new_startpt = startpt
	var moved_to = Vector2()
	var history = []
	
	if progress:
		WLS.call_deferred('setup_rivergen_bar', 'Find River Path', 0, width + height)
	
	# parameters for the algorithm
	var override_hgts = 2  # 
	
	history.append(startpt)
	while moved_to != endpt:
	#for i in range(200):
		moved_to = Vector2()
		
		# get all the neighbors for startpt, just the orthogonal
		var neighbors = get_nondeepwater_neighbors(new_startpt)
		var neighbor_hts = get_neighbor_heights(neighbors, hgtmap[0])
		
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
					# to prevent just pooling up in deep areas, override every third iteration
					override_hgts -= 1
					break
		else:
			override_hgts = 3
			
		# ok, if you get here, just move one tile towards the endpt
		if moved_to == Vector2():
			moved_to = new_startpt + ideal_direction

		new_startpt = moved_to
		
		history.append(moved_to)
		
		if progress:
			WLS.call_deferred('increment_rivergen_bar')
	
	if simplify:
		print('simplifying river path...')
		var newpts = rdp(history)
		newpts = spaced_out_pts(newpts)
		rivertiles = newpts
		for pts in newpts:
			Map.call_deferred('set_cellv', pts, 0)
	else:
		rivertiles = history
		for pt in history:
			Map.call_deferred('set_cellv', pt, 0)
		
	if progress:
		#WLS.call_deferred('hack_fill_rivergen_bar')
		pass
	
func expand_river(rivertiles, expandtiles, mag_inc):
	var ct = 0
	for til in rivertiles:
		if ct in [0,1,2]:
			ct += 1
			continue
		if ct == len(rivertiles)-4:
			break
		# its a problem of calculating slope of the line and then getting a perpendicular
		#    want to widen along the perpendicular
		var cur_idx = ct
		#var prevtil = rivertiles[cur_idx - 1]
		#var nexttil = rivertiles[cur_idx + 1]
		var wayback_til = rivertiles[cur_idx - 2]
		var wayforward_til = rivertiles[cur_idx + 2]
		
		var slope = (wayforward_til - wayback_til).normalized().round()
		var rotatedslope = slope.rotated(-PI/2) * mag_inc
		
#		var newrtil = [til + rotatedslope, til - rotatedslope, prevtil + rotatedslope, prevtil - rotatedslope, nexttil + rotatedslope, nexttil - rotatedslope]
#		for newtil in newrtil:
#			if check_tile_in_map(newtil) and !(newtil in expandtiles):
#				expandtiles.append(newtil)
#				Map.set_cellv(newtil, 0)

		if rotatedslope.x < rotatedslope.y:
			rotatedslope += Vector2(2,0)
		if rotatedslope.y < rotatedslope.x:
			rotatedslope += Vector2(0,2)

		# now account for all tiles that fall in this perpendicular
		for x in rotatedslope.x:
			for y in rotatedslope.y:
				if check_tile_in_map(Vector2(til.x + x, til.y)) and !(Vector2(til.x + x, til.y) in expandtiles):
					if (Map.call_deferred('get_cellv', Vector2(til.x + x, til.y)) != 0):
						expandtiles.append(Vector2(til.x + x, til.y))
						#Map.set_cellv(Vector2(til.x + x, til.y), Map.get_cellv(Vector2(til.x + x, til.y)) - 1)
						Map.call_deferred('set_cellv', Vector2(til.x + x, til.y), 0)
				if check_tile_in_map(Vector2(til.x, til.y + y)) and !(Vector2(til.x, til.y + y) in expandtiles):
					if (Map.call_deferred('get_cellv', Vector2(til.x, til.y + y)) != 0):
						expandtiles.append(Vector2(til.x, til.y + y))
						#Map.set_cellv(Vector2(til.x, til.y + y), Map.get_cellv(Vector2(til.x, til.y + y)) - 1)
						Map.call_deferred('set_cellv', Vector2(til.x, til.y + y), 0)
				if check_tile_in_map(Vector2(til.x - x, til.y)) and !(Vector2(til.x - x, til.y) in expandtiles):
					if (Map.call_deferred('get_cellv', Vector2(til.x - x, til.y)) != 0):
						expandtiles.append(Vector2(til.x - x, til.y))
						#Map.set_cellv(Vector2(til.x - x, til.y), Map.get_cellv(Vector2(til.x - x, til.y)) - 1)
						Map.call_deferred('set_cellv', Vector2(til.x - x, til.y), 0)
				if check_tile_in_map(Vector2(til.x, til.y - y)) and !(Vector2(til.x, til.y - y) in expandtiles):
					if (Map.call_deferred('get_cellv', Vector2(til.x, til.y - y)) != 0):
						expandtiles.append(Vector2(til.x, til.y - y))
						#Map.set_cellv(Vector2(til.x, til.y - y), Map.get_cellv(Vector2(til.x, til.y - y)) - 1)
						Map.call_deferred('set_cellv', Vector2(til.x, til.y - y), 0)
		ct += 1

	return expandtiles
	
func expand_river_v2(opts):
	#OS.delay_msec(10000)
	var mag_inc = opts[0]
	var midexpand = opts[1]
	var shallexpand = opts[2]

	var factr = mag_inc
	var mid_factr = mag_inc
	var shall_factr = mag_inc
	
	var deeptile_generation_benchmark = 0
	var deeptile_validation_benchmark = 0
	var medtile_generation_benchmark = 0
	var medtile_validation_benchmark = 0
	var shalltile_generation_benchmark = 0
	var shalltile_validation_benchmark = 0
	var shalltile_settile_benchmark = 0
	var starttime = 0
	var endtime = 0
	if benchmark:
		print('running expand_river_v2 with benchmarking enabled...')
	
	if progress:
		WLS.call_deferred('setup_riverwiden_bar', 'Expand River', 0, len(rivertiles) * mag_inc * 40)
	
	for til in rivertiles:
		# determine block size
		var rnge = int(factr * 2)
		factr = (randi() % (rnge + 1)) + round(mag_inc - (rnge / 2))
		if debug:
			print('starting tile: ' + str(til))
			print('deepfactr: ' + str(factr))
		
		# just draw a big block around each river tile, fuck it
		if benchmark:
			starttime = OS.get_ticks_msec()
		var newtils = []
		for f in range(factr):
			newtils.append(til + Vector2(-1 * (f + 1), 1 * (f + 1)))
			newtils.append(til + Vector2(0, 1 * (f + 1)))
			newtils.append(til + Vector2(1 * (f + 1), 1 * (f + 1)))
			newtils.append(til + Vector2(-1 * (f + 1), 0))
			newtils.append(til + Vector2(1 * (f + 1), 0))
			newtils.append(til + Vector2(-1 * (f + 1), -1 * (f + 1)))
			newtils.append(til + Vector2(0, -1 * (f + 1)))
			newtils.append(til + Vector2(1 * (f + 1), -1 * (f + 1)))
		if benchmark:
			endtime = OS.get_ticks_msec()
			deeptile_generation_benchmark += endtime - starttime
		
		if benchmark:
			starttime = OS.get_ticks_msec()
		for newt in newtils:
			if check_tile_in_map(newt) and !(newt in rivertiles) and !(newt in deeprivtiles):
				# smooth out edge of deeprivtiles by only accepting tiles with neighbors of same type
				if len(find_tile_neighbors_same_type(newt, 0)) >= 3:
					deeprivtiles.append(newt)
					#Map.set_cellv(Vector2(til.x, til.y - y), Map.get_cellv(Vector2(til.x, til.y - y)) - 1)
					Map.call_deferred('set_cellv', newt, 0)
			if progress:
				WLS.call_deferred('increment_riverwiden_bar')
		if debug:
			print('New deep river tiles: ' + str(deeprivtiles))
		if benchmark:
			endtime = OS.get_ticks_msec()
			deeptile_validation_benchmark += endtime - starttime
		
	if midexpand:
		for til in deeprivtiles:
			# draw in the middle tiles
			var newtils = []
			if benchmark:
				starttime = OS.get_ticks_msec()
			for f in range(mid_factr):
				newtils.append(til + Vector2(-1 * (f + 1), 1 * (f + 1)))
				newtils.append(til + Vector2(0, 1 * (f + 1)))
				newtils.append(til + Vector2(1 * (f + 1), 1 * (f + 1)))
				newtils.append(til + Vector2(-1 * (f + 1), 0))
				newtils.append(til + Vector2(1 * (f + 1), 0))
				newtils.append(til + Vector2(-1 * (f + 1), -1 * (f + 1)))
				newtils.append(til + Vector2(0, -1 * (f + 1)))
				newtils.append(til + Vector2(1 * (f + 1), -1 * (f + 1)))
			if benchmark:
				endtime = OS.get_ticks_msec()
				medtile_generation_benchmark += endtime - starttime
			
			if benchmark:
				starttime = OS.get_ticks_msec()
			for newt in newtils:
				if check_tile_in_map(newt) and !(newt in rivertiles) and !(newt in deeprivtiles) and !(newt in medrivtiles):
					#if (len(find_tile_neighbors_same_type(newt, 0)) >= 3):
					medrivtiles.append(newt)
				if progress:
					WLS.call_deferred('increment_riverwiden_bar')
			# have to do a second pass, so that your check for nearby tiles isn't affected by you changing the tile type
			for medt in medrivtiles:
				Map.call_deferred('set_cellv', medt, 1)
			if debug:
				print('medfactr: ' + str(mid_factr))
				print('New medium river tiles: ' + str(medrivtiles))
			if benchmark:
				endtime = OS.get_ticks_msec()
				medtile_validation_benchmark += endtime - starttime
				
	if shallexpand:
		for til in medrivtiles:
			# draw in the shallow tiles
			var newtils = []
			if benchmark:
				starttime = OS.get_ticks_msec()
			for f in range(shall_factr):
				newtils.append(til + Vector2(-1 * (f + 1), 1 * (f + 1)))
				newtils.append(til + Vector2(0, 1 * (f + 1)))
				newtils.append(til + Vector2(1 * (f + 1), 1 * (f + 1)))
				newtils.append(til + Vector2(-1 * (f + 1), 0))
				newtils.append(til + Vector2(1 * (f + 1), 0))
				newtils.append(til + Vector2(-1 * (f + 1), -1 * (f + 1)))
				newtils.append(til + Vector2(0, -1 * (f + 1)))
				newtils.append(til + Vector2(1 * (f + 1), -1 * (f + 1)))
			if benchmark:
				endtime = OS.get_ticks_msec()
				shalltile_generation_benchmark += endtime - starttime
			
			if benchmark:
				starttime = OS.get_ticks_msec()
			for newt in newtils:
				if check_tile_in_map(newt) and !(newt in rivertiles) and !(newt in deeprivtiles) and !(newt in medrivtiles) and !(newt in shallrivtiles):
					#if (len(find_tile_neighbors_same_type(newt, 1)) >= 3):
					shallrivtiles.append(newt)
				if progress:
					WLS.call_deferred('increment_riverwiden_bar')
			if benchmark:
				endtime = OS.get_ticks_msec()
				shalltile_validation_benchmark += endtime - starttime
			
			if benchmark:
				starttime = OS.get_ticks_msec()
			# have to do a second pass, so that your check for nearby tiles isn't affected by you changing the tile type
			for medt in shallrivtiles:
				Map.call_deferred('set_cellv', medt, 2)
			if debug:
				print('shallfactr: ' + str(shall_factr))
				print('New shallow river tiles: ' + str(shallrivtiles))
			if benchmark:
				endtime = OS.get_ticks_msec()
				shalltile_settile_benchmark += endtime - starttime
				
	# rebuild rivertiles to include all water tiles
	for til in deeprivtiles:
		if !(til in rivertiles):
			rivertiles.append(til)
	for til in medrivtiles:
		if !(til in rivertiles):
			rivertiles.append(til)
	for til in shallrivtiles:
		if !(til in rivertiles):
			rivertiles.append(til)

	print('expand: ' + str(len(deeprivtiles)) + ' new deep river tiles')
	print('expand: ' + str(len(medrivtiles)) + ' new medium river tiles')
	print('expand: ' + str(len(shallrivtiles)) + ' new shallow river tiles')
	if benchmark:
		print('Time spent on deep river tile generation: ' + str(deeptile_generation_benchmark) + 'ms')
		print('Time spent on deep river tile validation: ' + str(deeptile_validation_benchmark) + 'ms')
		print('Time spent on medium river tile generation: ' + str(medtile_generation_benchmark) + 'ms')
		print('Time spent on medium river tile validation: ' + str(medtile_validation_benchmark) + 'ms')
		print('Time spent on shallow river tile generation: ' + str(shalltile_generation_benchmark) + 'ms')
		print('Time spent on shallow river tile validation: ' + str(shalltile_validation_benchmark) + 'ms')
		print('Time spent on shallow river tile setting: ' + str(shalltile_settile_benchmark) + 'ms')
	
	if progress:
		WLS.call_deferred('hack_fill_riverwiden_bar')
		
func expand_river_v3(opts):
	var mag_inc = opts[0]
	var midexpand = opts[1]
	var shallexpand = opts[2]

	var factr = mag_inc
	var mid_factr = mag_inc
	var shall_factr = mag_inc
	
	var deeptile_generation_benchmark = 0
	var deeptile_validation_benchmark = 0
	var medtile_generation_benchmark = 0
	var medtile_validation_benchmark = 0
	var shalltile_generation_benchmark = 0
	var shalltile_validation_benchmark = 0
	var shalltile_settile_benchmark = 0
	#var starttime = 0
	#var endtime = 0
	if benchmark:
		print('running expand_river_v3 with benchmarking enabled...')
	
	if progress:
		WLS.call_deferred('setup_riverwiden_bar', 'Expand River', 0, len(rivertiles) * 4 * 4 * factr)
	
	var ct = 0
	
	for til in rivertiles:
		var deepwaterfactr = factr
		
		if ct == len(rivertiles) - 1:
			break
		var nexttil = rivertiles[ct + 1]
		
		# get tangent directions for expansion
		var fwddir = til.direction_to(nexttil)
		var pos_tangent = fwddir.tangent()
		var neg_tangent = pos_tangent.rotated(PI)
		
		for fact in range(deepwaterfactr):
			for newt in [(til + pos_tangent * (fact + 1)).round(), (til + neg_tangent * (fact + 1)).round(),
			             (til + fwddir + (pos_tangent * (fact + 1))).round(), (til + fwddir + (neg_tangent * (fact + 1))).round()]:
				if check_tile_in_map(newt) and !(rivertiles.has(newt)) and !(deeprivtiles.has(newt)) and !(medrivtiles.has(newt)) and !(shallrivtiles.has(newt)):
					# smooth out edge of deeprivtiles by only accepting tiles with neighbors of same type
					deeprivtiles.append(newt)
					#Map.set_cellv(Vector2(til.x, til.y - y), Map.get_cellv(Vector2(til.x, til.y - y)) - 1)
					Map.call_deferred('set_cellv', newt, 0)
				if progress:
					WLS.call_deferred('increment_riverwiden_bar')
			if debug:
				print('New deep river tiles: ' + str(deeprivtiles))
		ct += 1
	
	if midexpand:
		ct = 0
		for til in rivertiles:
			var midwaterfactr = mid_factr
					
			if ct == len(rivertiles) - 1:
				break
			var nexttil = rivertiles[ct + 1]
			
			# get tangent directions for expansion
			var fwddir = til.direction_to(nexttil)
			var pos_tangent = fwddir.tangent()
			var neg_tangent = pos_tangent.rotated(PI)
			
			for fact in range(midwaterfactr):
				for newt in [(til + pos_tangent * (fact + 1) + (midwaterfactr * pos_tangent)).round(), (til + neg_tangent * (fact + 1) + (midwaterfactr * neg_tangent)).round(),
							 (til + fwddir + pos_tangent * (fact + 1) + (midwaterfactr * pos_tangent)).round(), (til + fwddir + neg_tangent * (fact + 1) + (midwaterfactr * neg_tangent)).round()]:
					if check_tile_in_map(newt) and !(rivertiles.has(newt)) and !(deeprivtiles.has(newt)) and !(medrivtiles.has(newt)) and !(shallrivtiles.has(newt)):
						# smooth out edge of deeprivtiles by only accepting tiles with neighbors of same type
						medrivtiles.append(newt)
						#Map.set_cellv(Vector2(til.x, til.y - y), Map.get_cellv(Vector2(til.x, til.y - y)) - 1)
						Map.call_deferred('set_cellv', newt, 1)
					if progress:
						WLS.call_deferred('increment_riverwiden_bar')
				if debug:
					print('New medium river tiles: ' + str(deeprivtiles))
			
			ct += 1
			
	if shallexpand and midexpand:
		ct = 0
		for til in rivertiles:
			var shallwaterfactr = shall_factr
			
			if ct == len(rivertiles) - 1:
				break
			var nexttil = rivertiles[ct + 1]
			
			# get tangent directions for expansion
			var fwddir = til.direction_to(nexttil)
			var pos_tangent = fwddir.tangent()
			var neg_tangent = pos_tangent.rotated(PI)
			
			for fact in range(shallwaterfactr):
				for newt in [(til + pos_tangent * (fact + 1) + ((mid_factr + shall_factr) * pos_tangent)).round(), (til + neg_tangent * (fact + 1) + ((mid_factr + shall_factr) * neg_tangent)).round(),
							 (til + fwddir + pos_tangent * (fact + 1) + ((mid_factr + shall_factr) * pos_tangent)).round(), (til + fwddir + neg_tangent * (fact + 1) + ((mid_factr + shall_factr) * neg_tangent)).round()]:
					if check_tile_in_map(newt) and !(rivertiles.has(newt)) and !(deeprivtiles.has(newt)) and !(medrivtiles.has(newt)) and !(shallrivtiles.has(newt)):
						# smooth out edge of deeprivtiles by only accepting tiles with neighbors of same type
						shallrivtiles.append(newt)
						#Map.set_cellv(Vector2(til.x, til.y - y), Map.get_cellv(Vector2(til.x, til.y - y)) - 1)
						Map.call_deferred('set_cellv', newt, 2)
					if progress:
						WLS.call_deferred('increment_riverwiden_bar')
				if debug:
					print('New shall river tiles: ' + str(deeprivtiles))
			ct += 1
	
		ct = 0
		for til in rivertiles:
			var greenfactr = shall_factr
			
			if ct == len(rivertiles) - 1:
				break
			var nexttil = rivertiles[ct + 1]
			
			# get tangent directions for expansion
			var fwddir = til.direction_to(nexttil)
			var pos_tangent = fwddir.tangent()
			var neg_tangent = pos_tangent.rotated(PI)
			
			for fact in range(greenfactr):
				for newt in [(til + pos_tangent * (fact + 1) + ((mid_factr + shall_factr + shall_factr) * pos_tangent)).round(), (til + neg_tangent * (fact + 1) + ((mid_factr + shall_factr + shall_factr) * neg_tangent)).round(),
							 (til + fwddir + pos_tangent * (fact + 1) + ((mid_factr + shall_factr + shall_factr) * pos_tangent)).round(), (til + fwddir + neg_tangent * (fact + 1) + ((mid_factr + shall_factr + shall_factr) * neg_tangent)).round()]:
					if check_tile_in_map(newt) and !(rivertiles.has(newt)) and !(deeprivtiles.has(newt)) and !(medrivtiles.has(newt)) and !(shallrivtiles.has(newt)):
						# smooth out edge of deeprivtiles by only accepting tiles with neighbors of same type
						greentiles.append(newt)
						#Map.set_cellv(Vector2(til.x, til.y - y), Map.get_cellv(Vector2(til.x, til.y - y)) - 1)
						Map.call_deferred('set_cellv', newt, 3)
					if progress:
						WLS.call_deferred('increment_riverwiden_bar')
				if debug:
					print('New shall river tiles: ' + str(deeprivtiles))
			ct += 1
					
	# rebuild rivertiles to include all water tiles
	for til in deeprivtiles:
		if !(til in rivertiles):
			rivertiles.append(til)
	for til in medrivtiles:
		if !(til in rivertiles):
			rivertiles.append(til)
	for til in shallrivtiles:
		if !(til in rivertiles):
			rivertiles.append(til)

	print('expand: ' + str(len(deeprivtiles)) + ' new deep river tiles')
	print('expand: ' + str(len(medrivtiles)) + ' new medium river tiles')
	print('expand: ' + str(len(shallrivtiles)) + ' new shallow river tiles')
	if benchmark:
		print('Time spent on deep river tile generation: ' + str(deeptile_generation_benchmark) + 'ms')
		print('Time spent on deep river tile validation: ' + str(deeptile_validation_benchmark) + 'ms')
		print('Time spent on medium river tile generation: ' + str(medtile_generation_benchmark) + 'ms')
		print('Time spent on medium river tile validation: ' + str(medtile_validation_benchmark) + 'ms')
		print('Time spent on shallow river tile generation: ' + str(shalltile_generation_benchmark) + 'ms')
		print('Time spent on shallow river tile validation: ' + str(shalltile_validation_benchmark) + 'ms')
		print('Time spent on shallow river tile setting: ' + str(shalltile_settile_benchmark) + 'ms')
	
	if progress:
		WLS.call_deferred('hack_fill_riverwiden_bar')
		
func expand_river_v4(opts):
	var mag_inc = opts[0]
	var midexpand = opts[1]
	var shallexpand = opts[2]

	var factr = mag_inc
	var mid_factr = mag_inc
	var shall_factr = mag_inc
	
	var deeptile_generation_benchmark = 0
	var deeptile_validation_benchmark = 0
	var medtile_generation_benchmark = 0
	var medtile_validation_benchmark = 0
	var shalltile_generation_benchmark = 0
	var shalltile_validation_benchmark = 0
	var shalltile_settile_benchmark = 0
	#var starttime = 0
	#var endtime = 0
	if benchmark:
		print('running expand_river_v3 with benchmarking enabled...')
	
	if progress:
		WLS.call_deferred('setup_riverwiden_bar', 'Expand River', 0, len(rivertiles) * 4 * 4 * factr)
	
	
	for til in rivertiles:
		for f in factr:
			for g in factr:
				for newt in [til + Vector2(g, f), til + Vector2(-g, f), til - Vector2(g, f),  til - Vector2(-g, f)]:
					if check_tile_in_map(newt):
						# smooth out edge of deeprivtiles by only accepting tiles with neighbors of same type
						deeprivtiles.append(newt)
						#rivertiles.append(newt)
						Map.call_deferred('set_cellv', newt, 0)
					if progress:
						WLS.call_deferred('increment_riverwiden_bar')
	if midexpand:
		for til in rivertiles:
			for f in range(factr, factr + mid_factr):
				for g in range(factr, factr+ mid_factr):
					for newt in [til + Vector2(g, f), til + Vector2(-g, f), til - Vector2(g, f),  til - Vector2(-g, f)]:
						if check_tile_in_map(newt) and !(deeprivtiles.has(newt)):
							# smooth out edge of deeprivtiles by only accepting tiles with neighbors of same type
							medrivtiles.append(newt)
							#rivertiles.append(newt)
							Map.call_deferred('set_cellv', newt, 1)
						if progress:
							WLS.call_deferred('increment_riverwiden_bar')
	if midexpand and shallexpand:
		for til in rivertiles:
			for f in range(factr + mid_factr, factr + mid_factr + shall_factr):
				for g in range(factr + mid_factr, factr + mid_factr + shall_factr):
					for newt in [til + Vector2(g, f), til + Vector2(-g, f), til - Vector2(g, f),  til - Vector2(-g, f)]:
						if check_tile_in_map(newt) and !(deeprivtiles.has(newt)) and !(medrivtiles.has(newt)):
							# smooth out edge of deeprivtiles by only accepting tiles with neighbors of same type
							shallrivtiles.append(newt)
							#rivertiles.append(newt)
							Map.call_deferred('set_cellv', newt, 2)
						if progress:
							WLS.call_deferred('increment_riverwiden_bar')
	
	# rebuild rivertiles to include all water tiles
	for til in deeprivtiles:
		if !(til in rivertiles):
			rivertiles.append(til)
	for til in medrivtiles:
		if !(til in rivertiles):
			rivertiles.append(til)
	for til in shallrivtiles:
		if !(til in rivertiles):
			rivertiles.append(til)

	print('expand: ' + str(len(deeprivtiles)) + ' new deep river tiles')
	print('expand: ' + str(len(medrivtiles)) + ' new medium river tiles')
	print('expand: ' + str(len(shallrivtiles)) + ' new shallow river tiles')
	if benchmark:
		print('Time spent on deep river tile generation: ' + str(deeptile_generation_benchmark) + 'ms')
		print('Time spent on deep river tile validation: ' + str(deeptile_validation_benchmark) + 'ms')
		print('Time spent on medium river tile generation: ' + str(medtile_generation_benchmark) + 'ms')
		print('Time spent on medium river tile validation: ' + str(medtile_validation_benchmark) + 'ms')
		print('Time spent on shallow river tile generation: ' + str(shalltile_generation_benchmark) + 'ms')
		print('Time spent on shallow river tile validation: ' + str(shalltile_validation_benchmark) + 'ms')
		print('Time spent on shallow river tile setting: ' + str(shalltile_settile_benchmark) + 'ms')


func construct_final_terrain(placeholder):
	if !placeholder == null:
		print('arguments not supported')
	
	if progress:
		WLS.call_deferred('setup_finalterrain_bar', 'Finalize Terrain', 0, width * height)
		
	var tileval
	#var overridedtiles = []
	for x in range(width):
		for y in range(height):
			# if it is next to a river, override with green
			#if self.is_neighboring_a_river(Vector2(x,y)):
			#	for til in [Vector2(x, y), Vector2(x + 1, y), Vector2(x - 1, y),
			#				Vector2(x, y - 1), Vector2(x + 1, y - 1), Vector2(x - 1, y - 1),
			#				Vector2(x, y + 1), Vector2(x + 1, y + 1), Vector2(x - 1, y + 1)]:
			#		overridedtiles.append(Vector2(x,y))
			#		if !rivertiles.has(Vector2(x, y)):
			#			Map.call_deferred('set_cellv', Vector2(x, y), 4)
			# if it isn't a river or a overridden green tile, set with the initial terrain value
			if !rivertiles.has(Vector2(x, y)) and !greentiles.has(Vector2(x, y)):
				tileval = starttils[x][y]
				Map.call_deferred('set_cellv', Vector2(x, y), tileval)
			if progress:
				WLS.call_deferred('increment_finalterrain_bar')
	
	if progress:
		WLS.call_deferred('hack_fill_finalterrain_bar')

func build_world_texture(placeholder):
	if placeholder != null or riverwidth == null:
		print('attempting to use unexpected argument in create_new_world')
	Map.clear()
	
	var thread_fp = Thread.new()
	thread_fp.start(self, "first_pass_terrain", null)
	thread_fp.wait_to_finish()
	
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
		
		# method 1 - solid river path, track with perpendicular vectors to fill in
		var thread_wander = Thread.new()
		thread_wander.start(self, "river_wander", [start_pt, end_pt, false])
		thread_wander.wait_to_finish()
		
		var thread_ex = Thread.new()
		thread_ex.start(self, "expand_river_v3", [riverwidth, true, true])
		thread_ex.wait_to_finish()
		
		# method 2 - appears to be better in general, using the river v2 and simplified path
		#var thread_wander = Thread.new()
		#thread_wander.start(self, "river_wander", [start_pt, end_pt, true])
		#thread_wander.wait_to_finish()
		#
		#var thread_ex = Thread.new()
		#thread_ex.start(self, "expand_river_v4", [riverwidth, true, true])
		#thread_ex.wait_to_finish()
		
		var thread_final = Thread.new()
		thread_final.start(self, "construct_final_terrain", null)
		thread_final.wait_to_finish()
		
		# get the three biggest concentrations of deepwater
		var temphgt = []
		var deepest_tls = []
		var deepest_tls_sorted = []
		#var deepest_tls_location = []
		
	    # get the deepest three spots first
		for tls in deeptiles:
			temphgt = hgtmap[0][tls.x][tls.y]
			deepest_tls.append(temphgt)
			
		deepest_tls_sorted = deepest_tls.duplicate()
		deepest_tls_sorted.sort()
		
		return
		#for spts in deepspots:
		# check if deeptile is deeper than previously logged deepspots and also separated from them
		#	if (temphgt < hgtmap[0][spts.x][spts.y]) and tls.distance_to(spts) > 5:

func check_neighbors(cell, unvisited):
	var list = []
	for n in cell_walls.keys():
		if cell + n in unvisited:
			list.append(cell + n)
	return list
	
func make_maze():
	var unvisited = []
	var stack = []
	
	Map.call_deferred('clear')
	for x in range(width):
		for y in range(height):
			unvisited.append(Vector2(x, y))
			Map.call_deferred('set_cellv', Vector2(x, y), N|E|S|W)
	var current = Vector2(0, 0)
	unvisited.erase(current)
	
	# execute recursive backtracker algorithm
	while unvisited:
		var neighbors = check_neighbors(current, unvisited)
		if neighbors.size() > 0:
			var next = neighbors[randi() % neighbors.size()]
			stack.append(current)
			var dir = next-current    # direction vector for direction moved in
			var current_walls = Map.call_deferred('get_cellv', current) - cell_walls[dir]      # remove the wall for the direction moved into new cell
			var next_walls = Map.call_deferred('get_cellv', next) - cell_walls[-dir]         # remove the wall for the direction moved from old cell
			Map.call_deferred('set_cellv', current, current_walls)
			Map.call_deferred('set_cellv', next, next_walls)
			current = next
			unvisited.erase(current)
		elif stack:
			current = stack.pop_back()   # backtrack if there are no neighbors, use the cell behind
		yield(get_tree(), 'idle_frame')
