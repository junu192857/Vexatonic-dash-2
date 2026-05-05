extends Node2D

var noteDatas: Array[NoteData]
var laneDatas: Array[Lane]

@export var NOTE_SCENE: PackedScene
@export var CONNECTOR_SCENE: PackedScene
@export var LINE_SCENE: PackedScene

@onready var inputHandler = $EditorInputHandler
@onready var camera = $Camera2D

@onready var noteSelectorPanel = $CanvasLayer/NoteSelectorPanel
@onready var settingPanel = $CanvasLayer/SettingPanel

var editor_ready = false
#Editor에서 Setting.speed는 1인 것으로 가정
func _ready():
	inputHandler.move_camera.connect(_on_move_camera)
	inputHandler.zoom_camera.connect(_on_zoom_camera)
	inputHandler.move_preview.connect(_on_move_preview)
	inputHandler.put_note.connect(_on_put_note)
	noteSelectorPanel.visible = false
	settingPanel.visible = false
	
	
# ================== 에디터 시작하기 ==========================

func _on_start_editor():
	editor_ready = true
	current_state = EditorState.Ready
	var bpm = $CanvasLayer/InitialPanel/BPMBox.value
	var music_time = $CanvasLayer/InitialPanel/MusicTimeBox.value
	if music_time == 0:
		music_time = 180
	$CanvasLayer/InitialPanel.visible = false
	music_bpm.append(Vector2(0, bpm))
	music_end_time = music_time * 1000
	noteSelectorPanel.visible = true
	settingPanel.visible = true
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

enum NoteSelection {Lane, RedNote, BlueNote, YellowNote, RedLong, BlueLong, YellowLong, Nothing}
enum EditorState { Ready, Placing }
#Case 1: Initial lane 제작
#Case 2: lane 분기
#Case 3: lane 이어 찍기
enum LanePlacingCase {Case1, Case2, Case3, None}
var lane_case : LanePlacingCase
var lane_start_pos: Vector2

var selected_note: NoteSelection = NoteSelection.Nothing
var current_state: EditorState = EditorState.Ready
var preview: Node2D

func _on_select_mode(selected: int):
	if (!editor_ready):
		return
	if selected in NoteSelection.values():
		selected_note = selected
		current_state = EditorState.Ready
		if (preview != null):
			preview.queue_free()
			preview = null
			#preview = generate_preview(selected_note)
			print("Note Changed: %d" % selected_note)
	else:
		push_error("Invalid EditMode: %d" % selected)
		
func _on_move_preview():
	if (!editor_ready):
		return
	if (preview == null):
		preview = generate_preview(selected_note)
	else:
		update_preview(selected_note)
		
func update_preview(selected: int):
	var mouse_pos = get_global_mouse_position()
	if (selected == NoteSelection.Lane):
		if (current_state == EditorState.Ready):
			lane_case = find_lane_placing_case(mouse_pos)
			if (lane_case == LanePlacingCase.None):
				preview.queue_free()
				preview = null
			else: 
				preview.position = get_preview_pos_for_lane(mouse_pos, lane_case)
		else:
			if (lane_start_pos.x >= mouse_pos.x):
				preview.queue_free()
				preview == null
			else:
				preview.set_data(lane_start_pos, mouse_pos)
				
func generate_preview(selected: int) -> Node2D:
	var my_preview
	var mouse_pos = get_global_mouse_position()
	
	if (selected == NoteSelection.Lane):
		if (current_state == EditorState.Ready):
			lane_case = find_lane_placing_case(mouse_pos)
			#case 1: 비어 있는 곳에 lane을 찍는 경우
			if lane_case == LanePlacingCase.None:
				return null
			if lane_case == LanePlacingCase.Case1:
				my_preview = CONNECTOR_SCENE.instantiate()
				add_child(my_preview)
				my_preview.position = get_preview_pos_for_lane(mouse_pos, lane_case)
		else:
			my_preview = CONNECTOR_SCENE.instantiate()
			#lane_start_pos와 현재 mouse_pos로 lane 찍기
			add_child(my_preview)
			my_preview.set_data(lane_start_pos, mouse_pos)
			my_preview.position = lane_start_pos
	else: if (selected == NoteSelection.RedNote or selected == NoteSelection.RedLong):
		pass
	else: if (selected == NoteSelection.BlueNote or selected == NoteSelection.BlueLong):
		pass
	else:
		pass
	return my_preview

