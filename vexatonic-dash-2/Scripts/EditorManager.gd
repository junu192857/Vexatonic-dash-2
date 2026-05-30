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
	inputHandler.delete_something.connect(_on_delete_something)
	inputHandler.toggle_shifting.connect(_on_toggle_shifting)
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
	$x_axis_bar.size = Vector2(Setting.get_posx_from_time(levelData.length), 6.0)

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
		if (bar != music_bar):
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

var target_keyframe: Keyframe
var keyframe_indicator: ENote
var previous_connector: EConnector
var next_connector: EConnector
var target_note: ENote

var mouse_pos: Vector2
var snapped_x: float
var adjusted_y: float
var shifting: bool

var can_do_something

func _on_select_note(selected: int):
	if (!editor_ready):
		return
	if selected in NoteSelection.values():
		selected_note = selected as NoteSelection
		if inputHandler.put_note.is_connected(_on_put_note):
			inputHandler.put_note.disconnect(_on_put_note)
		if inputHandler.put_note.is_connected(_on_modify):
			inputHandler.put_note.disconnect(_on_modify)
		
		# selected < 20이면 레인/노트, selected > 20이면 modify
		if (selected < 20):
			selected_color = selected % 10 - 1
			inputHandler.put_note.connect(_on_put_note)
		else:
			inputHandler.put_note.connect(_on_modify)
		current_state = EditorState.Ready
		if (preview != null):
			preview.queue_free()
			preview = null
		cleanup_modify_values()
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
			generate_modify_preview()
		else:
			cancel_modify_lane()
			cancel_modify_note()
	else:
		if (preview == null):
			if (check_mouse_in_available_area()):
				preview = generate_preview(selected_note)
		else:
			if (!check_mouse_in_available_area()):
				preview.queue_free()
				preview = null
			else: update_preview(selected_note)

# Modify 과정에서 설정된 값들 전부 초기화.
func cleanup_modify_values():
	can_do_something = false
	target_keyframe = null
	if (keyframe_indicator != null):
		keyframe_indicator.queue_free()
		keyframe_indicator = null
	if (target_note != null):
		target_note.process_color()
		target_note = null
	previous_connector = null
	next_connector = null

#새로운 노트나 레인을 찍기 위한 preview를 이동시키는 함수.
func update_preview(selected: int):
	if (selected == NoteSelection.Nothing):
		return
	if (selected == NoteSelection.Lane):
		if (current_state == EditorState.Ready):
			lane_case = find_lane_placing_case()
			if lane_case == LanePlacingCase.None:
				cancel_put_lane_or_note()
			else: 
				preview.position = get_preview_pos_for_lane(lane_case)
				can_do_something = true
		else:
			if (lane_start_pos.x >= snapped_x):
				cancel_put_lane_or_note()
			else:
				preview.set_data(lane_start_pos, Vector2(snapped_x, lane_start_pos.y if shifting else mouse_pos.y))
				can_do_something = true
	else:
		if (current_state == EditorState.Ready):
			note_case = find_note_placing_available()
			if (!note_case):
				cancel_put_lane_or_note()
			else:
				preview.position = get_preview_pos_for_note()
		else:
			if (!find_longNote_placing_available()):
				cancel_put_lane_or_note()
			else:
				print("REAL snapped_x: %f" % snapped_x)
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
						var kf_x = Setting.get_posx_from_time(kf.kf.x)
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
						existing_connector.z_index = 1
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
					existing_marker.is_marker = true
					existing_marker.set_color(selected_color)
				long_end_time = Setting.get_time_from_posx(existing_marker.global_position.x)
				existing_marker.global_position = Vector2(snapped_x, target_lane.get_height(Setting.get_time_from_posx(snapped_x)))
				
				can_do_something = true
