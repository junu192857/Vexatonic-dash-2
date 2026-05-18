extends Node2D

var levelData: LevelData

@export var NOTE_SCENE: PackedScene
@export var CONNECTOR_SCENE: PackedScene
@export var LINE_SCENE: PackedScene

@onready var inputHandler = $EditorInputHandler
@onready var camera = $Camera2D
@onready var musicPlayer = $AudioStreamPlayer

@onready var initialPanel = $CanvasLayer/InitialPanel
@onready var noteSelectorPanel = $CanvasLayer/NoteSelectorPanel
@onready var settingPanel = $CanvasLayer/SettingPanel
@onready var savePanel = $CanvasLayer/SavePanel
@onready var loadPanel = $CanvasLayer/LoadPanel

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
	if (!check_everything_done()):
		return
	set_initial_value()
	initiate_editor()
	place_bar_lines()

func check_everything_done() -> bool:
	if music_path == "":
		initialPanel.get_node("WarningLabel").text = "WARNING: Please set music"
		return false
	if initialPanel.get_node("BPMBox").value == 0:
		initialPanel.get_node("WarningLabel").text = "WARNING: Please set initial bpm"
		return false
	if initialPanel.get_node("MusicTimeBox").value == 0:
		initialPanel.get_node("WarningLabel").text = "WARNING: Please set song's length"
		return false
	return true

func initiate_editor():
	editor_ready = true
	current_state = EditorState.Ready
	initialPanel.visible = false
	noteSelectorPanel.visible = true
	settingPanel.visible = true

func set_initial_value():
	levelData = LevelData.new()
	var bpm = initialPanel.get_node("BPMBox").value
	var music_time = initialPanel.get_node("MusicTimeBox").value
	levelData.bpm.append(Vector2(0, bpm))
	levelData.bpm.append(Vector2(Setting.INFINITE, 60))
	levelData.music_path = music_path.get_file()
	levelData.length = music_time * 1000
	chart_loaded = false

func start_find_music():
	initialPanel.get_node("FileDialog").popup()
	
func select_music(path: String):
	var stream = AudioStreamMP3.new()
	var data = FileAccess.get_file_as_bytes(path)
	if (data.is_empty()):
		initialPanel.get_node("MusicText").text = "Please load valid music file"
		initialPanel.get_node("StartButton").visible = false
		return
	stream.data = FileAccess.get_file_as_bytes(path)

	musicPlayer.stream = stream
	music_path = path
	initialPanel.get_node("MusicTimeBox").value = musicPlayer.stream.get_length()
	initialPanel.get_node("MusicText").text = path.get_file()
	
	initialPanel.get_node("StartButton").visible = true

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
	
	for i in range(levelData.bpm.size() - 1):
		print("bpm time: %f" % levelData.bpm[i].x)
	
	for i in range(levelData.bpm.size() - 1):
		if levelData.bpm[i].x > levelData.bpm[i+1].x:
			push_error("Please sort by time ascending")
			return
		var bpm_start_time = levelData.bpm[i].x
		var bpm = levelData.bpm[i].y
		var bpm_end_time = min(levelData.bpm[i + 1].x, levelData.length)
		if bpm_start_time < 0:
			push_error("time cannot be negative")
			return
		if bpm_start_time > levelData.length:
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
	return line

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

enum NoteSelection {Lane = 0, RedNote = 1, BlueNote = 2, YellowNote = 3, RedLong = 11, BlueLong = 12, \
					YellowLong = 13, ModifyLane = 21, ModifyNote = 22, Nothing = 100}
enum EditorState { Ready, Placing }
#Case 1: Initial lane 제작
#Case 2: lane 분기
#Case 3: lane 이어 찍기
enum LanePlacingCase {Case1, Case2, Case3, None}
var lane_case : LanePlacingCase
var lane_start_pos: Vector2
var target_lane: Lane
var long_start_pos: Vector2
var long_end_time: float

var selected_note: NoteSelection = NoteSelection.Nothing
var selected_color
var note_case: bool
var current_state: EditorState = EditorState.Ready
var preview: Node2D

var target_keyframe
var keyframe_indicator: ENote
var target_note: ENote

var mouse_pos: Vector2
var snapped_x: float

