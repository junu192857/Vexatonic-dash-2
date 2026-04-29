extends Node2D

var noteDatas: Array[NoteData]
var lanes: Array[Lane]

@export var CHARACTER_SCENE: PackedScene
@onready var musicPlayer = $AudioStreamPlayer

var characters: Array[Character]
var time: float
var music_started = false
var time_start_tick: float
var music_start_tick: float
#어느 레인까지 캐릭터가 생성되었는지 체크하는 용도
var lane_index: int

const COUNTDOWN_TIME = 3000

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# ==== Parsing & Lanes, NoteDatas 정렬
	print("START")
	InputHandler.note_pressed.connect(_on_pressed)
	ChartParser.parse("res://Charts/test.csv", lanes, noteDatas)
	Lane.sort_lanes(lanes)
	lane_index = 0
	noteDatas.sort_custom(func(a: NoteData, b: NoteData):
		if a.lane != b.lane:
			return a.lane < b.lane
		return a.time < b.time
	)
	
	# 채보 찍기
	render_chart()
	
	#print(noteDatas.size())
	for lane:Lane in lanes:
		lane.print_data()
	
	# 최초의 lane들에 캐릭터 생성
	for lane in lanes:
		if (lane.is_init):
			place_character(lane)
			lane_index += 1
	
	time_start_tick = Time.get_ticks_msec()

func place_character(lane: Lane):
	#var initial_pos_x = Setting.get_posx_from_time(-COUNTDOWN_TIME)
	var character = CHARACTER_SCENE.instantiate() as Character
	#sayane.position = Vector2(initial_pos_x, -Setting.CHARACTER_POS_Y)
	character.set_lane(lane)
	characters.append(character)
	add_child(character)
	
	
func _process(delta):
	if (not music_started):
		time = Time.get_ticks_msec() - time_start_tick - COUNTDOWN_TIME
		if time >= 0:
			musicPlayer.play()
			music_start_tick = Time.get_ticks_msec()
			music_started = true
	else:
		time = musicPlayer.get_playback_position() * 1000
	
	if (lane_index < lanes.size() and lanes[lane_index].get_start_time() < time):
		place_character(lanes[lane_index])
		lane_index += 1
		
	
	for character in characters:
		if character.set_character_position(time):
			characters.erase(character)


#============================== Chart Rendering ===================================

@export var NOTE_SCENE: PackedScene
@export var CONNECTOR_SCENE: PackedScene

# render_chart() 후 생성된 Note, Connector, Marker의 관계
#
#			   /‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\									 /‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\
#             /						  \									/						  \
# RhythmScene --- Note --- Connector NextNote---Connector      LongNote---Connector(롱놋틱) Marker Connector
#			  \								   					/	    \__________________/
#			   \_______________________________________________/


func render_chart():
	var pos_x
	var previous_time = -1
	var previous_note
	var previous_lane = -1
	for noteData in noteDatas:
		pos_x = Setting.get_posx_from_time(noteData.time)
		if (previous_time >= 0):
			var connector = place_connector(-1, previous_time + Setting.time_per_note_width, noteData.time, \
							previous_lane, true, previous_note, Vector2(Setting.NOTE_WIDTH, 0))
		var cur_note = place_note(noteData, pos_x, false, self)
		assign_note(cur_note)
	
		previous_time = noteData.time
		previous_lane = noteData.lane
		previous_note = cur_note;
	
		if (noteData.type == 1): #LongNote
			var length = Setting.get_posx_from_time(noteData.end_time-noteData.time)
			var connector = place_connector(noteData.color, noteData.time + Setting.time_per_note_width, \
							noteData.end_time, previous_lane, true, cur_note, Vector2(Setting.NOTE_WIDTH, 0))
			var marker = place_note(noteData, length, true, cur_note)
			previous_time = noteData.end_time
			previous_note = marker;
			
	for lane:Lane in lanes:
		lane.print_data()
		lane.sort_notes()
		place_initial_connector(lane)
		place_final_connector(lane)

# 단노트, 롱노트 시작점 밑 끝점 생성
func place_note(data:NoteData, pos_x: float, is_marker:bool, parent: Node2D) -> Node2D:
	var note = NOTE_SCENE.instantiate() as Node2D
	note.set_data(data)
	var lane = Lane.find_lane(lanes, data.lane)
	parent.add_child(note)
	if !is_marker:
		note.position = Vector2(pos_x, -lane.get_height(data.time))
	else:
		note.position = Vector2(pos_x, -(lane.get_height(data.end_time) - lane.get_height(data.time)))
	#print("Place Note at %f"% pos_x)
	
	return note