#새로운 노트나 레인을 찍기 위한 preview를 만드는 함수.
func generate_preview(selected: int) -> Node2D:
	if (selected == NoteSelection.Nothing):
		return null
	
	var my_preview = null
	if (selected == NoteSelection.Lane):
		if (current_state == EditorState.Ready):
			lane_case = find_lane_placing_case()
			if lane_case == LanePlacingCase.None:
				cancel_put_lane_or_note()
				return null
			else:
				my_preview = CONNECTOR_SCENE.instantiate()
				add_child(my_preview)
				my_preview.position = get_preview_pos_for_lane(lane_case)
		else:
			if (lane_start_pos.x >= snapped_x):
				cancel_put_lane_or_note()
				return null
			my_preview = CONNECTOR_SCENE.instantiate()
			#lane_start_pos와 현재 mouse_pos로 lane 찍기
			add_child(my_preview)
			my_preview.set_data(lane_start_pos, Vector2(snapped_x, lane_start_pos.y if shifting else mouse_pos.y))
			my_preview.position = lane_start_pos
	else: #Note인 경우
		if (current_state == EditorState.Ready):
			note_case = find_note_placing_available()
			if (!note_case):
				cancel_put_lane_or_note()
				return null
			my_preview = NOTE_SCENE.instantiate()
			add_child(my_preview)
			my_preview.position = get_preview_pos_for_note()
			my_preview.set_color(selected_color)
		else: #Note이고 Placing인 경우: 무조건 LongNote
			if (!find_longNote_placing_available()):
				cancel_put_lane_or_note()
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
					var kf_x = Setting.get_posx_from_time(kf.kf.x)
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
			my_marker.is_marker = true
			my_marker.global_position = Vector2(snapped_x, target_lane.get_height(Setting.get_time_from_posx(snapped_x)))
			my_marker.set_color(selected_color)
			long_end_time = Setting.get_time_from_posx(my_marker.global_position.x)
			
	can_do_something = true
	return my_preview

func generate_modify_preview():
	if (!editor_ready):
		return
	if (current_state == EditorState.Ready):
		match selected_note:
			NoteSelection.ModifyLane:
				var new_target_keyframe = find_target_keyframe()
				if (new_target_keyframe == null):
					cleanup_modify_values()
					return
				if (target_keyframe != new_target_keyframe):
					target_keyframe = new_target_keyframe
					if (keyframe_indicator != null):
						keyframe_indicator.queue_free()
					keyframe_indicator = put_keyframe_indicator()
			NoteSelection.ModifyNote:
				var new_target_note = find_target_note()
				if (new_target_note == null):
					cleanup_modify_values()
					return
				if (target_note != new_target_note):
					if (target_note != null):
						target_note.process_color()
					target_note = new_target_note
					target_note.select_color()
			_:
				push_error("INVALID NOTE SELECTION")
	else:
		match selected_note:
			NoteSelection.ModifyLane:
				#var kf_index = target_lane.keyframes.find(target_keyframe)
				#var prev_kf = target_lane.keyframes[kf_index - 1] if kf_index > 0 else null
				#var next_kf = target_lane.keyframes[kf_index + 1] if kf_index < target_lane.keyframes.size() - 1 else null
				var prev_x = Setting.get_posx_from_time(previous_connector.start_keyframe.kf.x) if previous_connector else -INF
				var next_x = Setting.get_posx_from_time(next_connector.end_keyframe.kf.x) if next_connector else INF
				if not shifting:
					adjusted_y = mouse_pos.y
				else:
					if previous_connector:
						adjusted_y = previous_connector.start_keyframe.kf.y
					elif next_connector:
						adjusted_y = next_connector.end_keyframe.kf.y
				var new_keyframe = Keyframe.new(Setting.get_time_from_posx(snapped_x), adjusted_y)
				new_keyframe.set_lane(target_lane.lane_index)
				if snapped_x > prev_x + Setting.EPSILON and snapped_x < next_x - Setting.EPSILON:
					if previous_connector:
						previous_connector.end_keyframe = new_keyframe
						previous_connector.set_data_from_keyframes()
					if next_connector:
						if (next_connector.visible == false):
							next_connector.visible = true
						next_connector.start_keyframe = new_keyframe
						next_connector.set_data_from_keyframes()
				else:
					cancel_modify_lane()
					return
				if (keyframe_indicator == null):
					keyframe_indicator = put_keyframe_indicator()
				keyframe_indicator.global_position = Vector2(snapped_x, adjusted_y)
			NoteSelection.ModifyNote:
				target_note.select_color()
				
				if target_note.get_data().type == 0:  # 단노트
					note_case = find_note_placing_available()
					if (!find_note_placing_available()):
						cancel_modify_note()
						return
					target_note.global_position = Vector2(snapped_x, target_lane.get_height(Setting.get_time_from_posx(snapped_x)))
				
				elif target_note.get_data().type == 1 and not target_note.is_marker:  # 롱노트 앞부분
					var long_end_x = Setting.get_posx_from_time(target_note.get_data().end_time)
					if (snapped_x >= long_end_x):
						cancel_modify_note()
						return
					if (!find_note_placing_available()):
						cancel_modify_note()
						return
					print("Trying move only parent")
					#target_note.global_position = Vector2(snapped_x, target_lane.get_height(Setting.get_time_from_posx(snapped_x)))
					move_only_parent(target_note, Vector2(snapped_x, target_lane.get_height(Setting.get_time_from_posx(snapped_x))))
					adjust_longNote_connector(target_note, Setting.get_time_from_posx(snapped_x), target_note.get_data().end_time)
				
				else:  # 롱노트 뒷부분
					if (!find_longNote_placing_available()):
						cancel_modify_note()
						return
					target_note.global_position = Vector2(snapped_x, target_lane.get_height(Setting.get_time_from_posx(snapped_x)))
					adjust_longNote_connector(target_note.get_parent(), target_note.get_data().time, Setting.get_time_from_posx(snapped_x))
	can_do_something = true
