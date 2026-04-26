extends Node2D
class_name Sayane

var lane:Lane

func set_character_position(time:float):
	position = Vector2(Setting.get_posx_from_time(time), -(lane.get_height(time)+Setting.CHARACTER_POS_Y))
	
func set_lane(p_lane: Lane):
	lane = p_lane