func _on_select_note(selected: int):
	if (!editor_ready):
		return
	if selected in NoteSelection.values():
		selected_note = selected as NoteSelection
		if (selected < 20):
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
	mouse_pos = get_global_mouse_position()
	snapped_x = get_snapped_x(mouse_pos.x)
	
	if (selected_note == NoteSelection.ModifyLane or selected_note == NoteSelection.ModifyNote):
		if (check_mouse_in_available_area()):
			find_modify_target()
		else:
			cleanup_values()
	else:
		if (preview == null):
			if (check_mouse_in_available_area()):
				preview = generate_preview(selected_note, mouse_pos, snapped_x)
		else:
			if (!check_mouse_in_available_area()):
				preview.queue_free()
				preview = null
			else: update_preview(selected_note, mouse_pos, snapped_x)

# Modify 과정에서 설정된 값들 전부 초기화.
func cleanup_values():
	target_keyframe = null
	if (keyframe_indicator != null):
		keyframe_indicator.queue_free()
		keyframe_indicator = null
	if (target_note != null):
		target_note.process_color()
		target_note = null

#새로운 노트나 레인을 찍기 위한 preview를 이동시키는 함수.
func update_preview(selected: int, mouse_pos: Vector2, snapped_x: float):
	if (selected == NoteSelection.Nothing):
		return
	if (selected == NoteSelection.Lane):
		if (current_state == EditorState.Ready):
			lane_case = find_lane_placing_case(mouse_pos)
			if lane_case == LanePlacingCase.None:
				preview.queue_free()
				preview = null
			else: 
				preview.position = get_preview_pos_for_lane(mouse_pos, lane_case)
		else:
			if (lane_start_pos.x >= snapped_x):
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
			if (!find_longNote_placing_available(mouse_pos, snapped_x)):
				preview.queue_free()
				preview = null
			else:
				var connector_start_x = long_start_pos.x + Setting.NOTE_WIDTH / 2.0
				var connector_end_x = snapped_x - Setting.NOTE_WIDTH / 2.0
				var existing_marker = null
				var existing_connector = null
				for child in preview.get_children():
					if child is EConnector:
						existing_connector = child
						continue
					if child is ENote:
						existing_marker = child
				if connector_end_x > connector_start_x:
					# 구간 포인트 수집
					var points = [connector_start_x]
					for kf in target_lane.keyframes:
						var kf_x = Setting.get_posx_from_time(kf.x)
						if kf_x > connector_start_x and kf_x < connector_end_x:
							points.append(kf_x)
						if kf_x >= connector_end_x:
							break
					points.append(connector_end_x)
					
					# existing_connector 없으면 생성
					if existing_connector == null:
						existing_connector = CONNECTOR_SCENE.instantiate()
						preview.add_child(existing_connector)
						existing_connector.set_editor_color(selected_color)
						print("new connector added")
					
					# 체인 순회하면서 재사용/생성/삭제
					var current = existing_connector
					
					print("points.size:  %d" % points.size())
					for i in range(points.size() - 1):
						var start_pos = Vector2(points[i], target_lane.get_height(Setting.get_time_from_posx(points[i])))
						var end_pos = Vector2(points[i + 1], target_lane.get_height(Setting.get_time_from_posx(points[i + 1])))
						current.set_data(start_pos, end_pos)
						current.global_position = start_pos
						
						if i < points.size() - 2:
							print("Hello?")
							# 다음 구간이 더 있음
							var child_connector
							for child in current.get_children():
								if child is EConnector:
									child_connector = child
									break
							if child_connector == null:
								child_connector = CONNECTOR_SCENE.instantiate()
								current.add_child(child_connector)
								child_connector.set_editor_color(selected_color)
							current = child_connector
						else:
							print("HELLO@?")
							# 마지막 구간: 남은 자식 Connector 삭제
							var child_connector
							for child in current.get_children():
								if child is EConnector:
									child_connector = child
									break
							if child_connector != null:
								child_connector.queue_free()
								child_connector = null
								print("child_connector deleted")
				
				if (existing_marker == null):
					existing_marker = NOTE_SCENE.instantiate()
					preview.add_child(existing_marker)
					existing_marker.set_color(selected_color)
				long_end_time = Setting.get_time_from_posx(existing_marker.global_position.x)
				existing_marker.global_position = Vector2(snapped_x, target_lane.get_height(Setting.get_time_from_posx(snapped_x)))
		
