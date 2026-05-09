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
@onready var savePanel = $CanvasLayer/SavePanel

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
	music_bpm.append(Vector2(INF, 60))
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
var bit: int = 16
@onready var line_holder = $LineHolder

func set_bit(p_bit: int):
	bit = p_bit # 4, 6, 8, 12, 16, 24, 32, 48, free(0)
	place_bar_lines()

#현재 camera의 zoom과 position에 맞춰서 마디 구분선 출력
func place_bar_lines():
	for bar in line_holder.get_children():
		bar.queue_free()
	
	var effective_bit = bit if bit != 0 else 4
	
	for i in range(music_bpm.size() - 1):
		if music_bpm[i].x > music_bpm[i+1].x:
			push_error("Please sort by time ascending")
			return
		var bpm_start_time = music_bpm[i].x
		var bpm = music_bpm[i].y
		var bpm_end_time = min(music_bpm[i + 1].x, music_end_time)
		if bpm_start_time < 0:
			push_error("time cannot be negative")
			return
		if bpm_start_time > music_end_time:
			return
		
		var beat_duration = 60000.0 / bpm
		var snap_duration = beat_duration * 4.0 / effective_bit
		var time = bpm_start_time
		var snap_count = 0
		
		while true:
			var x = Setting.get_posx_from_time(time)
			if snap_count % effective_bit == 0:
				put_line(x, true)  # 마디 시작 (굵은 선)
			else:
				put_line(x, false)
			snap_count += 1
			time += snap_duration
			if time >= bpm_end_time - Setting.EPSILON:
				break
		
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

const UNPROCECSSED_COLORS: Array[Color] = [Color(1, 0.4, 0.4), Color(0.4, 0.4, 1.0),Color(1.0, 1.0, 0.4)]
const PROCESSED_COLORS: Array[Color] = [Color(0.8,0,0),Color(0.0, 0.0, 0.7),Color(0.8, 0.7, 0.0)]

enum NoteSelection {Lane = 0, RedNote = 1, BlueNote = 2, YellowNote = 3, RedLong = 11, BlueLong = 12, YellowLong = 13, Nothing = 100}
enum EditorState { Ready, Placing }
#Case 1: Initial lane 제작
#Case 2: lane 분기
#Case 3: lane 이어 찍기
enum LanePlacingCase {Case1, Case2, Case3, None}
var lane_case : LanePlacingCase
var lane_start_pos: Vector2
var target_lane: Lane
var long_start_pos: Vector2

var selected_note: NoteSelection = NoteSelection.Nothing
var selected_color
var note_case: bool
var current_state: EditorState = EditorState.Ready
var preview: Node2D

func _on_select_mode(selected: int):
	if (!editor_ready):
		return
	if selected in NoteSelection.values():
		selected_note = selected as NoteSelection
		selected_color = selected % 10 - 1
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
	if (selected == NoteSelection.Nothing):
		return
	var mouse_pos = get_global_mouse_position()
	if (selected == NoteSelection.Lane):
		if (current_state == EditorState.Ready):
			lane_case = find_lane_placing_case(mouse_pos)
			if lane_case == LanePlacingCase.None:
				preview.queue_free()
				preview = null
			else: 
				preview.position = get_preview_pos_for_lane(mouse_pos, lane_case)
		else:
			var snapped_x = get_snapped_x(mouse_pos.x)
			if (!check_mouse_in_available_area(mouse_pos) or lane_start_pos.x >= snapped_x):
				preview.queue_free()
				preview = null
			else:
				preview.set_data(lane_start_pos, Vector2(snapped_x, mouse_pos.y))
	else:
		if (current_state == EditorState.Ready):
			note_case = find_note_placing_available(mouse_pos)
			if (!note_case):
				preview.queue_free()
				preview = null
			else:
				preview.position = get_preview_pos_for_note(mouse_pos)
		else:
			var snapped_x = get_snapped_x(mouse_pos.x)
			if (!find_longNote_placing_available(mouse_pos, snapped_x)):
				preview.queue_free()
				preview = null
			else:
				var connector_start_x = long_start_pos.x + Setting.NOTE_WIDTH
				var existing_marker = null
				var existing_connector = null
				for child in preview.get_children():
					if child is EConnector:
						existing_connector = child
						continue
					if child is ENote:
						existing_marker = child
				if (snapped_x > connector_start_x):
					if existing_connector == null:
						existing_connector = CONNECTOR_SCENE.instantiate()
						preview.add_child(existing_connector)
						existing_connector.set_color(selected_color)
					var start_pos = Vector2(connector_start_x, target_lane.get_height(Setting.get_time_from_posx(connector_start_x)))
					var end_pos = Vector2(snapped_x, target_lane.get_height(Setting.get_time_from_posx(snapped_x)))
					print("Start_pos_y : %f and End_pos_y: %f" % [start_pos.y, end_pos.y])
					existing_connector.set_data(start_pos, end_pos)
					existing_connector.global_position = start_pos
				existing_marker.global_position = Vector2(snapped_x, target_lane.get_height(Setting.get_time_from_posx(snapped_x)))
		
				
