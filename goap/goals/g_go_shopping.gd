extends "res://goap/goap_goal.gd"

var ready_to_shop = false
var targetshop = null

func setup():
	
	# Called after setup_common()
	
	name = "g_go_shopping" # String to identify the goal from others after creation
	priority = 3.0 # The higher this number, the more important the goal. Agent will always want to fulfill the goal with the highest priority first
	type = TYPE_NORMAL # Defines goal type. Definitions of enums are found in ancestor script
	
	if $shoppingcountdown_timer.is_stopped():
		$shoppingcountdown_timer.wait_time = rand_range(0,120)
		$shoppingcountdown_timer.start()
	
	# Define symbols by adding them to goals list with add_symbol(string symbol, bool value)
	add_symbol('s_shopped', true)
	
	return



func evaluate():
	
	# Go through all symbols and check if they are in the state this goal desires
	# If one symbol is not fulfilled, this goal may be used in planning
	# Returns a dictionary of all of goal's symbols in worldstate if any is not satisfied, otherwise null
	
	# if the gui conversation box is visible, you are having a conversation and you need to activate this goal
	if ready_to_shop:
		targetshop = null
		
		for shps in get_tree().get_nodes_in_group('shops'):
			if entity.global_position.distance_to(shps.global_position) < 400:
				targetshop = shps
				break
		
		if targetshop:
			ready_to_shop = false
			$shoppingcountdown_timer.stop()
			$shoppingcountdown_timer.wait_time = rand_range(60,120)
			$shoppingcountdown_timer.start()
			return {'s_shopped': false}
	
	return null

func on_completion():
	
	# Fires when all symbols of this goal have the desired state after completion of an action by a GOAP agent, signified by the completion of the last action in the plan
	# 'times_completed' increases by one each time before this event is called
	# Signal 'goal_completed' is emitted after this, unless 'emit_signal' is set to false
	# ONESHOT goals will delete themselves after this
	# DIMINISHING type goals will reduce their priority automatically to (priority_default ( == priority in setup()) / times_completed + 1)
	
	return


func _on_shoppingcountdown_timer_timeout():
	ready_to_shop = true