#새로운 노트나 레인을 찍기 위한 preview를 만드는 함수.
func generate_preview(selected: int, mouse_pos: Vector2, snapped_x: float) -> Node2D:
	if (selected == NoteSelection.Nothing):
		return null
	
	var my_preview = null
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
			if (lane_start_pos.x >= snapped_x):
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
			if (!find_longNote_placing_available(mouse_pos, snapped_x)):
				return null
			my_preview = NOTE_SCENE.instantiate()
			add_child(my_preview)
			my_preview.position = long_start_pos
			my_preview.set_color(selected_color)
			
			var connector_start_x = long_start_pos.x + Setting.NOTE_WIDTH / 2.0
			var connector_end_x = snapped_x - Setting.NOTE_WIDTH / 2.0
			if connector_end_x > connector_start_x:
				var points = [connector_start_x]
				for kf in target_lane.keyframes:
					var kf_x = Setting.get_posx_from_time(kf.x)
					if kf_x > connector_start_x and kf_x < connector_end_x:
						points.append(kf_x)
					if kf_x >= connector_end_x:
						break
				points.append(connector_end_x)
				
				var parent_node = my_preview
				for i in range(points.size() - 1):
					var start_x = points[i]
					var end_x = points[i + 1]
					var start_pos = Vector2(start_x, target_lane.get_height(Setting.get_time_from_posx(start_x)))
					var end_pos = Vector2(end_x, target_lane.get_height(Setting.get_time_from_posx(end_x)))
					
					var longNote_connector = CONNECTOR_SCENE.instantiate()
					parent_node.add_child(longNote_connector)
					longNote_connector.set_editor_color(selected_color)
					longNote_connector.set_data(start_pos, end_pos)
					longNote_connector.global_position = start_pos
					parent_node = longNote_connector
					print("Generating: connector added")
			
			var my_marker = NOTE_SCENE.instantiate()
			my_preview.add_child(my_marker)
			my_marker.global_position = Vector2(snapped_x, target_lane.get_height(Setting.get_time_from_posx(snapped_x)))
			my_marker.set_color(selected_color)
			long_end_time = Setting.get_time_from_posx(my_marker.global_position.x)
	return my_preview

func find_modify_target():
	if (!editor_ready):
		return
	if (current_state == EditorState.Ready):
		match selected_note:
			NoteSelection.ModifyLane:
				var new_target_keyframe = find_target_keyframe()
				if (new_target_keyframe == null):
					cleanup_values()
					return
				if (target_keyframe != new_target_keyframe):
					target_keyframe = new_target_keyframe
					if (keyframe_indicator != null):
						keyframe_indicator.queue_free()
					keyframe_indicator = put_keyframe_indicator(target_keyframe)
			NoteSelection.ModifyNote:
				var new_target_note = find_target_note()
			_:
				push_error("INVALID NOTE SELECTION")

func put_keyframe_indicator(keyframe: Vector2):
	var indicator = NOTE_SCENE.instantiate()
	add_child(indicator)
	indicator.global_position = Vector2(Setting.get_posx_from_time(target_keyframe.x), target_keyframe.y)
	indicator.sprite.modulate = Color(0,0,0)
	return indicator
# 마우스가 정상 위치에 있는지 확인. 해당 위치에 있어야 preview를 볼 수 있다.
func check_mouse_in_available_area() -> bool:
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
	#if (!check_mouse_in_available_area(mouse_pos)):
	#	return LanePlacingCase.None
	var camera_left = camera.global_position.x - get_viewport_rect().size.x / 2

	# Case 2 우선 체크: 레인 위에 마우스가 있는 경우
	for lane in levelData.lanes:
		var lane_x_start = Setting.get_posx_from_time(lane.keyframes[0].x)
		var lane_x_end = Setting.get_posx_from_time(lane.keyframes[-1].x)
		if snapped_x >= lane_x_start and mouse_pos.x > lane_x_start and snapped_x < lane_x_end and mouse_pos.x <= lane_x_end:
			var lane_y = lane.get_height(Setting.get_time_from_posx(mouse_pos.x))
			if abs(lane_y - mouse_pos.y) <= Setting.HALF_CONNECTOR_HEIGHT:
				set_target_lane(lane)
				return LanePlacingCase.Case2

	# Case 3 체크
	var closest_lane: Lane = null
	var closest_dist: float = Setting.INFINITE

	for lane in levelData.lanes:
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
		set_target_lane(closest_lane)
		return LanePlacingCase.Case3

	# Case 1 체크
	if (camera_left <= 0): #and !is_lane_in_range(0, mouse_pos.x, mouse_pos.y)):
		return LanePlacingCase.Case1

	return LanePlacingCase.None