func cancel_put_lane_or_note():
	if (preview):
		preview.queue_free()
		preview = null
		can_do_something = false

func cancel_modify_lane():
	can_do_something = false
	if (!target_keyframe):
		return
	if (target_keyframe.lane_index != -1):
		if previous_connector:
			previous_connector.end_keyframe = target_keyframe
			previous_connector.set_data_from_keyframes()
		if next_connector:
			next_connector.start_keyframe = target_keyframe
			next_connector.set_data_from_keyframes()
	else:
		if previous_connector:
			previous_connector.end_keyframe = next_connector.end_keyframe
			previous_connector.set_data_from_keyframes()
		if next_connector:
			next_connector.visible = false
	if (keyframe_indicator != null):
		keyframe_indicator.queue_free()
		keyframe_indicator = null

	

func cancel_modify_note():
	can_do_something = false
	if (target_note != null):
		target_note.process_color()
		if (current_state == EditorState.Placing):
			var data = target_note.get_data()
			if (data.type == 0):
				target_note.global_position = Vector2(Setting.get_posx_from_time(data.time), target_lane.get_height(data.time))
			elif (target_note.is_marker):
				target_note.global_position = Vector2(Setting.get_posx_from_time(data.end_time), target_lane.get_height(data.end_time))
				adjust_longNote_connector(target_note.get_parent(), data.time, data.end_time)
			else:
				move_only_parent(target_note, Vector2(Setting.get_posx_from_time(data.time), target_lane.get_height(data.time)))
				adjust_longNote_connector(target_note, data.time, data.end_time)

func put_keyframe_indicator():
	var indicator = NOTE_SCENE.instantiate()
	add_child(indicator)
	indicator.global_position = Vector2(Setting.get_posx_from_time(target_keyframe.kf.x), target_keyframe.kf.y)
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

func find_lane_placing_case() -> LanePlacingCase:
	#if (!check_mouse_in_available_area(mouse_pos)):
	#	return LanePlacingCase.None
	var camera_left = camera.global_position.x - get_viewport_rect().size.x / 2

	# Case 2 우선 체크: 레인 위에 마우스가 있는 경우
	for lane in levelData.lanes:
		var lane_x_start = Setting.get_posx_from_time(lane.keyframes[0].kf.x)
		var lane_x_end = Setting.get_posx_from_time(lane.keyframes[-1].kf.x)
		if snapped_x >= lane_x_start and mouse_pos.x > lane_x_start and snapped_x < lane_x_end and mouse_pos.x <= lane_x_end:
			var lane_y = lane.get_height(Setting.get_time_from_posx(mouse_pos.x))
			if abs(lane_y - mouse_pos.y) <= Setting.HALF_CONNECTOR_HEIGHT:
				set_target_lane(lane)
				return LanePlacingCase.Case2

	# Case 3 체크
	var closest_lane: Lane = null
	var closest_dist: float = Setting.INFINITE

	for lane in levelData.lanes:
		var lane_x_end = Setting.get_posx_from_time(lane.keyframes[-1].kf.x)
		if mouse_pos.x > lane_x_end:
			if camera_left < lane_x_end:
				var lane_y_end = lane.keyframes[-1].kf.y
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

