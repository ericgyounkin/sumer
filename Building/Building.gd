extends Node2D

var playerhiddencount = 0
var destroyed = false 
var Health = 100
var enemy_contact = false


# need a signal from enemy showing contact... (add something for collision although collision wouldn't always mean attack) 


 

func handle_bodyent(body):
	if body.is_in_group('players'):
		playerhiddencount += 1
		if playerhiddencount == 1:       # first body in triggers building to hide
			$Tween.interpolate_property($Sprite, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0.5), 0.1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
			$Tween.start()
			#$Sprite.modulate = Color(1, 1, 1, 0.5)

		$Tween2.interpolate_property(body, "modulate", Color(1, 1, 1, 1), Color(0.01, 0.01, 0.01, 0.2), 0.1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		$Tween2.start()
		#body.modulate = Color(0.01, 0.01, 0.01, 0.2)
		if body.has_node('npc_gui'):
			$Tween3.interpolate_property(body.get_node('npc_gui'), "modulate", Color(1, 1, 1, 1), Color(100, 100, 100, 5), 0.1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
			$Tween3.start()
			#body.get_node('npc_gui').modulate = Color(100, 100, 100, 5)
	elif body.is_in_group('bullet'):
		body.z_index = 0
		
func handle_bodyexit(body):
	if body.is_in_group('players'):
		if !body.dead and !body.incapacitated:
			playerhiddencount -= 1
			if playerhiddencount == 0:
				$Tween.interpolate_property($Sprite, "modulate", Color(1, 1, 1, 0.5), Color(1, 1, 1, 1), 0.1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
				$Tween.start()
				#$Sprite.modulate = Color(1, 1, 1, 1)
			$Tween2.interpolate_property(body, "modulate", Color(0.01, 0.01, 0.01, 0.2), Color(1, 1, 1, 1), 0.1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
			$Tween2.start()
			#body.modulate = Color(1, 1, 1, 1)
			if body.has_node('npc_gui'):
				$Tween3.interpolate_property(body.get_node('npc_gui'), "modulate", Color(100, 100, 100, 5), Color(1, 1, 1, 1), 0.1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
				$Tween3.start()
				#body.get_node('npc_gui').modulate = Color(1, 1, 1, 1)
	elif body.is_in_group('bullet'):
		body.z_index = 1
		
func handle_areaent(area):
	area.z_index = 0
		
func handle_areaexit(area):
	area.z_index = 1	

		