func find_note_placing_available(mouse_pos: Vector2) -> bool:
	#if (!check_mouse_in_available_area(mouse_pos)):
	#	return false

	for lane in levelData.lanes:
		var lane_x_start = Setting.get_posx_from_time(lane.keyframes[0].x)
		var lane_x_end = Setting.get_posx_from_time(lane.keyframes[-1].x)
		if snapped_x >= lane_x_start and mouse_pos.x >= lane_x_start and snapped_x <= lane_x_end and mouse_pos.x <= lane_x_end:
			var lane_y = lane.get_height(Setting.get_time_from_posx(mouse_pos.x))
			if abs(lane_y - mouse_pos.y) <= Setting.HALF_CONNECTOR_HEIGHT:
				set_target_lane(lane)
				return true
	
	return false

func find_longNote_placing_available(mouse_pos: Vector2, snapped_x : float) -> bool:
	if (long_start_pos.x >= snapped_x):
		return false
	var lane_x_end = Setting.get_posx_from_time(target_lane.keyframes[-1].x)
	print("Snapped_x: %f, land_x_end: %f" % [snapped_x, lane_x_end])
	if (snapped_x > lane_x_end):
		return false
	return true
# Ready 단계에서 Lane의 preview의 위치 구하기.
func get_preview_pos_for_lane(mouse_pos: Vector2, case: LanePlacingCase) -> Vector2:
	if (case == LanePlacingCase.Case1):
		return Vector2(0, mouse_pos.y)
	else: if (case == LanePlacingCase.Case2):
		return Vector2(snapped_x, target_lane.get_height(Setting.get_time_from_posx(snapped_x)))
	else: if (case == LanePlacingCase.Case3):
		return Vector2(Setting.get_posx_from_time(target_lane.keyframes[-1].x),target_lane.keyframes[-1].y)
	return Vector2.ZERO
	
func get_preview_pos_for_note(mouse_pos: Vector2) -> Vector2:
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
			levelData.noteDatas.append(data)
			preview.set_data(data)
			target_lane.add_note(preview)
			print("New Note added")
			preview = null
			return
		else: if (selected_note / 10 == 1): #롱노트
			long_start_pos = preview.global_position
			print("New LongNote init added")
			pass
		current_state = EditorState.Placing
	else: if (current_state == EditorState.Placing):
		if (selected_note == NoteSelection.Lane):
			if (lane_case == LanePlacingCase.Case1):
				print("CASE 1 ACTIVATED")
				var new_index = Lane.find_free_index(levelData.lanes)
				var new_lane = Lane.new(new_index, true)
				new_lane.add_keyframe(0, lane_start_pos.y)
				new_lane.add_keyframe(Setting.get_time_from_posx(preview.get_end_pos(lane_start_pos).x), preview.get_end_pos(lane_start_pos).y)
				print("New initial line added with initial y %f and next y %f" % [lane_start_pos.y, preview.get_end_pos(lane_start_pos).y ])
				levelData.lanes.append(new_lane)
				new_lane.add_editor_connector(preview)
				preview.set_lane_index(new_index)
			else: if (lane_case == LanePlacingCase.Case2):
				print("CASE 2 ACTIVATED")
				var new_index = Lane.find_free_index(levelData.lanes)
				var new_lane = Lane.new(new_index, false)
				new_lane.add_keyframe(Setting.get_time_from_posx(lane_start_pos.x), lane_start_pos.y)
				new_lane.add_keyframe(Setting.get_time_from_posx(preview.get_end_pos(lane_start_pos).x), preview.get_end_pos(lane_start_pos).y)
				print("New initial line added with initial y %f and next y %f" % [lane_start_pos.y,preview.get_end_pos(lane_start_pos).y ])
				levelData.lanes.append(new_lane)
				target_lane.add_editor_connector(preview)
				preview.set_lane_index(new_index)
			else: if (lane_case == LanePlacingCase.Case3):
				print("CASE 3 ACTIVATED")
				target_lane.add_keyframe(Setting.get_time_from_posx(preview.get_end_pos(lane_start_pos).x), preview.get_end_pos(lane_start_pos).y)
				print("Lane %d: added new keyframe with y %f" % [target_lane.lane_index, preview.get_end_pos(lane_start_pos).y])
				target_lane.add_editor_connector(preview)
				preview.set_lane_index(target_lane.lane_index)
			preview = null
			lane_case = LanePlacingCase.None
		else:
			var data = NoteData.new(Setting.get_time_from_posx(preview.global_position.x), selected_color, 1, long_end_time, target_lane.lane_index)
			print("New LongNote added: start time %f and end time %f and lane index %d" % [Setting.get_time_from_posx(preview.global_position.x), long_end_time, target_lane.lane_index])
			levelData.noteDatas.append(data)
			preview.set_data(data)
			target_lane.add_note(preview)
			preview = null
		current_state = EditorState.Ready

