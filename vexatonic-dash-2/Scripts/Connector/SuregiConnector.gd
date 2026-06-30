extends Connector
class_name SuregiConnector

@onready var line:Line2D = $Line2D

func set_connector_data(p_color:int, start_time, end_time, p_lane: Lane, first: bool) -> float:
	lane = p_lane
	var start_height
	if p_lane != null:
		start_height = p_lane.get_height(start_time - Setting.time_per_note_width) if first else \
					   p_lane.get_height(start_time)
	
	line.points.append(Vector2.ZERO)
# 다음 keyframe이 나오기 전까지만 찍도록 end_time 조정
	for kf in p_lane.keyframes:
		if (kf.kf.x > start_time):
			if kf.kf.x >= end_time:
				line.points.append(Vector2(Setting.get_posx_from_time(end_time - start_time), p_lane.get_height(end_time) - start_height))
			else:
				line.points.append(Vector2(Setting.get_posx_from_time(kf.kf.x - start_time), kf.kf.y - start_height))
			
	
	line.modulate = Color(1,1,1)
	data = ConnectorData.new(p_color, Setting.get_posx_from_time(end_time - start_time), p_lane.get_height(end_time) - start_height)
	return end_time
	
func _ready():
	pass