# 해당 Connector가 단노트 또는 Marker 뒤에 처음 나오는 Connector인 경우 first = true, 그 외의 경우 first = false
func place_connector(p_color:int, start_time: float, end_time: float, lane: int, first: bool, parent:Node2D, p_pos:Vector2):
	if (end_time - start_time <= 0):
		return
	var connector = CONNECTOR_SCENE.instantiate() as Node2D
	var initial_end_time = connector.set_connector_data(p_color, start_time, end_time, Lane.find_lane(lanes, lane), first)
	
	# 하나의 Connector 안에서 레인이 꺾이는 경우: 꺾이는 지점부터 새로운 Connector 생성
	if (end_time - initial_end_time > Setting.EPSILON):
		var following_connector = place_connector(p_color, initial_end_time, end_time, lane, false,\
								  connector, Vector2(connector.data.length, -connector.data.delta_y))

	parent.add_child(connector)
	connector.position = p_pos
	
	
# 레인의 첫 번째 노트 이전의 Connector 생성. 첫 번째 노트가 없으면 패스
func place_initial_connector(lane: Lane):
	if (!lane.notes.is_empty()):
		if (lane.is_init):
			print("THIS IS INITIAL LANE")
			#var initial_height = lane.keyframes[0].y
			var initial_connector = place_connector(-1, -3000, lane.notes[0].get_time(), lane.lane_index, false,\
									self, Vector2(Setting.get_posx_from_time(-3000),0))
			
			#var connector = CONNECTOR_SCENE.instantiate() as Node2D
			#connector.position = Vector2(Setting.get_posx_from_time(-3000),0)
			#connector.set_connector_data(-1, -3000, lane.notes[0].get_time(), lane, false)
			#add_child(connector)
		else:
			if (lane.keyframes[0].x < lane.notes[0].get_time()):
				var initial_connector = place_connector(-1, lane.keyframes[0].x, lane.notes[0].get_time(), lane.lane_index,\
										false, self,  Vector2(Setting.get_posx_from_time(lane.keyframes[0].x), -lane.keyframes[0].y))
				
				#var connector = CONNECTOR_SCENE.instantiate() as Node2D
				#connector.position = Vector2(Setting.get_posx_from_time(lane.keyframes[0].x), -lane.keyframes[0].y)
				#connector.set_connector_data(-1, lane.keyframes[0].x, lane.notes[0].get_time(), lane, false)
				#add_child(connector)

# 레인의 마지막 노트 이후의 Connector 생성 또는 노트가 없는 레인의 Connector 생성
func place_final_connector(lane: Lane):
	print("LANE SIZE: %d" % lane.notes.size())
	if (!lane.notes.is_empty()):
		var last_note_time = lane.notes[-1].get_end_time() #find last note or marker
		if lane.keyframes[-1].x - last_note_time > Setting.time_per_note_width:
			var connector_time = last_note_time + Setting.time_per_note_width
			var final_connector = place_connector(-1, connector_time, lane.keyframes[-1].x, lane.lane_index, true,\
								  self,  Vector2(Setting.get_posx_from_time(connector_time), -lane.get_height(last_note_time)))
	else:
		var final_connector = place_connector(-1, lane.keyframes[0].x, lane.keyframes[-1].x, lane.lane_index, false,\
							  self, Vector2(Setting.get_posx_from_time(lane.keyframes[0].x), -lane.keyframes[0].y))

# 생성된 노트를 레인의 노트 큐에 할당
func assign_note(note: Note):
	var lane = Lane.find_lane(lanes, note.data.lane)
	lane.add_Note(note)

#==================================================================================







#================================== Input Reading =================================

var total_judgements:Array[int] = [0, 0, 0, 0]

func _on_pressed(p_color:int):
	var pressed_ms = time
	#print("Hello! your color is: %d and pressed_ms: %f and time: %f and character_posx: %f" % [p_color, pressed_ms, time, character.position.x])
	
	for lane:Lane in lanes:
		if (lane.notes.size() <= lane.note_index):
			continue
		else:
			var judgement = lane.notes[lane.note_index].process_input(p_color, pressed_ms)
			if (judgement < 4): #not pass
				lane.note_index += 1
				break

#===================================================================================