func find_note_placing_available() -> bool:
	for lane in levelData.lanes:
		var lane_x_start = Setting.get_posx_from_time(lane.keyframes[0].kf.x)
		var lane_x_end = Setting.get_posx_from_time(lane.keyframes[-1].kf.x)
		if (lane_x_start - snapped_x < Setting.EPSILON):
			snapped_x += Setting.EPSILON
		elif (snapped_x - lane_x_end < Setting.EPSILON):
			snapped_x -= Setting.EPSILON
		if snapped_x >= lane_x_start and snapped_x <= lane_x_end:
			var lane_y = lane.get_height(Setting.get_time_from_posx(snapped_x))
			if abs(lane_y - mouse_pos.y) <= Setting.HALF_CONNECTOR_HEIGHT:
				set_target_lane(lane)
				return true
	
	return false

func find_longNote_placing_available() -> bool:
	print("Finding..")
	if (long_start_pos.x >= snapped_x):
		return false
	var lane_x_end = Setting.get_posx_from_time(target_lane.keyframes[-1].kf.x)
	if (snapped_x - lane_x_end < Setting.EPSILON):
		snapped_x -= Setting.EPSILON
		print("Adjusted snapped_x. new x is %f and new time is %f" % [snapped_x, Setting.get_time_from_posx(snapped_x)])
	if (snapped_x > lane_x_end):
		return false
	return true

# Ready 단계에서 Lane의 preview의 위치 구하기.
func get_preview_pos_for_lane(case: LanePlacingCase) -> Vector2:
	if (case == LanePlacingCase.Case1):
		return Vector2(0, mouse_pos.y)
	elif (case == LanePlacingCase.Case2):
		return Vector2(snapped_x, target_lane.get_height(Setting.get_time_from_posx(snapped_x)))
	elif (case == LanePlacingCase.Case3):
		return Vector2(Setting.get_posx_from_time(target_lane.keyframes[-1].kf.x),target_lane.keyframes[-1].kf.y)
	return Vector2.ZERO
	
func get_preview_pos_for_note() -> Vector2:
	return Vector2(snapped_x, target_lane.get_height(Setting.get_time_from_posx(snapped_x)))

func _on_put_note():
	if !editor_ready or !can_do_something or !check_mouse_in_available_area():
		return
	if current_state == EditorState.Ready:
		_on_put_note_ready()
	else:
		_on_put_note_placing()

func _on_put_note_ready():
	if selected_note == NoteSelection.Lane:
		lane_start_pos = preview.global_position
		current_state = EditorState.Placing
	elif selected_note / 10 == 0:  # 단노트
		_place_single_note()
	elif selected_note / 10 == 1:  # 롱노트
		long_start_pos = preview.global_position
		current_state = EditorState.Placing

func _on_put_note_placing():
	if selected_note == NoteSelection.Lane:
		_place_lane()
	else:
		_place_long_note()
	current_state = EditorState.Ready

func _place_single_note():
	var data = NoteData.new(Setting.get_time_from_posx(preview.global_position.x), selected_color, 0, 0, target_lane.lane_index)
	levelData.noteDatas.append(data)
	preview.set_data(data)
	target_lane.add_note(preview)
	preview = null

func _place_long_note():
	var data = NoteData.new(Setting.get_time_from_posx(preview.global_position.x), selected_color, 1, long_end_time, target_lane.lane_index)
	levelData.noteDatas.append(data)
	preview.set_data(data)
	target_lane.add_note(preview)
	preview = null

