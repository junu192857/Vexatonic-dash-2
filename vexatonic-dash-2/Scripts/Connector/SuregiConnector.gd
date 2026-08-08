extends Connector
class_name SuregiConnector

var line:Line2D

func set_connector_data(p_color:int, start_time, end_time, p_lane: Lane, first: bool) -> float:
	line = $Line2D
	lane = p_lane
	var start_height
	if p_lane != null:
		start_height = Setting.mirror_y(p_lane.get_height(PositionCalculator.get_time_from_posx(PositionCalculator.get_posx_from_time(start_time) - Setting.NOTE_WIDTH))) if first else \
					   Setting.mirror_y(p_lane.get_height(start_time))

	line.add_point(Vector2.ZERO)
# 다음 keyframe이 나오기 전까지만 찍도록 end_time 조정
	for kf in p_lane.keyframes:
		if (kf.kf.x > start_time):
			if kf.kf.x >= end_time:
				line.add_point(Vector2(PositionCalculator.get_posx_from_time(end_time) - PositionCalculator.get_posx_from_time(start_time), Setting.mirror_y(p_lane.get_height(end_time)) - start_height))
				break
			else:
				line.add_point(Vector2(PositionCalculator.get_posx_from_time(kf.kf.x) - PositionCalculator.get_posx_from_time(start_time), Setting.mirror_y(kf.kf.y) - start_height))


	data = ConnectorData.new(p_color, PositionCalculator.get_posx_from_time(end_time) - PositionCalculator.get_posx_from_time(start_time), Setting.mirror_y(p_lane.get_height(end_time)) - start_height)
	set_color()
	return end_time

func set_color():
	if (data.color == -1):
		line.modulate = Color(1,1,1)
	else:
		line.modulate = Setting.UNPROCESSED_COLORS[data.color]

func _ready():
	pass
