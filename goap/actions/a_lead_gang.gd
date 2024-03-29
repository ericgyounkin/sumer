extends "res://goap/goap_action.gd"

# Copied and modified by specific actions
#var pause = 5

func return_gangleader_move():
	var move_offset = Vector2()
	move_offset.x = rand_range(600, 1000)
	var offsetx_multi = bool(randi() % 2)
	if offsetx_multi:
		move_offset.x = -move_offset.x
	move_offset.y = rand_range(600, 1000)
	var offsety_multi = bool(randi() % 2)
	if offsety_multi:
		move_offset.y = -move_offset.y
	return move_offset

func setup():
	
	# called after setup_common()
	
	cost = 1.0              # higher cost actions are considered less preferable over lower cost actions when planning
	name = 'a_lead_gang'               # String identifier of this action.  setup_common() will make sure the action's node is named after this
	type = TYPE_NORMAL      # See ancestor script for type descriptions

	# Movement - use add_movement(string id)
	add_movement('move_normal')
	
	# Preconditions - use add_precondition(string symbol, bool value)
	
	# Effects - use add_effect(string symbol, bool value)
	add_effect('s_leadgang', true)
	return

func reset():
	
	# Called when planner wants to consider this action
	# Sets action's state to the state it should be before running execute() for the first time

	return
	
func evaluate():
	
	# Planner calls this before resetting the action
	# If returning true, the planner will consider this action for its current plan
	# If returning false, the planner will not include this action in the plan for the currently inspected goal at all!
	return true
	
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
		var wander_offset = return_gangleader_move()
		entity.mousepos = entity.global_position + wander_offset
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
