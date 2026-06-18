class_name Trigger

enum TYPE { Move = 31, Zoom  = 32, Rotate = 33}

var type: TYPE
var start: float
var c: float
var t: float

func _init(p_type: TYPE, p_start: float, p_c: float, p_t: float) -> void:
	type = p_type
	start = p_start
	c = p_c
	t = p_t
