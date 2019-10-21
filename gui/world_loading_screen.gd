extends Control


onready var hmbar = $bars/heightmapbar
onready var lkbar = $bars/lookuptablebar
onready var fpbar = $bars/firstpassterrainbar
onready var rgbar = $bars/rivergenbar
onready var rwbar = $bars/riverwidenbar
onready var ftbar = $bars/finalterrainbar

func _ready():
	hmbar.setup_bar('Generate Heightmap', 0, 1)
	lkbar.setup_bar('Generate Lookup Table', 0, 1)
	fpbar.setup_bar('Initial Terrain Generation', 0, 1)
	rgbar.setup_bar('Find River Path', 0, 1)
	rwbar.setup_bar('Expand River', 0, 1)
	ftbar.setup_bar('Finalize Terrain', 0, 1)

func update_bars():
	hmbar.update()
	lkbar.update()
	fpbar.update()
	rgbar.update()
	rwbar.update()
	ftbar.update()
	
	
func setup_heightmap_bar(txt, minr, maxr, maxsizeofbar=0):
	hmbar.setup_bar(txt, minr, maxr, maxsizeofbar)
	
func increment_heightmap_bar():
	hmbar.increment_bar()
	
func hack_fill_heightmap_bar():
	hmbar.hack_fill_bar()
	
	
func setup_lookup_bar(txt, minr, maxr, maxsizeofbar=0):
	lkbar.setup_bar(txt, minr, maxr, maxsizeofbar)
	
func increment_lookup_bar():
	lkbar.increment_bar()
	
func hack_fill_lookup_bar():
	lkbar.hack_fill_bar()
	
	
func setup_firstpass_bar(txt, minr, maxr, maxsizeofbar=0):
	fpbar.setup_bar(txt, minr, maxr, maxsizeofbar)
	
func increment_firstpass_bar():
	fpbar.increment_bar()
	
func hack_fill_firstpass_bar():
	fpbar.hack_fill_bar()
	
	
func setup_rivergen_bar(txt, minr, maxr, maxsizeofbar=0):
	rgbar.setup_bar(txt, minr, maxr, maxsizeofbar)
	
func increment_rivergen_bar():
	rgbar.increment_bar()
	
func hack_fill_rivergen_bar():
	rgbar.hack_fill_bar()
	
	
func setup_riverwiden_bar(txt, minr, maxr, maxsizeofbar=0):
	rwbar.setup_bar(txt, minr, maxr, maxsizeofbar)
	
func increment_riverwiden_bar():
	rwbar.increment_bar()
	
func hack_fill_riverwiden_bar():
	rwbar.hack_fill_bar()
	

func setup_finalterrain_bar(txt, minr, maxr, maxsizeofbar=0):
	ftbar.setup_bar(txt, minr, maxr, maxsizeofbar)
	
func increment_finalterrain_bar():
	ftbar.increment_bar()
	
func hack_fill_finalterrain_bar():
	ftbar.hack_fill_bar()