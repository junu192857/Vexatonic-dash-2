extends Node2D
class_name CameraRangeRect

var _rect: Rect2 = Rect2()
var color: Color = Color(1.0, 1.0, 0.0, 0.8)
var line_scale: float = 1.0

func set_bounds(rect: Rect2) -> void:
	_rect = rect
	queue_redraw()

func set_line_scale(s: float) -> void:
	line_scale = s
	queue_redraw()


func _draw() -> void:
	var r = _rect
	var s = line_scale
	# 가로변 (두께 = y방향 s)
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, s), color, true)
	draw_rect(Rect2(r.position.x, r.position.y + r.size.y - s, r.size.x, s), color, true)
	# 세로변 (두께 = x방향 s)
	draw_rect(Rect2(r.position.x, r.position.y, s, r.size.y), color, true)
	draw_rect(Rect2(r.position.x + r.size.x - s, r.position.y, s, r.size.y), color, true)