func generate_preview(selected: int) -> Node2D:
	if (selected == NoteSelection.Nothing):
		return null
	
	var my_preview = null
	var mouse_pos = get_global_mouse_position()
	
	if (selected == NoteSelection.Lane):
		if (current_state == EditorState.Ready):
			lane_case = find_lane_placing_case(mouse_pos)
			if lane_case == LanePlacingCase.None:
				return null
			else:
				my_preview = CONNECTOR_SCENE.instantiate()
				add_child(my_preview)
				my_preview.position = get_preview_pos_for_lane(mouse_pos, lane_case)
		else:
			var snapped_x = get_snapped_x(mouse_pos.x)
			if (!check_mouse_in_available_area(mouse_pos) or lane_start_pos.x >= snapped_x):
				return null
			my_preview = CONNECTOR_SCENE.instantiate()
			#lane_start_pos와 현재 mouse_pos로 lane 찍기
			add_child(my_preview)
			my_preview.set_data(lane_start_pos, Vector2(snapped_x, mouse_pos.y))
			my_preview.position = lane_start_pos
	else: #Note인 경우
		if (current_state == EditorState.Ready):
			note_case = find_note_placing_available(mouse_pos)
			if (!note_case):
				return null
			my_preview = NOTE_SCENE.instantiate()
			add_child(my_preview)
			my_preview.position = get_preview_pos_for_note(mouse_pos)
			my_preview.set_color(selected_color)
		else: #Note이고 Placing인 경우: 무조건 LongNote
			var snapped_x = get_snapped_x(mouse_pos.x)
			if (!find_longNote_placing_available(mouse_pos, snapped_x)):
				return null
			my_preview = NOTE_SCENE.instantiate()
			add_child(my_preview)
			my_preview.position = long_start_pos
			my_preview.set_color(selected_color)
			
			var connector_start_x = long_start_pos.x + Setting.NOTE_WIDTH
			if (snapped_x > connector_start_x):
				var longNote_connector = CONNECTOR_SCENE.instantiate()
				my_preview.add_child(longNote_connector)
				longNote_connector.set_color(selected_color)
				var start_pos = Vector2(connector_start_x, target_lane.get_height(Setting.get_time_from_posx(connector_start_x)))
				var end_pos = Vector2(snapped_x, target_lane.get_height(Setting.get_time_from_posx(snapped_x)))
				longNote_connector.set_data(start_pos, end_pos)
				longNote_connector.global_position = start_pos
			
			var my_marker = NOTE_SCENE.instantiate()
			my_preview.add_child(my_marker)
			my_marker.global_position = Vector2(snapped_x, target_lane.get_height(Setting.get_time_from_posx(snapped_x)))
			my_marker.set_color(selected_color)
				
	return my_preview

# 마우스가 정상 위치에 있는지 확인. 해당 위치에 있어야 preview를 볼 수 있다.
func check_mouse_in_available_area(mouse_pos: Vector2) -> bool:
	if (mouse_pos.x < 0):
		return false
	var viewport_size = get_viewport_rect().size / camera.zoom
	var camera_pos = camera.global_position
	
	var screen_bottom = camera_pos.y + viewport_size.y / 2
	var threshold_y = screen_bottom - viewport_size.y * 0.3
	
	var screen_right = camera_pos.x + viewport_size.x / 2
	var threshold_x = screen_right - viewport_size.x * 0.15
	return mouse_pos.y <= threshold_y and mouse_pos.x <= threshold_x

