extends Node2D

var levelData: LevelData

@export var CHARACTER_SCENE: PackedScene
@onready var musicPlayer = $AudioStreamPlayer
@onready var camera = $CameraManager


var characters: Array[Character]
@export var character_holder: Node2D

var time: float
var music_started = false
var game_finished = false
var time_start_tick: float
var music_start_tick: float
#어느 레인까지 캐릭터가 생성되었는지 체크하는 용도
var lane_index: int

var noteHolders: Array[NoteHolder]

const COUNTDOWN_TIME = 3000
var level_path = "res://Charts/YOUNITHM"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# ==== Parsing & Lanes, NoteDatas 정렬
	print("START")
	$InputHandler.note_pressed.connect(_on_pressed)
	$InputHandler.note_released.connect(_on_released)
	
	for i in range(3):
		noteHolders.append(NoteHolder.new(i))
	
	levelData = ChartParser.parse(level_path, Setting.selected_difficulty)
	$IngameDataManager.set_total_notes(levelData.noteDatas)
	Lane.sort_lanes(levelData.lanes)
	lane_index = 0
	
	levelData.sort_noteDatas()
	levelData.sort_triggers()
	# 채보 찍기
	render_chart()
	sort_note_holders()
	
	if Setting.judge_offset != 0.0:
		for noteData in levelData.noteDatas:
			noteData.time -= Setting.judge_offset
			noteData.end_time -= Setting.judge_offset
	
	camera.set_triggers(levelData.triggers)
	var stream = AudioStreamMP3.new()
	print("MUSIC_PATH: " + levelData.music_path)
	stream.data = FileAccess.get_file_as_bytes(level_path + "/" +  levelData.music_path)
	musicPlayer.stream = stream
	
	
	#print(levelData.noteDatas.size())
	for lane:Lane in levelData.lanes:
		#lane.print_data()
		pass
	
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
	#var initial_pos_x = Setting.get_posx_from_time(-COUNTDOWN_TIME)
	var character = CHARACTER_SCENE.instantiate() as Character
	#sayane.position = Vector2(initial_pos_x, -Setting.CHARACTER_POS_Y)
	character.set_lane(lane)
	characters.append(character)
	character_holder.add_child(character)

	
func _physics_process(delta: float) -> void:
	if (not game_finished):
		if (not music_started):
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
			
		character_holder.position.x = Setting.get_posx_from_time(time)
		for character in characters:
			if character.set_character_position(time):
				characters.erase(character)
		
		for holder in noteHolders:
			holder.check_miss(time)
			holder.update_visuals(time)

		camera.move(time)
	

func sort_note_holders():
	for holder in noteHolders:
		holder.sort_notes()
		print("HELLO")

#============================== Chart Rendering ===================================

@export var NOTE_SCENE: PackedScene
@export var LONG_NOTE_SCENE: PackedScene
@export var CONNECTOR_SCENE: PackedScene

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
		pos_x = Setting.get_posx_from_time(noteData.time)
		var cur_note = place_note(noteData, pos_x, false, self)
		assign_note(cur_note)
		if (previous_time >= 0 and previous_lane == noteData.lane and Setting.gamemode != Setting.GAMEMODE.Suregi):
			var connector = place_connector(-1, previous_time + Setting.time_per_note_width / 2, noteData.time - Setting.time_per_note_width / 2, \
							previous_lane, true, previous_note, Vector2(Setting.NOTE_WIDTH / 2.0, 0))
	
		previous_time = noteData.time
		previous_lane = noteData.lane
		previous_note = cur_note;
	
		if (noteData.type == 1): #LongNote
			var end_pos_x = Setting.get_posx_from_time(noteData.end_time)
			var marker = place_note(noteData, end_pos_x, true, cur_note)
			var connector = place_connector(noteData.color, noteData.time + Setting.time_per_note_width / 2, \
							noteData.end_time - Setting.time_per_note_width / 2, previous_lane, true, cur_note, Vector2(Setting.NOTE_WIDTH / 2.0, 0))
			(cur_note as LongNote).set_target_connector(connector as Connector)
			previous_time = noteData.end_time
			previous_note = marker;
			
	for lane:Lane in levelData.lanes:
		#lane.print_data()
		lane.sort_notes()
		if (Setting.gamemode != Setting.GAMEMODE.Suregi):
			place_initial_connector(lane)
			place_final_connector(lane)