func _place_lane():
	match lane_case:
		LanePlacingCase.Case1: _place_lane_case1()
		LanePlacingCase.Case2: _place_lane_case2()
		LanePlacingCase.Case3: _place_lane_case3()
	preview = null
	lane_case = LanePlacingCase.None
	
func _place_lane_case1():
	print("CASE 1 ACTIVATED")
	var new_index = Lane.find_free_index(levelData.lanes)
	var new_lane = Lane.new(new_index, true)
	var new_start_keyframe = Keyframe.new(0, lane_start_pos.y)
	var new_end_keyframe = Keyframe.new(Setting.get_time_from_posx(preview.get_end_pos(lane_start_pos).x), preview.get_end_pos(lane_start_pos).y)
	new_start_keyframe.set_lane(new_index)
	new_end_keyframe.set_lane(new_index)
	new_lane.add_keyframe(new_start_keyframe)
	new_lane.add_keyframe(new_end_keyframe)
	print("New initial line added with initial y %f and next y %f" % [lane_start_pos.y, preview.get_end_pos(lane_start_pos).y ])
	levelData.lanes.append(new_lane)
	new_lane.add_editor_connector(preview)
	preview.set_editor_values(new_lane, new_start_keyframe, new_end_keyframe)

func _place_lane_case2():
	print("CASE 2 ACTIVATED")
	var new_index = Lane.find_free_index(levelData.lanes)
	var new_lane = Lane.new(new_index, false)
	var new_start_keyframe = Keyframe.new(Setting.get_time_from_posx(lane_start_pos.x), lane_start_pos.y)
	var new_end_keyframe = Keyframe.new(Setting.get_time_from_posx(preview.get_end_pos(lane_start_pos).x), preview.get_end_pos(lane_start_pos).y)
	new_start_keyframe.set_lane(new_index)
	new_end_keyframe.set_lane(new_index)
	new_lane.add_keyframe(new_start_keyframe)
	new_lane.add_keyframe(new_end_keyframe)
	print("New initial line added with initial y %f and next y %f" % [lane_start_pos.y,preview.get_end_pos(lane_start_pos).y ])
	levelData.lanes.append(new_lane)
	new_lane.add_editor_connector(preview)
	preview.set_editor_values(new_lane, new_start_keyframe, new_end_keyframe)

func _place_lane_case3():
	print("CASE 3 ACTIVATED")
	var new_end_keyframe = Keyframe.new(Setting.get_time_from_posx(preview.get_end_pos(lane_start_pos).x), preview.get_end_pos(lane_start_pos).y)
	new_end_keyframe.set_lane(target_lane.lane_index)
	print("Lane %d: added new keyframe with y %f" % [target_lane.lane_index, preview.get_end_pos(lane_start_pos).y])
	target_lane.add_editor_connector(preview)
	preview.set_editor_values(target_lane, target_lane.keyframes[-1], new_end_keyframe)
	target_lane.add_keyframe(new_end_keyframe)

func _on_modify():
	print("Hello from modify")
	if !editor_ready or !check_mouse_in_available_area() or !can_do_something:
		return
	match current_state:
		EditorState.Ready:
			_on_modify_ready()
		EditorState.Placing:
			_on_modify_placing()

func _on_modify_ready():
	if (selected_note == NoteSelection.ModifyLane):
		print("Target lane index: %d" % target_lane.lane_index)
		if target_keyframe.lane_index == -1:  # Adding new keyframe
			# 1. previous_connector 찾기
			print("Finding previous connector..")
			for connector in target_lane.editor_connectors:
				var conn_start_x = Setting.get_posx_from_time(connector.start_keyframe.kf.x)
				var target_x = Setting.get_posx_from_time(target_keyframe.kf.x)
				if conn_start_x < target_x:
					if previous_connector == null or conn_start_x > Setting.get_posx_from_time(previous_connector.start_keyframe.kf.x):
						previous_connector = connector
	
			if previous_connector == null:
				push_error("previous_connector를 찾을 수 없습니다.")
				return
	
			# 2. previous_connector의 end_keyframe을 target_keyframe으로 바꾸기
			var old_end_keyframe = previous_connector.end_keyframe
			previous_connector.end_keyframe = target_keyframe
			previous_connector.set_data_from_keyframes()
			# 3. next_connector 새로 만들기
			next_connector = CONNECTOR_SCENE.instantiate()
			add_child(next_connector)
			next_connector.set_editor_values(target_lane, target_keyframe, old_end_keyframe)
			next_connector.set_data_from_keyframes()
			
			current_state = EditorState.Placing
		else:
			for connector in target_lane.editor_connectors:
				if connector.end_keyframe == target_keyframe:
					previous_connector = connector
					print("Set previous connector")
				if connector.start_keyframe == target_keyframe:
					next_connector = connector
					print("Set end connector")
			current_state = EditorState.Placing
		
	elif (selected_note == NoteSelection.ModifyNote):
		current_state = EditorState.Placing
		#이 시점에서 target_lane, target_note 전부 결정 완료
	else:
		push_error("Please select Modify button")

