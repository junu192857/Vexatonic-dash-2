extends Node2D

var levelData: LevelData

@export var CHARACTER_SCENE: PackedScene
@onready var musicPlayer = $AudioStreamPlayer
@onready var cameraManager = $CameraManager
@onready var camera = $CameraManager/Camera2D
@onready var line = $CharacterHolder/Line
@onready var lineSprite = $CharacterHolder/Line/Sprite2D
@onready var character_holder:Node2D = $CharacterHolder

var characters: Array[Character]

var time: float
var need_refresh_tutorial: bool = true
var started_tutorial: bool = false
var music_started = false
var game_finished = false
var time_start_tick: float
var music_start_tick: float
#어느 레인까지 캐릭터가 생성되었는지 체크하는 용도
var lane_index: int

var noteHolders: Array[NoteHolder]

const COUNTDOWN_TIME = 3000
var level_path: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# ==== Parsing & Lanes, NoteDatas 정렬
	InputManager.pressed_a.connect(func(): _on_pressed(0, true))
	InputManager.released_a.connect(func(): _on_released(0, true))
	InputManager.pressed_l.connect(func(): _on_pressed(0, false))
	InputManager.released_l.connect(func(): _on_released(0, false))
	InputManager.pressed_s.connect(func(): _on_pressed(1, true))
	InputManager.released_s.connect(func(): _on_released(1, true))
	InputManager.pressed_k.connect(func(): _on_pressed(1, false))
	InputManager.released_k.connect(func(): _on_released(1, false))
	InputManager.pressed_d.connect(func(): _on_pressed(2, true))
	InputManager.released_d.connect(func(): _on_released(2, true))
	InputManager.pressed_j.connect(func(): _on_pressed(2, false))
	InputManager.released_j.connect(func(): _on_released(2, false))
	InputManager.pressed_space.connect(func(): _on_pressed(3, true))
	
	level_path = "res://Charts/Tutorial" if Setting.is_tutorial else Setting.selected_chart_dir 
	
	for i in range(4):
		noteHolders.append(NoteHolder.new(i))
	
	levelData = ChartParser.parse(level_path, 0 if Setting.is_tutorial else Setting.selected_difficulty)
	$IngameDataManager.set_total_notes(levelData.noteDatas)
	$IngameDataManager.all_notes_cleared.connect(end_game, CONNECT_ONE_SHOT)
	Lane.sort_lanes(levelData.lanes)
	lane_index = 0
	
	levelData.sort_noteDatas()
	levelData.sort_triggers()
	# Speed 트리거 세팅 (render_chart 전에 해야 위치 계산이 올바름)
	var speed_trigs = levelData.triggers.filter(func(t): return t.type == Trigger.TYPE.Speed)
	speed_trigs.sort_custom(func(a, b): return a.start < b.start)
	PositionCalculator.setup(speed_trigs.map(func(t): return {time = t.start, speed = t.c}))
	# 채보 찍기
	render_chart()
	sort_note_holders()
	
	if Setting.judge_offset != 0.0:
		for noteData in levelData.noteDatas:
			noteData.time -= Setting.judge_offset
			noteData.end_time -= Setting.judge_offset
	
	cameraManager.set_triggers(levelData.triggers)
	var stream = AudioStreamMP3.new()
	stream.data = FileAccess.get_file_as_bytes(level_path + "/" +  levelData.metadata.music_path)
	musicPlayer.stream = stream
	if Setting.is_tutorial:
		musicPlayer.volume_db = -80.0
	
		
	
	# 초기 캐릭터 및 판정선 생성
	if (Setting.gamemode != Setting.GAMEMODE.Normal_Character):
		$CharacterHolder/Line.visible = true
	for lane in levelData.lanes:
		if (lane.is_init):
			place_character(lane)
			lane_index += 1
	
	
	time_start_tick = Time.get_ticks_msec()

