extends "res://goap/goap_goal.gd"

var currentnpc = null
var angletonpc = 0

func setup():
	
	# Called after setup_common()
	
	name = "g_handle_npcs_closeby_civilian" # String to identify the goal from others after creation
	priority = 7.0 # The higher this number, the more important the goal. Agent will always want to fulfill the goal with the highest priority first
	type = TYPE_NORMAL # Defines goal type. Definitions of enums are found in ancestor script
	
	# Define symbols by adding them to goals list with add_symbol(string symbol, bool value)
	add_symbol('s_remark_npc', true)
	return


func evaluate():
	
	# Go through all symbols and check if they are in the state this goal desires
	# If one symbol is not fulfilled, this goal may be used in planning
	# Returns a dictionary of all of goal's symbols in worldstate if any is not satisfied, otherwise null
	
	# move the gang if no other reason presents itself
	var rslts = entity.get_nearest_npc_player_and_angle()
	currentnpc = rslts[0]
	angletonpc = rslts[1]
	if currentnpc != null:
		return {'s_remark_npc': false}


func on_completion():
	
	# Fires when all symbols of this goal have the desired state after completion of an action by a GOAP agent, signified by the completion of the last action in the plan
	# 'times_completed' increases by one each time before this event is called
	# Signal 'goal_completed' is emitted after this, unless 'emit_signal' is set to false
	# ONESHOT goals will delete themselves after this
	# DIMINISHING type goals will reduce their priority automatically to (priority_default ( == priority in setup()) / times_completed + 1)
	
	return