func _on_modify_placing():
	if selected_note == NoteSelection.ModifyLane:
		if (target_keyframe.lane_index == -1):
			# 1. target_keyframe을 현재 마우스 위치로 수정 (in-place, to preserve connector references)
			target_keyframe.kf = Vector2(Setting.get_time_from_posx(snapped_x), adjusted_y)
			previous_connector.end_keyframe = target_keyframe
			previous_connector.set_data_from_keyframes()
			next_connector.start_keyframe = target_keyframe
			next_connector.set_data_from_keyframes()
			target_lane.insert_editor_connector(next_connector)
			target_lane.insert_keyframe(target_keyframe)
		else:
			target_keyframe.kf = Vector2(Setting.get_time_from_posx(snapped_x), adjusted_y)
			if previous_connector:
				previous_connector.end_keyframe = target_keyframe
				previous_connector.set_data_from_keyframes()
			if next_connector:
				next_connector.start_keyframe = target_keyframe
				next_connector.set_data_from_keyframes()
		adjust_note_position()
	elif selected_note == NoteSelection.ModifyNote:
		if (target_note.get_data().type == 0):
			target_note.get_data().time = Setting.get_time_from_posx(snapped_x)
		elif target_note.get_data().type == 1 and not target_note.is_marker:
			target_note.get_data().time = Setting.get_time_from_posx(snapped_x)
			adjust_longNote_connector(target_note, target_note.get_data().time, target_note.get_data().end_time)
		else:
			var head = target_note.get_parent()
			head.get_data().end_time = Setting.get_time_from_posx(snapped_x)
			adjust_longNote_connector(head, target_note.get_data().time, target_note.get_data().end_time)
		target_note.process_color()
	else:
		push_error("Please select Modify button")
		return
	cleanup_modify_values()
	current_state = EditorState.Ready

func _on_delete_something():
	if (!editor_ready or current_state != EditorState.Placing):
		return
	match selected_note:
		NoteSelection.ModifyLane:
			if (target_keyframe.lane_index == -1):
				cancel_modify_lane()
			else:  # 기존 keyframe 삭제
				if previous_connector == null:
		# 레인의 첫 번째 keyframe: next_connector 삭제, 레인 시작점을 next_connector의 end_keyframe으로
					target_lane.keyframes.erase(target_keyframe)
					target_lane.editor_connectors.erase(next_connector)
					next_connector.queue_free()
					next_connector = null
				elif next_connector == null:
					# 레인의 마지막 keyframe: previous_connector 삭제, 레인 끝점을 previous_connector의 start_keyframe으로
					target_lane.keyframes.erase(target_keyframe)
					target_lane.editor_connectors.erase(previous_connector)
					previous_connector.queue_free()
					previous_connector = null
				else:
					# 중간 keyframe: previous_connector의 end_keyframe을 next_connector의 end_keyframe으로
					previous_connector.end_keyframe = next_connector.end_keyframe
					previous_connector.set_data_from_keyframes()
					target_lane.keyframes.erase(target_keyframe)
					target_lane.editor_connectors.erase(next_connector)
					next_connector.queue_free()
					next_connector = null
				if target_lane.keyframes.size() <= 1:
					# lane에 속한 editor_connectors 모두 삭제
					for connector in target_lane.editor_connectors:
						connector.queue_free()
					target_lane.editor_connectors.clear()
					levelData.lanes.erase(target_lane)
			adjust_note_position()
		NoteSelection.ModifyNote:
			var noteData = target_note.get_data()
			
			if target_note.is_marker:
				# 롱노트 뒷부분인 경우 앞부분을 구해서 삭제
				var front_note = target_note.get_parent()
				levelData.noteDatas.erase(noteData)
				target_lane.notes.erase(front_note)
				front_note.queue_free()  # 앞부분 삭제 시 자식(connector, marker)도 같이 삭제됨
			else:
				levelData.noteDatas.erase(noteData)
				target_lane.notes.erase(target_note)
				target_note.queue_free()  # 단노트 또는 롱노트 앞부분 삭제 시 자식도 같이 삭제됨
		_:
			push_error("Please select modify button")
			return
	cleanup_modify_values()
	current_state = EditorState.Ready

