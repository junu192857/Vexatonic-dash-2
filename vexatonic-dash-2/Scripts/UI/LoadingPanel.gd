class_name LoadingPanel
extends CanvasLayer

@onready var left_panel: ColorRect = $Control/LeftPanel
@onready var right_panel: ColorRect = $Control/RightPanel

const OPEN_LEFT = Vector2(-0.5, 0.0)
const OPEN_RIGHT = Vector2(1.0, 1.5)
const CLOSED_LEFT = Vector2(0.0, 0.5)
const CLOSED_RIGHT = Vector2(0.5, 1.0)

signal closed
signal opened

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
