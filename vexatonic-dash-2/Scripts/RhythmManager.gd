extends Node

var noteDatas: Array[NoteData]
var lanes: Array[Lane]

@export var CHARACTER_SCENE: PackedScene
@onready var musicPlayer = $AudioStreamPlayer

var character: Node2D
var time: float
var music_started = false
var time_start_tick: float
var music_start_tick: float

const COUNTDOWN_TIME = 3000

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	InputHandler.note_pressed.connect(_on_pressed)
	parse("res://Charts/test.csv", lanes, noteDatas)
	render_chart()
	
	for lane:Lane in lanes:
		lane.print_data()
		lane.sort_notes()
	print(noteDatas.size())
	
	#RhythmScene으로 넘어온 뒤 3초 후 게임 시작
	place_character()
	
	time_start_tick = Time.get_ticks_msec()

func place_character():
	var initial_pos_x = Setting.get_posx_from_time(-COUNTDOWN_TIME)
	character = CHARACTER_SCENE.instantiate() as Node2D
	character.position = Vector2(initial_pos_x, -26)
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
		
	character.position.x = Setting.get_posx_from_time(time)

#============================== Chart Parsing =====================================

func parse(path:String, lanes: Array[Lane], noteDatas: Array[NoteData]):
	#var notes: Array[NoteData]
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("ERROR: 채보 파일을 열 수 없습니다.: "+ path)
		return
	
	var current_lane: Lane
	
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		print(line)
		
		if line == "" or line.begins_with("#"):
			continue
		
		var parts = line.split(" ")
		
		if parts[0] == "LANE":
			var index = int(parts[1])
			if (Lane.find_lane(lanes, index)) == null:
				current_lane = Lane.new(index)
				lanes.append(current_lane)
			else:
				push_error("ERROR: lane index %d already exist" % index)
			continue
		
		if parts[0] == "END" and current_lane:
			current_lane = null
			continue
		
		if parts.size() == 2 and current_lane:
			current_lane.add_keyframe(float(parts[0]), float(parts[1]))
			continue
			
		if current_lane == null and parts.size() >= 5:
			var time = float(parts[0])
			var color = int(parts[1])
			var type = int(parts[2])
			var end_time = float(parts[3])
			var lane = int(parts[4])

			noteDatas.append(NoteData.new(time, color, type, end_time, lane))
			print("append done")
		
	return


#============================== Chart Rendering ===================================

@export var NOTE_SCENE: PackedScene
@export var CONNECTOR_SCENE: PackedScene
	
func render_chart():
	place_initial_connector()
	
	var pos_x
	var previous_time = -1
	var previous_note
	var previous_lane = -1
	for noteData in noteDatas:
		pos_x = Setting.get_posx_from_time(noteData.time)
		if (previous_time >= 0):
			var connector = place_connector(-1, previous_time + Setting.time_per_note_width, noteData.time, previous_lane)
			if (connector):
				previous_note.add_child(connector)
		
		var cur_note = place_note(noteData, pos_x, true)
		add_child(cur_note)
		assign_note(cur_note)
		
		previous_time = noteData.time
		previous_lane = noteData.lane
		previous_note = cur_note;
		
		if (noteData.type == 1): #LongNote
			var length = Setting.get_posx_from_time(noteData.end_time-noteData.time)
			var connector = place_connector(noteData.color, noteData.time + Setting.time_per_note_width, noteData.end_time, previous_lane)
			cur_note.add_child(connector)
			var marker = place_note(noteData, length, false)
			cur_note.add_child(marker)
			previous_time = noteData.end_time
			previous_note = marker;
			

func place_note(data:NoteData, pos_x: float, original:bool) -> Node2D:
	var note = NOTE_SCENE.instantiate() as Node2D
	note.set_data(data)
	note.position = Vector2(pos_x, -Lane.find_lane(lanes, data.lane).get_height(data.time) if original else 0)
	#print("Place Note at %f"% pos_x)
	return note

func place_connector(p_color:int, start_time: float, end_time: float, lane: int) -> Node2D:
	if (end_time - start_time <= 0):
		return null
	var connector = CONNECTOR_SCENE.instantiate() as Node2D
	connector.set_connector_data(p_color, start_time, end_time, Lane.find_lane(lanes, lane))
	connector.position = Vector2(Setting.NOTE_WIDTH, 0)
	#print("Place Connector with length %f" % (length-Setting.NOTE_WIDTH))
	return connector
	
func place_initial_connector():
	var connector = CONNECTOR_SCENE.instantiate() as Node2D
	connector.position = Vector2(-1000,0)
	connector.set_connector_data(-1, -3000, 0)
	add_child(connector)
	

	
func assign_note(note: Note):
	var lane = Lane.find_lane(lanes, note.data.lane)
	lane.add_Note(note)

#==================================================================================







#================================== Input Reading =================================

var total_judgements:Array[int] = [0, 0, 0, 0]

func _on_pressed(p_color:int):
	var pressed_ms = time
	print("Hello! your color is: %d and pressed_ms: %f and time: %f and character_posx: %f" % [p_color, pressed_ms, time, character.position.x])
	
	for lane:Lane in lanes:
		if (lane.notes.size() <= lane.note_index):
			continue
		else:
			var judgement = lane.notes[lane.note_index].process_input(p_color, pressed_ms)
			if (judgement < 4): #not pass
				lane.note_index += 1
				break

#===================================================================================