func adjust_note_position():
	var lane_start_time = target_lane.keyframes[0].kf.x
	var lane_end_time = target_lane.keyframes[-1].kf.x
	
	# 1. keyframe이 하나 남은 경우 모든 노트 삭제
	if target_lane.keyframes.size() <= 1:
		for note in target_lane.notes:
			levelData.noteDatas.erase(note.get_data())
			note.queue_free()
		target_lane.notes.clear()
		return
	
	var notes_to_remove = []
	for note in target_lane.notes:
		var noteData = note.get_data()
		var should_remove = false
		
		if noteData.type == 0:  # 단노트
			if noteData.time < lane_start_time or noteData.time > lane_end_time:
				should_remove = true
			else:
				note.position.y = target_lane.get_height(noteData.time)
		else:  # 롱노트
			if noteData.time < lane_start_time or noteData.time > lane_end_time or \
			   noteData.end_time < lane_start_time or noteData.end_time > lane_end_time:
				should_remove = true
			else:
				adjust_longNote_connector(note, noteData.time, noteData.end_time)
		
		if should_remove:
			notes_to_remove.append(note)
	
	for note in notes_to_remove:
		levelData.noteDatas.erase(note.get_data())
		target_lane.notes.erase(note)
		note.queue_free()
		
func adjust_longNote_connector(note: ENote, start_time: float, end_time: float):
	if (note.get_data().type != 1):
		push_error("Sorry, this is not a long note")
		return
	
	note.position.y = target_lane.get_height(start_time)
	
	var marker
	# 기존 connector 체인 삭제
	for child in note.get_children():
		if child is EConnector:
			child.queue_free()
		elif child is ENote:
			marker = child
	
	# connector 새로 찍기
	var connector_start_x = Setting.get_posx_from_time(start_time) + Setting.NOTE_WIDTH / 2.0
	var connector_end_x = Setting.get_posx_from_time(end_time) - Setting.NOTE_WIDTH / 2.0
	if connector_start_x < connector_end_x:
		var points = [connector_start_x]
		for kf in target_lane.keyframes:
			if kf.kf.x > start_time + Setting.get_time_from_posx(Setting.NOTE_WIDTH) and kf.kf.x < end_time:
				points.append(Setting.get_posx_from_time(kf.kf.x))
			if kf.kf.x > end_time:
				break
		points.append(connector_end_x)
		var parent_node = note
		for i in range(points.size() - 1):
			var start_x = points[i]
			var end_x = points[i + 1]
			var start_pos = Vector2(start_x, target_lane.get_height(Setting.get_time_from_posx(start_x)))
			var end_pos = Vector2(end_x, target_lane.get_height(Setting.get_time_from_posx(end_x)))
			var longNote_connector = CONNECTOR_SCENE.instantiate()
			parent_node.add_child(longNote_connector)
			longNote_connector.set_editor_color(note.get_data().color)
			longNote_connector.set_data(start_pos, end_pos)
			longNote_connector.global_position = start_pos
			parent_node = longNote_connector
		for child in note.get_children():
			if child is EConnector:
				child.z_index = 1
	#marker y좌표 조정
	marker.global_position.y = target_lane.get_height(end_time)

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
			print("my lane's keyframe: time %f and height %f" % [keyframe.kf.x, keyframe.kf.y])

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
			file.store_line("%s %s" % [kf.kf.x, kf.kf.y])
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
			var start_time = lane.keyframes[i].kf.x
			var start_pos = Vector2(Setting.get_posx_from_time(start_time), lane.keyframes[i].kf.y)
			
			var connector = CONNECTOR_SCENE.instantiate()
			add_child(connector)
			connector.set_editor_color(-1)
			connector.set_editor_values(lane, lane.keyframes[i], lane.keyframes[i+1])
			connector.set_data_from_keyframes()
			connector.global_position = start_pos
			lane.add_editor_connector(connector)
			
	
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
					if kf.kf.x > noteData.time + Setting.get_time_from_posx(Setting.NOTE_WIDTH) and kf.kf.x < noteData.end_time:
						points.append(Setting.get_posx_from_time(kf.kf.x))
					if kf.kf.x > noteData.end_time:
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
			marker.is_marker = true
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