func place_character(lane: Lane):
	if (Setting.gamemode != Setting.GAMEMODE.Normal_Character):
		return
	var character = CHARACTER_SCENE.instantiate() as Character
	character.set_lane(lane)
	lane.character = character
	characters.append(character)
	character_holder.add_child(character)

	
func _physics_process(delta: float) -> void:
	if (not game_finished):
		if (not music_started):
			if (Setting.is_tutorial and Time.get_ticks_msec() - time_start_tick > 1000.0 and need_refresh_tutorial):
				time_start_tick = Time.get_ticks_msec()
				need_refresh_tutorial = false
			time = Time.get_ticks_msec() - time_start_tick - COUNTDOWN_TIME
			if time >= Setting.sound_offset:
				musicPlayer.play()
				music_start_tick = Time.get_ticks_msec()
				music_started = true
		else:
			time = musicPlayer.get_playback_position() * 1000 + Setting.sound_offset
		
		if (lane_index < levelData.lanes.size() and levelData.lanes[lane_index].get_start_time() < time):
			place_character(levelData.lanes[lane_index])
			lane_index += 1
			
		character_holder.position = Vector2(PositionCalculator.get_posx_from_time_fast(time), cameraManager.position.y)
		if (Setting.gamemode != Setting.GAMEMODE.Normal_Character):
			lineSprite.scale = Vector2(0.01, 6.0) / camera.zoom.y
		for character in characters:
			if character.set_character_position(time):
				characters.erase(character)
		
		for holder in noteHolders:
			holder.check_miss(time)
			holder.update_visuals(time)

		cameraManager.move(time)
	

func sort_note_holders():
	for holder in noteHolders:
		holder.sort_notes()

#============================== Chart Rendering ===================================

@export var NOTE_SCENE: PackedScene
@export var LONG_NOTE_SCENE: PackedScene
@export var CONNECTOR_SCENE: PackedScene
@export var SUREGI_CONNECTOR_SCENE: PackedScene
@export var ARC_CONNECTOR_SCENE: PackedScene

# render_chart() 후 생성된 Note, Connector, Marker의 관계
#
#			   /‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\									 /‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\
#             /						  \									/						  \
# RhythmScene --- Note --- Connector   NextNote---Connector    LongNote---Connector(롱놋틱) Marker Connector
#			  \								   					/	    \__________________/
#			   \_______________________________________________/


