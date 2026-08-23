class_name TriggerStatus
# 에디터 재생 중 특정 시점의 카메라/속도 트리거 반영 상태 (IngameStatusHolder 표시용)

var camera_y: float
var camera_zoom: float
var camera_x: float
var camera_rotation: float
var speed: float

func _init(p_camera_y: float = 0.0, p_camera_zoom: float = 1.0, p_camera_x: float = 0.0, p_camera_rotation: float = 0.0, p_speed: float = 1.0) -> void:
	camera_y = p_camera_y
	camera_zoom = p_camera_zoom
	camera_x = p_camera_x
	camera_rotation = p_camera_rotation
	speed = p_speed
