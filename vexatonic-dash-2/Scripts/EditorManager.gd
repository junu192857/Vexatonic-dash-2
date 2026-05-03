extends Node2D

var noteDatas: Array[NoteData]
var laneDatas: Array[Lane]

@export var NOTE_SCENE: PackedScene
@export var CONNECTOR_SCENE: PackedScene
@export var LINE_SCENE: PackedScene

@onready var inputHandler = $EditorInputHandler
@onready var camera = $Camera2D

@onready var editorButtons = $CanvasLayer/NoteSelectorPanel

var editor_ready = false
#Editor에서 Setting.speed는 1인 것으로 가정
func _ready():
	inputHandler.move_camera.connect(_on_move_camera)
	inputHandler.zoom_camera.connect(_on_zoom_camera)
	inputHandler.move_preview.connect(_on_move_preview)
	editorButtons.visible = false
	
	
# ================== 에디터 시작하기 ==========================

func _on_start_editor():
	editor_ready = true
	var bpm = $CanvasLayer/InitialPanel/BPMBox.value
	var music_time = $CanvasLayer/InitialPanel/MusicTimeBox.value
	if music_time == 0:
		music_time = 180
	$CanvasLayer/InitialPanel.visible = false
	music_bpm.append(Vector2(0, bpm))
	music_end_time = music_time * 1000
	editorButtons.visible = true
	place_bar_lines()
	

# ================== 에디터 내 카메라 조작 =====================
var dragging = false
var drag_start: Vector2
var camera_zoom_level: int = 1

func _on_move_camera(delta: Vector2):
	if !editor_ready:
		return
	camera.position -= delta
	realign_lines_by_move()

func _on_zoom_camera(zoom: bool):
	if !editor_ready:
		return
	if zoom:
		if camera_zoom_level < 5:
			camera_zoom_level += 1
		else:
			return
	else:
		if camera_zoom_level > -5:
			camera_zoom_level -= 1
		else:
			return
	var real_zoom = pow(1.2, camera_zoom_level)
	camera.zoom = Vector2.ONE * real_zoom
	realign_lines_by_zoom(zoom)
# ===================== 박자 구분선 출력 =====================

var music_bpm: Array[Vector2] # (time, bpm): time부터 bpm
var music_end_time : float = 180000
@onready var line_holder = $LineHolder

#func calculate_camera_boundary() -> Vector4:
#	var viewport_size = get_viewport_rect().size / camera.zoom
#	var camera_pos = camera.global_position
#
#	var top_left = camera_pos - 3 * viewport_size / 2
#	var bottom_right = camera_pos + 3 * viewport_size / 2
#
#	var top = top_left.y
#	var bottom = bottom_right.y
#	var left = top_left.x
#	var right = bottom_right.x
#	
#	return Vector4(top, bottom, left, right)

#현재 camera의 zoom과 position에 맞춰서 마디 구분선 출력
func place_bar_lines():
	for i in range(music_bpm.size()):
		var bpm_start_time = music_bpm[i].x
		var bpm = music_bpm[i].y
		var bpm_end_time = music_bpm[i + 1].x if i + 1 < music_bpm.size() else music_end_time
		print(bpm_start_time)
		print(bpm_end_time)
		if bpm_start_time < 0:
			push_error("time cannot be negative")
			return
		if bpm_start_time > bpm_end_time:
			push_error("Please sort music_bpm by time ascending")
			return
		if bpm_end_time > music_end_time:
			push_error("BPM end time cannot be later than music end time")
			return

		var beat_duration = 60000.0 / bpm
		var bar_duration = beat_duration * 4

		var time = bpm_start_time
		var beat_count = 0

		while true:
			var x = Setting.get_posx_from_time(time)

			if beat_count % 4 == 0:
				put_line(x, true)
			else:
				put_line(x, false)

			beat_count += 1
			time += beat_duration

			if time >= bpm_end_time - Setting.EPSILON:
				break

		if i + 1 < music_bpm.size():
			var x = Setting.get_posx_from_time(bpm_end_time)
			put_line(x, true)

func put_line(pos_x: float, major: bool):
	print("PUTTING LINE..")
	var line = LINE_SCENE.instantiate()
	line_holder.add_child(line)
	line.position = Vector2(pos_x, camera.global_position.y)
	line.scale = Vector2(pow(1.2, 1 if major else -3), 3)

func realign_lines_by_zoom(zoom: bool):
	var lines = line_holder.get_children()
	for line in lines:
		if (zoom):
			line.scale.x /= 1.2
		else:
			line.scale.x *= 1.2

func realign_lines_by_move():
	var lines = line_holder.get_children()
	for line in lines:
		line.position.y = camera.global_position.y
	
# ========================= 레인 및 노트 입력 ======================

enum NoteSelection {Lane, RedNote, BlueNote, YellowNote, RedLong, BlueLong, YellowLong}
var current_mode: NoteSelection
var preview: Node2D

func _on_select_mode(mode: int):
	if (!editor_ready):
		return
	if mode in NoteSelection.values():
		current_mode = mode
		if (preview != null):
			preview.queue_free()
			preview = generate_preview(mode)
		print("Mode Changed: %d" % current_mode)
	else:
		push_error("Invalid EditMode: %d" % mode)
		
func _on_move_preview():
	if (!editor_ready):
		return
	if (preview == null):
		return
	var mouse_pos = get_global_mouse_position()

func generate_preview(mode: int) -> Node2D:
	var my_preview
	if (mode == 0): #lane
		pass
	else: if (mode % 3 == 1): #red
		pass
	else: if (mode % 3 == 2): #blue
		pass 
	else: #yellow
		pass
	return my_preview
