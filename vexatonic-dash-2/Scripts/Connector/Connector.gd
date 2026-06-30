extends Node2D
class_name Connector

var polygon:Polygon2D

var data:ConnectorData
var lane
var c_start_time: float
var c_end_time: float
var processed_polygon: Polygon2D

const UNPROCESSED_COLORS: Array[Color] = [Color(1, 0.4, 0.4), Color(0.4, 0.4, 1.0),Color(1.0, 1.0, 0.4)]
const PROCESSED_COLORS: Array[Color] = [Color(0.8,0,0),Color(0.0, 0.0, 0.7),Color(0.8, 0.7, 0.0)]


func set_connector_data(p_color:int, start_time, end_time, p_lane: Lane, first: bool) -> float:
	c_start_time = start_time
	lane = p_lane
	var calculated_delta_y: float = 0.0
	var start_height
	if p_lane != null:
		start_height = p_lane.get_height(start_time - Setting.time_per_note_width) if first else \
					   p_lane.get_height(start_time)
					
# 다음 keyframe이 나오기 전까지만 찍도록 end_time 조정
		for kf in p_lane.keyframes:
			if kf.kf.x > start_time:
				if kf.kf.x >= end_time: #이게 마지막 connector인 경우.
					calculated_delta_y = p_lane.get_height(end_time) - start_height
				else: # 앞으로 connector가 더 나오는 경우.
					calculated_delta_y = kf.kf.y - start_height
					end_time = kf.kf.x
				break
	c_end_time = end_time
	data = ConnectorData.new(p_color, Setting.get_posx_from_time(end_time - start_time), calculated_delta_y)
	return end_time

func _ready():
	polygon = $Polygon2D
	
	polygon.polygon = PackedVector2Array([
		Vector2(0,-Setting.HALF_CONNECTOR_HEIGHT), #좌상
		Vector2(data.length,-Setting.HALF_CONNECTOR_HEIGHT+data.delta_y), #우상
		Vector2(data.length,Setting.HALF_CONNECTOR_HEIGHT+data.delta_y), #우하
		Vector2(0,Setting.HALF_CONNECTOR_HEIGHT) #좌하
	])
	polygon.uv = PackedVector2Array([
		Vector2(0,0),
		Vector2(240,0),
		Vector2(240,500),
		Vector2(0,500)
	])
	set_color()
	#if (data.color != -1):
	#	make_new_polygon()
	
func set_color():
	if (data.color == -1):
		polygon.modulate = Color(1,1,1)
	else:
		polygon.modulate = UNPROCESSED_COLORS[data.color]


func make_new_polygon():
	processed_polygon = Polygon2D.new()
	processed_polygon.z_index = 2
	add_child(processed_polygon)
	processed_polygon.visible = false

# from_time~to_time 구간을 PROCESSED_COLORS로 칠함. 자식 Connector에 재귀 적용.
func paint_range(from_time: float, to_time: float) -> void:
	if (data.color == -1):
		return
	if processed_polygon == null:
		return
	
	var local_start_x = clamp(Setting.get_posx_from_time(from_time - c_start_time), 0.0, data.length)
	var local_end_x   = clamp(Setting.get_posx_from_time(to_time   - c_start_time), 0.0, data.length)
	if local_end_x <= local_start_x or data.length <= Setting.EPSILON:
		processed_polygon.visible = false
	else:
		var y_start = (local_start_x / data.length) * data.delta_y
		var y_end   = (local_end_x   / data.length) * data.delta_y
		processed_polygon.polygon = PackedVector2Array([
			Vector2(local_start_x, y_start - Setting.HALF_CONNECTOR_HEIGHT),
			Vector2(local_end_x,   y_end   - Setting.HALF_CONNECTOR_HEIGHT),
			Vector2(local_end_x,   y_end   + Setting.HALF_CONNECTOR_HEIGHT),
			Vector2(local_start_x, y_start + Setting.HALF_CONNECTOR_HEIGHT),
		])
		processed_polygon.color = PROCESSED_COLORS[data.color]
		processed_polygon.visible = true

	#for child in get_children():
	#	if child is Connector:
	#		child.paint_range(from_time, to_time)
