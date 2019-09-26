extends Control


onready var hmbar = $bars/heightmapbar
onready var lkbar = $bars/lookuptablebar
onready var fpbar = $bars/firstpassterrainbar
onready var rgbar = $bars/rivergenbar
onready var rwbar = $bars/riverwidenbar


func updatebars():
	hmbar.update()
	lkbar.update()
	fpbar.update()
	rgbar.update()
	rwbar.update()