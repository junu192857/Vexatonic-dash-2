extends Node2D

@onready var polygon:Polygon2D = $Polygon2D

var data:ConnectorData
var lane

const UNPROCECSSED_COLORS: Array[Color] = [Color(1, 0.4, 0.4), Color(0.4, 0.4, 1.0),Color(1.0, 1.0, 0.4)]
const PROCESSED_COLORS: Array[Color] = [Color(0.8,0,0),Color(0.0, 0.0, 0.7),Color(0.8, 0.7, 0.0)]


func set_connector_data(p_color:int, start_time, end_time, p_lane: Lane = null):
	lane = p_lane
	var calculated_delta_y: float = 0.0
	var connector_ended: bool = true
	
	if p_lane != null:
		var start_height = p_lane.get_height(start_time)
		for kf in p_lane.keyframes:
			if kf.x > start_time:
				calculated_delta_y = kf.y - start_height
				connector_ended = false
				break
				
	data = ConnectorData.new(p_color, Setting.get_posx_from_time(end_time - start_time), calculated_delta_y)

func _ready():
	polygon.polygon = PackedVector2Array([
		Vector2(0,-25-data.delta_y), #좌상
		Vector2(data.length,-25-data.delta_y), #우상
		Vector2(data.length,25-data.delta_y), #우하
		Vector2(0,25-data.delta_y) #좌하
	])
	polygon.uv = PackedVector2Array([
		Vector2(0,0),
		Vector2(240,0),
		Vector2(240,500),
		Vector2(0,500)
	])
	if (data.color == -1):
		polygon.modulate = Color(1,1,1)
	else:
		polygon.modulate = UNPROCECSSED_COLORS[data.color]
