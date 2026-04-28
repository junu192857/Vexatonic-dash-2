extends Node2D
class_name Character

var lane:Lane

func set_character_position(time:float) -> bool:
	if (time > lane.get_end_time()):
		queue_free()
		return true
	else:
		position = Vector2(Setting.get_posx_from_time(time), -(lane.get_height(time)+Setting.CHARACTER_POS_Y))
		return false
	
	
func set_lane(p_lane: Lane):
	lane = p_lane
