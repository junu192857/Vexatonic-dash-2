extends Connector
class_name EConnector

#@onready var polygon:Polygon2D = $Polygon2D

#var data:ConnectorData
var lane_index: int
var start_keyframe: Vector2
var end_keyframe: Vector2
#const PROCESSED_COLORS: Array[Color] = [Color(0.8,0,0),Color(0.0, 0.0, 0.7),Color(0.8, 0.7, 0.0)]

func _ready():
	data = ConnectorData.new(-1, 24, 0)
	polygon.uv = PackedVector2Array([
		Vector2(0,0),
		Vector2(240,0),
		Vector2(240,500),
		Vector2(0,500)
	])
	polygon.modulate = Color(1,1,1)
	set_polygon_dynamically()

func set_polygon_dynamically():
	polygon.polygon = PackedVector2Array([
		Vector2(0,-Setting.HALF_CONNECTOR_HEIGHT), #좌상
		Vector2(data.length,-Setting.HALF_CONNECTOR_HEIGHT+data.delta_y), #우상
		Vector2(data.length,Setting.HALF_CONNECTOR_HEIGHT+data.delta_y), #우하
		Vector2(0,Setting.HALF_CONNECTOR_HEIGHT) #좌하
	])

func set_data_from_keyframes():
	var start_pos = Vector2(Setting.get_posx_from_time(start_keyframe.x), start_keyframe.y)
	var end_pos = Vector2(Setting.get_posx_from_time(end_keyframe.x), end_keyframe.y)
	global_position = start_pos
	data.set_length(end_pos.x - start_pos.x)
	data.set_delta_y(end_pos.y - start_pos.y)
	set_polygon_dynamically()
	
func set_data(start_pos: Vector2, end_pos: Vector2):
	data.set_length(end_pos.x - start_pos.x)
	data.set_delta_y(end_pos.y - start_pos.y)
	set_polygon_dynamically()

func get_end_pos(start_pos:Vector2):
	return start_pos + Vector2(data.length, data.delta_y)

func set_editor_values(index:int, s_keyframe: Vector2, e_keyframe: Vector2):
	lane_index = index
	start_keyframe = s_keyframe
	end_keyframe = e_keyframe
	
func set_editor_color(color: int):
	polygon.modulate = Color(1,1,1) if color == -1 else PROCESSED_COLORS[color]