# 단노트, 롱노트 시작점 밑 끝점 생성
func place_note(data:NoteData, pos_x: float, is_marker:bool, parent: Node2D) -> Node2D:
	var note = (LONG_NOTE_SCENE if not is_marker and data.type == 1 else NOTE_SCENE).instantiate() as Node2D
	note.set_data(data)
	var lane = Lane.find_lane(levelData.lanes, data.lane)
	parent.add_child(note)
	if !is_marker:
		note.global_position = Vector2(pos_x, lane.get_height(data.time))
		lane.adjust_keyframe(data.time, note.global_position.y)
	else:
		note.global_position = Vector2(pos_x, lane.get_height(data.end_time))
		lane.adjust_keyframe(data.end_time, note.global_position.y)
		
	
	#print("Place Note at x: %f y: %f"% [pos_x, note.global_position.y])
	return note

# 해당 Connector가 단노트 또는 Marker 뒤에 처음 나오는 Connector인 경우 first = true, 그 외의 경우 first = false
func place_connector(p_color:int, start_time: float, end_time: float, lane: int, first: bool, parent:Node2D, p_pos:Vector2):
	if (end_time - start_time <= 0):
		return
	var connector = CONNECTOR_SCENE.instantiate() as Node2D
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
	
# 레인의 첫 번째 노트 이전의 Connector 생성. 첫 번째 노트가 없으면 패스
func place_initial_connector(lane: Lane):
	if (!lane.notes.is_empty()):
		if (lane.is_init):
			print("THIS IS INITIAL LANE")
			#var initial_height = lane.keyframes[0].y
			var initial_connector = place_connector(-1, -COUNTDOWN_TIME, lane.notes[0].get_time() - Setting.time_per_note_width / 2, lane.lane_index, false,\
									self, Vector2(Setting.get_posx_from_time(-COUNTDOWN_TIME),lane.keyframes[0].kf.y))
		else:
			if (lane.keyframes[0].kf.x < lane.notes[0].get_time()):
				var initial_connector = place_connector(-1, lane.keyframes[0].kf.x, lane.notes[0].get_time() - Setting.time_per_note_width / 2, lane.lane_index,\
										false, self,  Vector2(Setting.get_posx_from_time(lane.keyframes[0].kf.x), lane.keyframes[0].kf.y))
	#TODO: 노트가 없는 initial lane에 대해 대응하기.

# 레인의 마지막 노트 이후의 Connector 생성 또는 노트가 없는 레인의 Connector 생성
func place_final_connector(lane: Lane):
	print("LANE SIZE: %d" % lane.notes.size())
	if (!lane.notes.is_empty()):
		var last_note_time = lane.notes[-1].get_end_time() #find last note or marker
		if lane.keyframes[-1].kf.x  > last_note_time + Setting.time_per_note_width / 2:
			var connector_time = last_note_time + Setting.time_per_note_width / 2
			var final_connector = place_connector(-1, connector_time, lane.keyframes[-1].kf.x, lane.lane_index, true,\
								  self,  Vector2(Setting.get_posx_from_time(connector_time), lane.get_height(last_note_time)))
	else:
		var final_connector = place_connector(-1, lane.keyframes[0].kf.x, lane.keyframes[-1].kf.x, lane.lane_index, false,\
							  self, Vector2(Setting.get_posx_from_time(lane.keyframes[0].kf.x), lane.keyframes[0].kf.y))

# 생성된 노트를 레인의 노트 큐에 할당
func assign_note(note: Note):
	var lane = Lane.find_lane(levelData.lanes, note.get_data().lane)
	lane.add_note(note)
	noteHolders[note.get_data().color].notes.append(note)
	note.judgement_spread.connect($IngameDataManager.catch_judgement)

#============================== End Level ==================================

func end_game():
	game_finished = true
	$IngameDataManager.on_song_end()




#================================== Input Reading =================================

func _on_pressed(p_color:int, is_left: bool):
	if not game_finished:
		noteHolders[p_color].process_input(time, is_left)

func _on_released(p_color:int, is_left: bool):
	if not game_finished:
		noteHolders[p_color].process_release(time, is_left)


#===================================================================================
