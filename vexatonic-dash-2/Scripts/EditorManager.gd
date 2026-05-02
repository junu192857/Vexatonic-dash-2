extends Node2D

var noteDatas: Array[NoteData]
var laneDatas: Array[Lane]

@export var NOTE_SCENE: PackedScene
@export var CONNECTOR_SCENE: PackedScene

@onready var inputHandler = $EditorInputHandler
@onready var camera = $Camera2D

@onready var editorButtons = $CanvasLayer/NoteSelectorPanel

var editor_ready = false
#Editor에서 Setting.speed는 1인 것으로 가정
func _ready():
	inputHandler.move_camera.connect(_on_move_camera)
	inputHandler.zoom_camera.connect(_on_zoom_camera)
	editorButtons.visible = false
	
	
# ================== 에디터 시작하기 ==========================

func _on_start_editor():
	editor_ready = true
	var bpm = $CanvasLayer/InitialPanel/SpinBox.value
	$CanvasLayer/InitialPanel.visible = false
	music_bpm.append(Vector2(0, bpm))
	editorButtons.visible = true
	print("BPM: %f" % bpm)
	

# ================== 에디터 내 카메라 조작 =====================
var dragging = false
var drag_start: Vector2
var camera_zoom_level: int = 1

func _on_move_camera(delta: Vector2):
	if !editor_ready:
		return
	$Camera2D.position -= delta

func _on_zoom_camera(zoom: bool):
	if !editor_ready:
		return
	if zoom and camera_zoom_level < 5:
		camera_zoom_level += 1
	else:
		if camera_zoom_level > -5:
			camera_zoom_level -= 1
	var real_zoom = pow(1.2, camera_zoom_level)
	camera.zoom = Vector2.ONE * real_zoom
# ===================== 박자 구분선 출력 =====================

var music_bpm: Array[Vector2] # (time, bpm): time부터 bpm

func calculate_camera_boundary() -> Vector4:
	var viewport_size = get_viewport_rect().size / camera.zoom
	var camera_pos = camera.global_position

	var top_left = camera_pos - 3 * viewport_size / 2
	var bottom_right = camera_pos + 3 * viewport_size / 2

	var top = top_left.y
	var bottom = bottom_right.y
	var left = top_left.x
	var right = bottom_right.x
	
	return Vector4(top, bottom, left, right)

#현재 camera의 zoom과 position에 맞춰서 마디 구분선 출력
func put_line():
	var boundary = calculate_camera_boundary()
	place_bar_lines(boundary)

func place_bar_lines(boundary: Vector4):
	for i in range(music_bpm.size()):
		var bpm_start_time = music_bpm[i].x
		var bpm = music_bpm[i].y
		var bpm_end_time = music_bpm[i + 1].x if i + 1 < music_bpm.size() else INF

		var beat_duration = 60000.0 / bpm
		var bar_duration = beat_duration * 4

		var time = bpm_start_time
		var beat_count = 0

		while true:
			var x = Setting.get_posx_from_time(time)
			if x > boundary[3]:
				break

			if x >= boundary[2]:
				if beat_count % 4 == 0:
					put_line_1(x)
				else:
					put_line_2(x)

			beat_count += 1
			time += beat_duration

			if time >= bpm_end_time - Setting.EPSILON:
				break

		if i + 1 < music_bpm.size():
			var x = Setting.get_posx_from_time(bpm_end_time)
			if x >= boundary[2] and x <= boundary[3]:
				put_line_1(x)

func put_line_1(pos_x: float):
	pass

func put_line_2(pos_x: float):
	pass