func render_chart():
	var pos_x
	var previous_time = -1
	var previous_note
	var previous_lane = -1
	for noteData in levelData.noteDatas:
		pos_x = PositionCalculator.get_posx_from_time(noteData.time)
		var cur_note = place_note(noteData, pos_x, false, self)
		assign_note(cur_note)
		if (previous_time >= 0 and previous_lane == noteData.lane):
			var prev_conn_start = PositionCalculator.get_time_from_posx(PositionCalculator.get_posx_from_time(previous_time) + Setting.NOTE_WIDTH / 2.0)
			var prev_conn_end = PositionCalculator.get_time_from_posx(PositionCalculator.get_posx_from_time(noteData.time) - Setting.NOTE_WIDTH / 2.0)
			if (Setting.gamemode == Setting.GAMEMODE.Suregi):
				var connector = place_suregi_connector(previous_note.data.color, prev_conn_start, prev_conn_end, \
							previous_lane, true, previous_note, Vector2(Setting.NOTE_WIDTH / 2.0, 0))
			else:
				var connector = place_connector(-1, prev_conn_start, prev_conn_end, \
							previous_lane, true, previous_note, Vector2(Setting.NOTE_WIDTH / 2.0, 0))
	
		previous_time = noteData.time
		previous_lane = noteData.lane
		previous_note = cur_note;
	
		if (noteData.type == 1): #LongNote
			var end_pos_x = PositionCalculator.get_posx_from_time(noteData.end_time)
			var marker = place_note(noteData, end_pos_x, true, cur_note)
			var connector = place_connector(noteData.color, \
							PositionCalculator.get_time_from_posx(PositionCalculator.get_posx_from_time(noteData.time) + Setting.NOTE_WIDTH / 2.0), \
							PositionCalculator.get_time_from_posx(PositionCalculator.get_posx_from_time(noteData.end_time) - Setting.NOTE_WIDTH / 2.0), \
							previous_lane, true, cur_note, Vector2(Setting.NOTE_WIDTH / 2.0, 0))
			(cur_note as LongNote).set_target_connector(connector as Connector)
			previous_time = noteData.end_time
			previous_note = marker
		
		elif (noteData.type == 2): #JumpNote
			var end_pos_x = PositionCalculator.get_posx_from_time(noteData.end_time)
			match Setting.gamemode:
				Setting.GAMEMODE.Normal_Character:
					var marker = place_note(noteData, end_pos_x, true, cur_note)
					# TODO: ARC_CONNECTOR_SCENE으로 Connector 만들기
					previous_time = noteData.end_time
					previous_note = marker
				Setting.GAMEMODE.Normal_Line:
					var marker = place_note(noteData, end_pos_x, true, cur_note)
					previous_time = noteData.end_time
					previous_note = marker
				Setting.GAMEMODE.Suregi:
					pass # previous_time/note를 점프 노트 시작으로 유지 → 다음 노트와 직선 연결
			
	for lane:Lane in levelData.lanes:
		#lane.print_data()
		lane.sort_notes()
		place_initial_connector(lane)
		place_final_connector(lane)

# 단노트, 롱노트 시작점 밑 끝점 생성
func place_note(data:NoteData, pos_x: float, p_is_marker:bool, parent: Node2D) -> Note:
	var note = (LONG_NOTE_SCENE if not p_is_marker and data.type == 1 else NOTE_SCENE).instantiate()
	note.set_data(data)
	note.is_marker = p_is_marker
	var lane = Lane.find_lane(levelData.lanes, data.lane)
	parent.add_child(note)
	note.select_color()
	if !p_is_marker:
		note.global_position = Vector2(pos_x, lane.get_height(data.time))
		if data.adjusted == 1:
			note.set_line()
		lane.adjust_keyframe(data.time, note.global_position.y)
	else:
		note.global_position = Vector2(pos_x, lane.get_height(data.end_time))
		lane.adjust_keyframe(data.end_time, note.global_position.y)
	return note

# 해당 Connector가 단노트 또는 Marker 뒤에 처음 나오는 Connector인 경우 first = true, 그 외의 경우 first = false
func place_connector(p_color:int, start_time: float, end_time: float, lane: int, first: bool, parent:Node2D, p_pos:Vector2):
	var connector
	if (end_time - start_time <= 0):
		return
	connector = CONNECTOR_SCENE.instantiate() as Node2D
	var initial_end_time = connector.set_connector_data(p_color, start_time, end_time, Lane.find_lane(levelData.lanes, lane), first)

	# 하나의 Connector 안에서 레인이 꺾이는 경우: 꺾이는 지점부터 새로운 Connector 생성
	if (end_time - initial_end_time > Setting.EPSILON):
		var following_connector = place_connector(p_color, initial_end_time, end_time, lane, false,\
								  connector, Vector2(connector.data.length, connector.data.delta_y))

	parent.add_child(connector)
	connector.position = p_pos
	if (p_color > -1):
		connector.z_index = 1
	return connector

func place_suregi_connector(p_color: int, start_time: float, end_time: float, lane: int, first: bool, parent:Node2D, p_pos:Vector2):
	var connector
	if (end_time - start_time <= 0):
		return
	connector = SUREGI_CONNECTOR_SCENE.instantiate() as Node2D
	connector.set_connector_data(p_color, start_time, end_time, Lane.find_lane(levelData.lanes, lane), first)
	parent.add_child(connector)
	connector.position = p_pos
	return connector
	
