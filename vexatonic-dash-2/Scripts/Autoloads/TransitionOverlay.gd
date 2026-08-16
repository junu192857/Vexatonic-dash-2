extends CanvasLayer

const OPEN_LEFT = Vector2(-0.5, 0.0)
const OPEN_RIGHT = Vector2(1.0, 1.5)
const CLOSED_LEFT = Vector2(0.0, 0.5)
const CLOSED_RIGHT = Vector2(0.5, 1.0)

var left_panel: ColorRect
var right_panel: ColorRect

signal closed
signal opened

# 씬 전환 중에도 파괴되지 않도록 코드로 자식 생성 (특정 씬에 속하지 않음)
func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS

	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(control)
	

	left_panel = ColorRect.new()
	left_panel.anchor_bottom = 1.0
	left_panel.anchor_left = OPEN_LEFT.x
	left_panel.anchor_right = OPEN_LEFT.y
	control.add_child(left_panel)

	right_panel = ColorRect.new()
	right_panel.anchor_bottom = 1.0
	right_panel.anchor_left = OPEN_RIGHT.x
	right_panel.anchor_right = OPEN_RIGHT.y
	control.add_child(right_panel)

# 화면 중앙으로 모여 화면을 가림
func close(duration: float = 0.4) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(left_panel, "anchor_left", CLOSED_LEFT.x, duration)
	tween.tween_property(left_panel, "anchor_right", CLOSED_LEFT.y, duration)
	tween.tween_property(right_panel, "anchor_left", CLOSED_RIGHT.x, duration)
	tween.tween_property(right_panel, "anchor_right", CLOSED_RIGHT.y, duration)
	await tween.finished
	closed.emit()

# 좌우 화면 밖으로 이동해 화면을 보여줌
func open(duration: float = 0.4) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(left_panel, "anchor_left", OPEN_LEFT.x, duration)
	tween.tween_property(left_panel, "anchor_right", OPEN_LEFT.y, duration)
	tween.tween_property(right_panel, "anchor_left", OPEN_RIGHT.x, duration)
	tween.tween_property(right_panel, "anchor_right", OPEN_RIGHT.y, duration)
	await tween.finished
	opened.emit()