func find_lane_placing_case(mouse_pos: Vector2) -> LanePlacingCase:
	if (!check_mouse_in_available_area(mouse_pos)):
		return LanePlacingCase.None
	var camera_left = camera.global_position.x - get_viewport_rect().size.x / 2

	# Case 2 우선 체크: 레인 위에 마우스가 있는 경우
	for lane in laneDatas:
		var lane_x_start = Setting.get_posx_from_time(lane.keyframes[0].x)
		var lane_x_end = Setting.get_posx_from_time(lane.keyframes[-1].x)
		var snapped_x = get_snapped_x(mouse_pos.x)
		if snapped_x >= lane_x_start and snapped_x < lane_x_end and mouse_pos.x <= lane_x_end:
			var lane_y = lane.get_height(Setting.get_time_from_posx(mouse_pos.x))
			if abs(lane_y - mouse_pos.y) <= Setting.HALF_CONNECTOR_HEIGHT:
				target_lane = lane
				return LanePlacingCase.Case2

	# Case 3 체크
	var closest_lane: Lane = null
	var closest_dist: float = INF

	for lane in laneDatas:
		var lane_x_end = Setting.get_posx_from_time(lane.keyframes[-1].x)
		if mouse_pos.x > lane_x_end:
			if camera_left < lane_x_end:
				var lane_y_end = lane.keyframes[-1].y
				if abs(lane_y_end - mouse_pos.y) <= Setting.HALF_CONNECTOR_HEIGHT:
					var dist = mouse_pos.x - lane_x_end
					if dist < closest_dist:
						closest_dist = dist
						closest_lane = lane

	if closest_lane != null:
		target_lane = closest_lane
		return LanePlacingCase.Case3

	# Case 1 체크
	if (camera_left <= 0): #and !is_lane_in_range(0, mouse_pos.x, mouse_pos.y)):
		return LanePlacingCase.Case1

	return LanePlacingCase.None

func find_note_placing_available(mouse_pos: Vector2) -> bool:
	if (!check_mouse_in_available_area(mouse_pos)):
		return false

	for lane in laneDatas:
		var lane_x_start = Setting.get_posx_from_time(lane.keyframes[0].x)
		var lane_x_end = Setting.get_posx_from_time(lane.keyframes[-1].x)
		var snapped_x = get_snapped_x(mouse_pos.x)
		if snapped_x >= lane_x_start and snapped_x <= lane_x_end and mouse_pos.x <= lane_x_end:
			var lane_y = lane.get_height(Setting.get_time_from_posx(mouse_pos.x))
			if abs(lane_y - mouse_pos.y) <= Setting.HALF_CONNECTOR_HEIGHT:
				target_lane = lane
				return true
	
	return false

func find_longNote_placing_available(mouse_pos: Vector2, snapped_x : float) -> bool:
	if (!check_mouse_in_available_area(mouse_pos) or long_start_pos.x >= snapped_x):
		return false
	var lane_x_end = Setting.get_posx_from_time(target_lane.keyframes[-1].x)
	if (snapped_x > lane_x_end):
		return false
	return true
# Ready 단계에서 Lane의 preview의 위치 구하기.
func get_preview_pos_for_lane(mouse_pos: Vector2, case: LanePlacingCase) -> Vector2:
	if (case == LanePlacingCase.Case1):
		return Vector2(0, mouse_pos.y)
	else: if (case == LanePlacingCase.Case2):
		var snapped_x = get_snapped_x(mouse_pos.x)
		return Vector2(snapped_x, target_lane.get_height(Setting.get_time_from_posx(snapped_x)))
	else: if (case == LanePlacingCase.Case3):
		return Vector2(Setting.get_posx_from_time(target_lane.keyframes[-1].x),target_lane.keyframes[-1].y)
	return Vector2.ZERO
	
func get_preview_pos_for_note(mouse_pos: Vector2) -> Vector2:
	var snapped_x = get_snapped_x(mouse_pos.x)
	return Vector2(snapped_x, target_lane.get_height(Setting.get_time_from_posx(snapped_x)))