func get_snapped_x(mouse_x: float) -> float:
	if bit == 0:
		return mouse_x
	
	var time = Setting.get_time_from_posx(mouse_x)
	
	var bpm = levelData.bpm[0].y
	var bpm_start_time = levelData.bpm[0].x
	for i in range(levelData.bpm.size() - 1):
		if time >= levelData.bpm[i].x and time < levelData.bpm[i + 1].x:
			bpm = levelData.bpm[i].y
			bpm_start_time = levelData.bpm[i].x
			break
	
	var beat_duration = 60000.0 / bpm
	var snap_duration = beat_duration * 4.0 / bit
	
	var elapsed = time - bpm_start_time
	var snapped_time = bpm_start_time + round(elapsed / snap_duration) * snap_duration
	
	return Setting.get_posx_from_time(snapped_time)

# ======================== Testing ===================================

func print_lane_info():
	for lane in levelData.lanes:
		print("LANE INDEX %d" % lane.lane_index)
		for keyframe in lane.keyframes:
			print("my lane's keyframe: time %f and height %f" % [keyframe.x, keyframe.y])

# ======================== Save Chart ================================

var save_difficulty = -1
var music_path = ""

func open_save_panel():
	editor_ready = false
	savePanel.visible = true
	if (chart_loaded):
		savePanel.get_node("OnlyForNewSave").visible = false
		savePanel.get_node("OnlyForLoaded").visible = true
		savePanel.get_node("OnlyForLoaded/Label").text = "Do you want to save %s %s?" % [levelData.name, Setting.DIFFICULTY_NAMES[save_difficulty]]

func quit_save_panel():
	savePanel.visible = false
	editor_ready = true

func save_chart():
	if (!chart_loaded):
		if save_difficulty == -1:
			savePanel.get_node("WarningLabel").text = "WARNING: Please set difficulty"
			return
		var folder_name = savePanel.get_node("OnlyForNewSave/LineEdit").text
		if folder_name.is_empty():
			savePanel.get_node("WarningLabel").text = "WARNING: Please set level name"
			return
		
		var dir_path = "res://Charts/" + folder_name
		DirAccess.make_dir_recursive_absolute(dir_path)
		
		# METADATA.txt 저장
		var meta_file = FileAccess.open(dir_path + "/METADATA.txt", FileAccess.WRITE)
		if meta_file == null:
			push_error("ERROR: METADATA.txt를 열 수 없습니다.")
			return
		meta_file.store_line("NAME " + folder_name)
		meta_file.store_line("MUSIC " + levelData.music_path)
		meta_file.store_line("LEVEL 1 2 3")
		meta_file.store_line("LENGTH %d" % levelData.length)
	
		# 음악 파일 저장
		DirAccess.copy_absolute(music_path, dir_path + "/" + levelData.music_path)
		
		var difficulty_name = Setting.DIFFICULTY_NAMES[save_difficulty]
		chart_path = dir_path + "/" + difficulty_name + ".txt"
	
	# 채보 파일 저장

	var file = FileAccess.open(chart_path, FileAccess.WRITE)
	if file == null:
		push_error("ERROR: 채보 파일을 열 수 없습니다.")
		return
	
	# BPM 저장
	for i in range(levelData.bpm.size() - 1):
		file.store_line("BPM %s %s" % [levelData.bpm[i].x, levelData.bpm[i].y])
	
	# LANE 저장
	for lane in levelData.lanes:
		file.store_line("LANE %d %d" % [lane.lane_index, 1 if lane.is_init else 0])
		for kf in lane.keyframes:
			file.store_line("%s %s" % [kf.x, kf.y])
		file.store_line("END")
	
	# 노트 저장
	for note in levelData.noteDatas:
		file.store_line("%f %d %d %f %d" % [note.time, note.color, note.type, note.end_time, note.lane])
	
	quit_save_panel()
	

