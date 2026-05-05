extends Node2D

@onready var polygon:Polygon2D = $Polygon2D

var data:ConnectorData
var lane

const UNPROCECSSED_COLORS: Array[Color] = [Color(1, 0.4, 0.4), Color(0.4, 0.4, 1.0),Color(1.0, 1.0, 0.4)]
const PROCESSED_COLORS: Array[Color] = [Color(0.8,0,0),Color(0.0, 0.0, 0.7),Color(0.8, 0.7, 0.0)]

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
		Vector2(data.length,-Setting.HALF_CONNECTOR_HEIGHT-data.delta_y), #우상
		Vector2(data.length,Setting.HALF_CONNECTOR_HEIGHT-data.delta_y), #우하
		Vector2(0,Setting.HALF_CONNECTOR_HEIGHT) #좌하
	])
