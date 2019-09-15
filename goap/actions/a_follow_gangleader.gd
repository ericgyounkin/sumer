extends "res://goap/goap_action.gd"

# Copied and modified by specific actions

var gangleader = null


func find_gangleader():
	if entity:
		for gangmember in get_tree().get_nodes_in_group('gang_member'):
			if gangmember.groupident == entity.groupident:
				if gangmember.gangleader:
					gangleader = gangmember

func return_gangleader_offset():
	var follow_offset = Vector2()
	follow_offset.x = rand_range(50, 100)
	var offsetx_multi = bool(randi() % 2)
	if offsetx_multi:
		follow_offset.x = -follow_offset.x
	follow_offset.y = rand_range(50, 100)
	var offsety_multi = bool(randi() % 2)
	if offsety_multi:
		follow_offset.y = -follow_offset.y
	return follow_offset

func setup():
	
	# called after setup_common()
	
	cost = 1.0              # higher cost actions are considered less preferable over lower cost actions when planning
	name = 'a_follow_gangleader'               # String identifier of this action.  setup_common() will make sure the action's node is named after this
	type = TYPE_NORMAL      # See ancestor script for type descriptions

	
	
	# Movement - use add_movement(string id)
	add_movement('move_normal')
	
	# Preconditions - use add_precondition(string symbol, bool value)
	
	# Effects - use add_effect(string symbol, bool value)
	add_effect('s_followleader', true)
	return

func reset():
	
	# Called when planner wants to consider this action
	# Sets action's state to the state it should be before running execute() for the first time
	if entity:
		find_gangleader()
	return
	
func evaluate():
	
	# Planner calls this before resetting the action
	# If returning true, the planner will consider this action for its current plan
	# If returning false, the planner will not include this action in the plan for the currently inspected goal at all!
	
	# If the gangleader is moving, follow him
	if gangleader.moving and gangleader.mousepos:
		return true
	# If the gangleader is stopped in conversation or something and is far away, go to him
	elif entity.global_position.distance_to(gangleader.global_position) > 200:
		return true
	return false
	
func get_cost():
	
	# Called when the planner wants to calculate the next best action
	# Higher cost actions are considered less preferable over lower cost actions when planning
	
	return cost
	
func get_target_location():
	
	# This is called when a TYPE_MOVEMENT action is to be executed by the agent next
	# The agent will call 'get_target_location()' on the action coming after the TYPE_MOVEMENT action in the current plan
	# This function must return a Vector2 as coordinate in the world to move to
	# If returning null, agent will abort plan, since its movement does not have a valid target
	# This function should only need to return a Vector2 if it has a precondition 's_atPoint' or similar,
	#    so TYPE_MOVEMENT actions should only be planned to occur before actions that need the agent to be at a
	#    certain location and therefore are able to return a position to move to

	if entity.is_network_master():
		print('get target location ' + str(entity.name))
		var follow_offset = return_gangleader_offset()
		if entity.global_position.distance_to(gangleader.global_position) > 300:
			entity.running = true
		else:
			entity.running = false
		
		if gangleader.check_having_conversation():
			entity.mousepos = gangleader.global_position + follow_offset
		else:
			entity.mousepos = gangleader.mousepos + follow_offset
		entity.rset('slave_mousepos', entity.mousepos)
		if global.netdebug:
			print('rset slave_mousepos, slave_move_speed')
		
	return null
	
func execute():
	
	# Manipulate the world through this code
	# Gets called in intervals.  The deltatime between these calls is stored as 'lastdelta'
	# Return one of these constants:
	#  - ABORTED - Action's execution code has encountered an unsolvable state, it is aborting its execution
	#  - CONTINUED - Action's execution code has run successfully, but the action is not done yet
	#  - COMPLETED - Action's execution code has run successfully and the action is done executing

	return COMPLETED