func set_difficulty(difficulty:int):
	save_difficulty = difficulty
# =============================== Load Chart ==========================
var chart_path
var chart_loaded : bool

func on_push_load_chart_button():
	loadPanel.visible = true
	initialPanel.visible = false
	

func find_chart():
	loadPanel.get_node("FileDialog").popup()

func select_chart(path: String):
	chart_path = path
	var dir = DirAccess.open(path.get_base_dir())
	for file in dir.get_files():
		if file.ends_with(".mp3"):
			music_path = path.get_base_dir() + "/" + file
			print(music_path)
			break
	
	var stream = AudioStreamMP3.new()
	var data = FileAccess.get_file_as_bytes(music_path)
	if (data.is_empty()):
		loadPanel.get_node("MusicLabel").text = "Please set music file with chart file"
		loadPanel.get_node("LoadButton").visible = false
		return
	stream.data = FileAccess.get_file_as_bytes(music_path)

	musicPlayer.stream = stream
	
	levelData = LevelData.new()
	levelData.name = path.get_base_dir().get_file()
	levelData.music_path = music_path.get_file()
	levelData.length = stream.get_length() * 1000
	
	
	match chart_path.get_file():
		Setting.DIFFICULTY_NAMES[0] + ".txt":
			save_difficulty = 0
		Setting.DIFFICULTY_NAMES[1] + ".txt":
			save_difficulty = 1
		Setting.DIFFICULTY_NAMES[2] + ".txt":
			save_difficulty = 2
		_:
			save_difficulty = -1
			
	if (save_difficulty == -1):
		loadPanel.get_node("MusicLabel").text = "Please load chart file with valid name"
		loadPanel.get_node("LoadButton").visible = false
		return
			
	loadPanel.get_node("NameLabel").text = "Chart: " + levelData.name + " " + Setting.DIFFICULTY_NAMES[save_difficulty]
	loadPanel.get_node("MusicLabel").text = "Song: " + levelData.music_path
	loadPanel.get_node("LengthLabel").text = "Length: " + str(levelData.length / 1000)
	loadPanel.get_node("LoadButton").visible = true
	

func finish_load_chart():
	parse(chart_path)
	levelData.bpm.append(Vector2(Setting.INFINITE, 60))
	for bpm in levelData.bpm:
		print("time: %f bpm:%f" % [bpm.x, bpm.y])
	chart_loaded = true
	loadPanel.visible = false
	initiate_editor()
	place_bar_lines()
	

func parse(chart_path: String):
	ChartParser.parse_chart(chart_path, levelData, true)
	for lane in levelData.lanes:
		for i in range(lane.keyframes.size() - 1):
			var start_time = lane.keyframes[i].x
			var end_time = lane.keyframes[i + 1].x
			var start_pos = Vector2(Setting.get_posx_from_time(start_time), lane.keyframes[i].y)
			var end_pos = Vector2(Setting.get_posx_from_time(end_time), lane.keyframes[i + 1].y)
			
			var connector = CONNECTOR_SCENE.instantiate()
			add_child(connector)
			connector.set_editor_color(-1)
			connector.set_data(start_pos, end_pos)
			connector.global_position = start_pos
			lane.add_editor_connector(connector)
			connector.set_lane_index(lane.lane_index)
	
	for noteData in levelData.noteDatas:
		var note: ENote = NOTE_SCENE.instantiate()
		var lane = Lane.find_lane(levelData.lanes, noteData.lane)
		note.set_data(noteData)
		add_child(note)
		note.position = Vector2(Setting.get_posx_from_time(noteData.time), lane.get_height(noteData.time))
		note.set_color(noteData.color)
		lane.add_note(note)

		if (noteData.type == 1):
			var connector_start_x = Setting.get_posx_from_time(noteData.time) + Setting.NOTE_WIDTH / 2.0
			var connector_end_x = Setting.get_posx_from_time(noteData.end_time) - Setting.NOTE_WIDTH / 2.0
			if connector_start_x < connector_end_x:
				var points = [connector_start_x]
				for kf in lane.keyframes:
					if kf.x > noteData.time + Setting.get_time_from_posx(Setting.NOTE_WIDTH) and kf.x < noteData.end_time:
						points.append(Setting.get_posx_from_time(kf.x))
					if kf.x > noteData.end_time:
						break
				points.append(connector_end_x)
				var parent_node = note
				var start_x
				var start_pos
				var end_x
				var end_pos
				for i in range(points.size() - 1):
					start_x = points[i]
					end_x = points[i + 1]
					start_pos = Vector2(start_x, lane.get_height(Setting.get_time_from_posx(start_x)))
					end_pos = Vector2(end_x, lane.get_height(Setting.get_time_from_posx(end_x)))
					
					var longNote_connector = CONNECTOR_SCENE.instantiate()
					parent_node.add_child(longNote_connector)
					longNote_connector.set_editor_color(noteData.color)
					longNote_connector.set_data(start_pos, end_pos)
					longNote_connector.global_position = start_pos
					parent_node = longNote_connector
			
			var marker = NOTE_SCENE.instantiate()
			note.add_child(marker)
			marker.set_color(noteData.color)
			marker.global_position = Vector2(Setting.get_posx_from_time(noteData.end_time), lane.get_height(noteData.end_time))
			

