extends Node2D

var noteDatas: Array[NoteData]
var laneDatas: Array[Lane]

@export var NOTE_SCENE: PackedScene
@export var CONNECTOR_SCENE: PackedScene

@onready var inputHandler = $EditorInputHandler
@onready var camera = $Camera2D

#Editor에서 Setting.speed는 1인 것으로 가정
func _ready():
	inputHandler.move_camera.connect(_on_move_camera)
	inputHandler.zoom_camera.connect(_on_zoom_camera)

# ================== 에디터 내 카메라 조작 =====================
var dragging = false
var drag_start: Vector2
var camera_zoom_level: int = 1

func _on_move_camera(delta: Vector2):
	$Camera2D.position -= delta

func _on_zoom_camera(zoom: bool):
	if zoom and camera_zoom_level < 5:
		camera_zoom_level += 1
	else:
		if camera_zoom_level > -5:
			camera_zoom_level -= 1
	var real_zoom = pow(1.2, camera_zoom_level)
	camera.zoom = Vector2.ONE * real_zoom
		
