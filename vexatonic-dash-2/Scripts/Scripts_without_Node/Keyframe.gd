class_name Keyframe

# (time(ms 단위), height(y좌표)로 레인이 꺾이는 지점을 표시)
var kf: Vector2

# 이 keyframe이 속한 레인, 아직 레인에 할당되지 않았다면 -1 반환
var lane_index: int

func _init(time: float, height: float):
	kf = Vector2(time, height)
	lane_index = -1

func set_lane(index: int):
	lane_index = index