func _process(_delta:float):
	if (music_bar != null):
		music_bar.global_position.x = Setting.get_posx_from_time(musicPlayer.get_playback_position() * 1000)

func set_target_lane(p_target_lane: Lane):
	target_lane = p_target_lane
	
func find_target_keyframe():
	# 1. 기존 keyframe 근처에 있는지 먼저 체크
	for lane in levelData.lanes:
		for kf in lane.keyframes:
			var kf_x = Setting.get_posx_from_time(kf.kf.x)
			var kf_y = kf.kf.y
			if abs(mouse_pos.x - kf_x) <= Setting.HALF_CONNECTOR_HEIGHT and \
			   abs(mouse_pos.y - kf_y) <= Setting.HALF_CONNECTOR_HEIGHT:
				set_target_lane(lane)
				return kf
	
	# 2. 레인 위에 있지만 keyframe 근처는 아닌 경우 -> 새로운 keyframe 생성
	for lane in levelData.lanes:
		var lane_x_start = Setting.get_posx_from_time(lane.keyframes[0].kf.x)
		var lane_x_end = Setting.get_posx_from_time(lane.keyframes[-1].kf.x)
		if snapped_x >= lane_x_start and mouse_pos.x > lane_x_start and snapped_x < lane_x_end and mouse_pos.x <= lane_x_end:
			var lane_y = lane.get_height(Setting.get_time_from_posx(snapped_x))
			if abs(lane_y - mouse_pos.y) <= Setting.HALF_CONNECTOR_HEIGHT:
				set_target_lane(lane)
				var new_kf = Keyframe.new(Setting.get_time_from_posx(snapped_x), lane_y)
				return new_kf
	
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
				target_lane = lane
				return find_enote_by_data(lane, noteData)
		else:  # 롱노트
			var end_x = Setting.get_posx_from_time(noteData.end_time)
			var end_y = lane.get_height(noteData.end_time)
			if abs(mouse_pos.x - note_x) <= Setting.NOTE_WIDTH and \
			   abs(mouse_pos.y - note_y) <= Setting.HALF_CONNECTOR_HEIGHT:
				target_lane = lane
				return find_enote_by_data(lane, noteData)
			elif abs(mouse_pos.x - end_x) <= Setting.NOTE_WIDTH and \
				 abs(mouse_pos.y - end_y) <= Setting.HALF_CONNECTOR_HEIGHT:
				target_lane = lane
				return find_enote_by_data(lane, noteData).get_marker()
	
	return null

func find_enote_by_data(lane: Lane, target_data: NoteData) -> Variant:
	for note in lane.notes:
		if note.get_data() == target_data:
			return note
	return null
	
func move_only_parent(parent: Node2D, pos: Vector2):
	var saved_positions = []
	var fixed_children = []
	
	for child in parent.get_children():
		if child is EConnector or child is ENote:
			saved_positions.append(child.global_position)
			fixed_children.append(child)
	
	parent.global_position = pos
	
	for i in range(fixed_children.size()):
		fixed_children[i].global_position = saved_positions[i]

func _on_toggle_shifting(pressed: bool):
	shifting = pressed
	_on_move_preview()
