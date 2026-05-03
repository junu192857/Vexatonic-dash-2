extends Node2D

@onready var polygon:Polygon2D = $Polygon2D

var data:ConnectorData
var lane

const UNPROCECSSED_COLORS: Array[Color] = [Color(1, 0.4, 0.4), Color(0.4, 0.4, 1.0),Color(1.0, 1.0, 0.4)]
const PROCESSED_COLORS: Array[Color] = [Color(0.8,0,0),Color(0.0, 0.0, 0.7),Color(0.8, 0.7, 0.0)]


#func set_connector_data(p_color:int, start_time, end_time, p_lane: Lane, first: bool) -> float:
	#print("Calling set_connector_data with %d, %f, %f" % [p_color, start_time, end_time])
	#lane = p_lane
	#var calculated_delta_y: float = 0.0
	#var start_height
	#if p_lane != null:
		#start_height = p_lane.get_height(start_time - Setting.time_per_note_width) if first else \
					   #p_lane.get_height(start_time)
					#
## 단노트 또는 marker에서 캐릭터가 수평으로 이동하도록 keyframe 조절
		#if (first):
			#p_lane.insert_keyframe(start_time - Setting.time_per_note_width, start_height)
			#p_lane.insert_keyframe(start_time, start_height)
			#var deleted = p_lane.delete_middle_keyframe(start_time - Setting.time_per_note_width, start_time)
			#if (deleted != null):
				#p_lane.insert_keyframe(start_time + 2 * Setting.EPSILON, deleted.y)
				#
## 다음 keyframe이 나오기 전까지만 찍도록 end_time 조정
		#print("Start height: %f" % start_height)
		#for kf in p_lane.keyframes:
			#if kf.x > start_time:
				#if kf.x >= end_time:
					#calculated_delta_y = p_lane.get_height(end_time) - start_height
				#else:
					#calculated_delta_y = kf.y - start_height
					#end_time = kf.x
				#break
				#
	#print("Calculated_delta_y = %f" % calculated_delta_y)
	#data = ConnectorData.new(p_color, Setting.get_posx_from_time(end_time - start_time), calculated_delta_y)
	#return end_time
#
#func _ready():
	#polygon.polygon = PackedVector2Array([
		#Vector2(0,-25), #좌상
		#Vector2(data.length,-25-data.delta_y), #우상
		#Vector2(data.length,25-data.delta_y), #우하
		#Vector2(0,25) #좌하
	#])
	#polygon.uv = PackedVector2Array([
		#Vector2(0,0),
		#Vector2(240,0),
		#Vector2(240,500),
		#Vector2(0,500)
	#])
	#if (data.color == -1):
		#polygon.modulate = Color(1,1,1)
	#else:
		#polygon.modulate = UNPROCECSSED_COLORS[data.color]

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
		Vector2(0,-25), #좌상
		Vector2(data.length,-25-data.delta_y), #우상
		Vector2(data.length,25-data.delta_y), #우하
		Vector2(0,25) #좌하
	])
	
