extends Node2D
class_name Character

var lane:Lane
var jumping:bool = false
var jumping_note: Note

func set_character_position(time:float) -> bool:
	if (0 < time and time < lane.get_start_time()):
		queue_free()
		return true
	
	if (time > lane.get_end_time()):
		queue_free()
		return true
	else:
		if (jumping):
			pass
		else:
			global_position.y = lane.get_height(time) + Setting.CHARACTER_POS_Y
		return false
	
	
func set_lane(p_lane: Lane):
	lane = p_lane