# ================================ 편의 기능 ============================

var music_playing: bool = false
var music_bar

func toggle_music():
	if (!music_playing):
		noteSelectorPanel.get_node("PlayMusicButton").text = "Stop Music"
		music_playing = true
		var initial_pos_x = get_music_start_pos()
		var music_start_time = Setting.get_time_from_posx(initial_pos_x) / 1000
		musicPlayer.play(music_start_time)
		music_bar = put_line(initial_pos_x, true)
		music_bar.get_child(0).modulate = Color(120,120,0)
		music_bar.scale.x = pow(1.2, 2-camera_zoom_level)
	else:
		noteSelectorPanel.get_node("PlayMusicButton").text = "Play Music"
		music_playing = false
		music_bar.queue_free()
		music_bar = null
		musicPlayer.stop()

func get_music_start_pos() -> float:
	var camera_left = camera.global_position.x - get_viewport_rect().size.x / camera.zoom.x / 2
	return max(0.0, camera_left)

func _process(delta:float):
	if (music_bar != null):
		music_bar.global_position.x = Setting.get_posx_from_time(musicPlayer.get_playback_position() * 1000)

func set_target_lane(p_target_lane: Lane):
	target_lane = p_target_lane
	
func find_target_keyframe():
	for lane in levelData.lanes:
		for kf in lane.keyframes:
			var kf_x = Setting.get_posx_from_time(kf.x)
			var kf_y = kf.y
			if abs(mouse_pos.x - kf_x) <= Setting.HALF_CONNECTOR_HEIGHT and \
			   abs(mouse_pos.y - kf_y) <= Setting.HALF_CONNECTOR_HEIGHT:
				return kf
	return null

func find_target_note() -> Variant:
	var camera_left = camera.global_position.x - get_viewport_rect().size.x / camera.zoom.x / 2
	var camera_right = camera.global_position.x + get_viewport_rect().size.x / camera.zoom.x / 2
	
	for noteData in levelData.noteDatas:
		var note_x = Setting.get_posx_from_time(noteData.time)
		if note_x < camera_left or note_x > camera_right:
			continue
		var lane = Lane.find_lane(levelData.lanes, noteData.lane)
		var note_y = lane.get_height(noteData.time)
		
		if noteData.type == 0:  # 단노트
			if abs(mouse_pos.x - note_x) <= Setting.NOTE_WIDTH and \
			   abs(mouse_pos.y - note_y) <= Setting.HALF_CONNECTOR_HEIGHT:
				return find_enote_by_data(lane, noteData)
		else:  # 롱노트
			var end_x = Setting.get_posx_from_time(noteData.end_time)
			if mouse_pos.x >= note_x and mouse_pos.x <= end_x and \
			   abs(mouse_pos.y - note_y) <= Setting.HALF_CONNECTOR_HEIGHT:
				return find_enote_by_data(lane, noteData)
	
	return null

func find_enote_by_data(lane: Lane, target_data: NoteData) -> Variant:
	for note in lane.notes:
		if note.data == target_data:
			return note
	return null