# 레인의 첫 번째 노트 이전의 Connector 생성. 첫 번째 노트가 없으면 패스
func place_initial_connector(lane: Lane):
	var start_time = -2 * COUNTDOWN_TIME if lane.is_init else lane.keyframes[0].kf.x
	var end_time = PositionCalculator.get_time_from_posx(PositionCalculator.get_posx_from_time(lane.notes[0].get_data().time) - Setting.NOTE_WIDTH / 2.0) if !lane.notes.is_empty() else lane.keyframes[-1].kf.x
	if (Setting.gamemode == Setting.GAMEMODE.Suregi):
		place_suregi_connector(-1, start_time, end_time, lane.lane_index, false, self, Vector2(PositionCalculator.get_posx_from_time(start_time),lane.keyframes[0].kf.y))
	else:
		place_connector(-1, start_time, end_time, lane.lane_index, false, self, Vector2(PositionCalculator.get_posx_from_time(start_time),lane.keyframes[0].kf.y))
	

# 레인의 마지막 노트 이후의 Connector 생성 또는 노트가 없는 레인의 Connector 생성
func place_final_connector(lane: Lane):
	if (!lane.notes.is_empty()):
		var last_note_time = lane.notes[-1].get_data().end_time #find last note or marker
		var connector_time = PositionCalculator.get_time_from_posx(PositionCalculator.get_posx_from_time(last_note_time) + Setting.NOTE_WIDTH / 2.0)
		if lane.keyframes[-1].kf.x > connector_time:
			if (Setting.gamemode == Setting.GAMEMODE.Suregi):
				var final_connector = place_suregi_connector(-1, connector_time, lane.keyframes[-1].kf.x, lane.lane_index, true,\
								  self,  Vector2(PositionCalculator.get_posx_from_time(connector_time), lane.get_height(last_note_time)))
			else:
				var final_connector = place_connector(-1, connector_time, lane.keyframes[-1].kf.x, lane.lane_index, true,\
								  self,  Vector2(PositionCalculator.get_posx_from_time(connector_time), lane.get_height(last_note_time)))
	else:
		if (Setting.gamemode == Setting.GAMEMODE.Suregi):
			var final_connector = place_suregi_connector(-1, lane.keyframes[0].kf.x, lane.keyframes[-1].kf.x, lane.lane_index, false,\
							  self, Vector2(PositionCalculator.get_posx_from_time(lane.keyframes[0].kf.x), lane.keyframes[0].kf.y))
		else:
			var final_connector = place_connector(-1, lane.keyframes[0].kf.x, lane.keyframes[-1].kf.x, lane.lane_index, false,\
							  self, Vector2(PositionCalculator.get_posx_from_time(lane.keyframes[0].kf.x), lane.keyframes[0].kf.y))

# 생성된 노트를 레인의 노트 큐에 할당
func assign_note(note: Note):
	var lane = Lane.find_lane(levelData.lanes, note.get_data().lane)
	lane.add_note(note)
	noteHolders[note.get_data().color].notes.append(note)
	note.judgement_spread.connect($IngameDataManager.catch_judgement)
	if (note.get_data().type == 2):
		note.judgement_spread.connect(lane._on_jump_character)
		lane.pending_jump_notes.append(note)

#============================== End Level ==================================

func end_game():
	game_finished = true
	PositionCalculator.reset()
	$IngameDataManager.on_song_end(level_path)
	var result = $IngameDataManager.get_result_data()
	$IngameUIManager.show_result_2(result)




#================================== Input Reading =================================

func _on_pressed(p_color:int, is_left: bool):
	if not game_finished:
		noteHolders[p_color].process_input(time, is_left)

func _on_released(p_color:int, is_left: bool):
	if not game_finished:
		noteHolders[p_color].process_release(time, is_left)


#===================================================================================
