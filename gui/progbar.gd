extends Control

onready var lbl = $margin/proggrid/lbl
onready var bar = $margin/proggrid/bar
onready var margin = $margin


#func _ready():
#	setup_bar('testthisout yes hahahaha', 0, 100)
#	for i in range(100):
#		update_bar(i)

func setup_bar(txt, minr, maxr, maxsizeofbar=0):
	# new size of label is based on new text and font size
	var fnt = lbl.get_font("normal_font")
	var strsize = fnt.get_string_size(txt)
	
	lbl.text = '   ' + txt
	lbl.rect_size = strsize
	bar.max_value = maxr
	bar.min_value = minr
	
	# override if you want a size other than 300 length prgbar
	if !(maxsizeofbar == 0):
		margin.margin_right = maxsizeofbar
	else:
		margin.margin_right = strsize.x + 400


func update_bar(prog):
	bar.value = prog
	

func increment_bar():
	if bar.value != bar.max_value:
		bar.value += 1
		

func hack_fill_bar():
	bar.value = bar.max_value