#(x_start, y) 와 (x_end, y)의 직선 구간 사이에 레인이 있는지 확인.
func is_lane_in_range(x_start: float, x_end: float, y: float) -> bool:
	if (x_start >= x_end):
		push_error("Why x_start is higher than x_end?!")
		return false
	
	for lane in laneDatas:
		var lane_x_start = Setting.get_posx_from_time(lane.keyframes[0].x)
		var lane_x_end = Setting.get_posx_from_time(lane.keyframes[-1].x)
		
		# x 범위가 겹치는지 확인
		if lane_x_end < x_start or lane_x_start > x_end:
			continue
		
		# 겹치는 x 구간에서 레인의 y좌표 확인
		var check_x_start = max(x_start, lane_x_start)
		var check_x_end = min(x_end, lane_x_end)
		var check_time_start = Setting.get_time_from_posx(check_x_start)
		var check_time_end = Setting.get_time_from_posx(check_x_end)
		
		for kf in lane.keyframes:
			if kf.x < check_time_start or kf.x > check_time_end:
				continue
			if abs(lane.get_height(kf.x) - y) <= 2 * Setting.HALF_CONNECTOR_HEIGHT:
				return true
		
		# 시작/끝 지점도 체크
		if abs(lane.get_height(check_time_start) - y) <= 2 * Setting.HALF_CONNECTOR_HEIGHT:
			return true
		if abs(lane.get_height(check_time_end) - y) <= 2 * Setting.HALF_CONNECTOR_HEIGHT:
			return true
	
	return false

# 마우스가 정상 위치에 있는지 확인. 해당 위치에 있어야 preview를 볼 수 있다.
func check_mouse_in_available_area(mouse_pos: Vector2) -> bool:
	if (mouse_pos.x < 0):
		return false
	var viewport_size = get_viewport_rect().size
	var camera_pos = camera.global_position
	var screen_bottom = camera_pos.y + viewport_size.y / 2
	var threshold_y = screen_bottom - viewport_size.y * 0.3
	return mouse_pos.y <= threshold_y

func find_lane_placing_case(mouse_pos: Vector2) -> LanePlacingCase:
	if (!check_mouse_in_available_area(mouse_pos)):
		return LanePlacingCase.None

	# Case 2 우선 체크: 레인 위에 마우스가 있는 경우
	for lane in laneDatas:
		var lane_x_start = Setting.get_posx_from_time(lane.keyframes[0].x)
		var lane_x_end = Setting.get_posx_from_time(lane.keyframes[-1].x)
		if mouse_pos.x >= lane_x_start and mouse_pos.x <= lane_x_end:
			var lane_y = lane.get_height(Setting.get_time_from_posx(mouse_pos.x))
			if abs(lane_y - mouse_pos.y) <= 2 * Setting.HALF_CONNECTOR_HEIGHT:
				return LanePlacingCase.Case2

	# Case 3 체크: 마우스가 레인 끝보다 오른쪽이고 왼쪽에 레인이 있는 경우
	for lane in laneDatas:
		var lane_x_end = Setting.get_posx_from_time(lane.keyframes[-1].x)
		if mouse_pos.x > lane_x_end:
			var lane_y_end = lane.keyframes[-1].y
			if abs(lane_y_end - mouse_pos.y) <= 2 * Setting.HALF_CONNECTOR_HEIGHT:
				return LanePlacingCase.Case3

	# Case 1 체크
	var camera_left = camera.global_position.x - get_viewport_rect().size.x / 2
	if (camera_left <= 0 and !is_lane_in_range(0, mouse_pos.x, mouse_pos.y)):
		return LanePlacingCase.Case1

	return LanePlacingCase.None

func get_preview_pos_for_lane(mouse_pos: Vector2, case: LanePlacingCase) -> Vector2:
	if (case == LanePlacingCase.Case1):
		return Vector2(0, mouse_pos.y)
	return Vector2.ZERO
	
func _on_put_note():
	if (!editor_ready):
		return
	if (preview == null):
		return
	if (current_state == EditorState.Ready):
		if (selected_note == NoteSelection.Lane):
			lane_start_pos = preview.global_position
		current_state = EditorState.Placing
	else: if (current_state == EditorState.Placing):
		if (selected_note == NoteSelection.Lane):
			if (lane_case == LanePlacingCase.Case1):
				print("HELLO?")
				var new_index = Lane.find_free_index(laneDatas)
				var new_lane = Lane.new(new_index, true)
				laneDatas.append(new_lane)
				new_lane.add_keyframe(0, -preview.global_position.y)
				new_lane.add_keyframe(Setting.get_time_from_posx(lane_start_pos.x), -preview.get_end_pos(lane_start_pos).y)
				preview.set_lane_index(new_index)
				preview = null
			lane_case = LanePlacingCase.None
		current_state = EditorState.Ready
