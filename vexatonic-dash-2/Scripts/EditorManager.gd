extends Node2D

var noteDatas: Array[NoteData]
var laneDatas: Array[Lane]

@export var NOTE_SCENE: PackedScene
@export var CONNECTOR_SCENE: PackedScene

#Editor에서 Setting.speed는 1인 것으로 가정

# ================== 마우스로 화면 드래그 =====================
var dragging = false
var drag_start: Vector2

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
			drag_start = event.position
	
	if event is InputEventMouseMotion and dragging:
		var delta = event.position - drag_start
		drag_start = event.position
		$Camera2D.position -= delta
	