func _on_put_note():
	if (!editor_ready):
		return
	if (preview == null):
		return
	if (current_state == EditorState.Ready):
		if (selected_note == NoteSelection.Lane):
			lane_start_pos = preview.global_position
		else: if (selected_note / 10 == 0): # 단노트
			var data = NoteData.new(Setting.get_time_from_posx(preview.global_position.x), selected_color, 0, 0, target_lane.lane_index)
			noteDatas.append(data)
			preview.set_data(data)
			print("New Note added")
			preview = null
			return
		else: if (selected_note / 10 == 1): #롱노트
			var data = NoteData.new(Setting.get_time_from_posx(preview.global_position.x), selected_color, 1, 0, target_lane.lane_index)
			noteDatas.append(data)
			preview.set_data(data)
			long_start_pos = preview.global_position
			print("New LongNote init added")
			pass
		current_state = EditorState.Placing
	else: if (current_state == EditorState.Placing):
		if (selected_note == NoteSelection.Lane):
			if (lane_case == LanePlacingCase.Case1):
				print("CASE 1 ACTIVATED")
				var new_index = Lane.find_free_index(laneDatas)
				var new_lane = Lane.new(new_index, true)
				
				new_lane.add_keyframe(0, lane_start_pos.y)
				new_lane.add_keyframe(Setting.get_time_from_posx(preview.get_end_pos(lane_start_pos).x), preview.get_end_pos(lane_start_pos).y)
				print("New initial line added with initial y %f and next y %f" % [lane_start_pos.y, preview.get_end_pos(lane_start_pos).y ])
				laneDatas.append(new_lane)
				preview.set_lane_index(new_index)
				preview = null
			else: if (lane_case == LanePlacingCase.Case2):
				print("CASE 2 ACTIVATED")
				var new_index = Lane.find_free_index(laneDatas)
				var new_lane = Lane.new(new_index, false)
				new_lane.add_keyframe(Setting.get_time_from_posx(lane_start_pos.x), lane_start_pos.y)
				new_lane.add_keyframe(Setting.get_time_from_posx(preview.get_end_pos(lane_start_pos).x), preview.get_end_pos(lane_start_pos).y)
				print("New initial line added with initial y %f and next y %f" % [lane_start_pos.y,preview.get_end_pos(lane_start_pos).y ])
				laneDatas.append(new_lane)
				preview.set_lane_index(new_index)
				preview = null
			else: if (lane_case == LanePlacingCase.Case3):
				print("CASE 3 ACTIVATED")
				target_lane.add_keyframe(Setting.get_time_from_posx(preview.get_end_pos(lane_start_pos).x), preview.get_end_pos(lane_start_pos).y)
				print("Lane %d: added new keyframe with y %f" % [target_lane.lane_index, preview.get_end_pos(lane_start_pos).y])
				preview.set_lane_index(target_lane.lane_index)
				preview = null
			lane_case = LanePlacingCase.None
		current_state = EditorState.Ready

func get_snapped_x(mouse_x: float) -> float:
	if bit == 0:
		return mouse_x
	
	var time = Setting.get_time_from_posx(mouse_x)
	
	var bpm = music_bpm[0].y
	var bpm_start_time = music_bpm[0].x
	for i in range(music_bpm.size() - 1):
		if time >= music_bpm[i].x and time < music_bpm[i + 1].x:
			bpm = music_bpm[i].y
			bpm_start_time = music_bpm[i].x
			break
	
	var beat_duration = 60000.0 / bpm
	var snap_duration = beat_duration * 4.0 / bit
	
	var elapsed = time - bpm_start_time
	var snapped_time = bpm_start_time + round(elapsed / snap_duration) * snap_duration
	
	return Setting.get_posx_from_time(snapped_time)

# ======================== Testing ===================================

func print_lane_info():
	for lane in laneDatas:
		print("LANE INDEX %d" % lane.lane_index)
		for keyframe in lane.keyframes:
			print("my lane's keyframe: time %f and height %f" % [keyframe.x, keyframe.y])
			
			
# ======================== Save Chart ================================

func open_save_panel():
	editor_ready = false
	savePanel.visible = true

func quit_save_panel():
	savePanel.visible = false
	editor_ready = false

func save_chart():
	var file_name = savePanel.get_node("LineEdit").text
	if file_name.is_empty():
		push_error("파일 이름을 입력해주세요!")
		return
	
	var file = FileAccess.open("res://Charts/" + file_name + ".csv", FileAccess.WRITE)
	if file == null:
		push_error("ERROR: 파일을 열 수 없습니다.: " + file_name)
		return
	
	for lane in laneDatas:
		file.store_line("LANE %d %d" % [lane.lane_index, 1 if lane.is_init else 0])
		for kf in lane.keyframes:
			file.store_line("%s %s" % [kf.x, kf.y])
		file.store_line("END")
	
	quit_save_panel()
