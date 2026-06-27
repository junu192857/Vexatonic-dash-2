class_name Trigger

enum TYPE { Move = 31, Zoom  = 32, Rotate = 33, BPM = 34}

var type: TYPE
var start: float
#c: 얼마나 이동 또는 줌할거냐를 결정
var c: float
#t: 이동 또는 줌에 걸리는 시간 결정
var t: float

func _init(p_type: TYPE, p_start: float, p_c: float, p_t: float) -> void:
	type = p_type
	start = p_start
	c = p_c
	t = p_t
