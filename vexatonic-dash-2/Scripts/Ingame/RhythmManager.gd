extends Node2D

var levelData: LevelData

@export var CHARACTER_SCENE: PackedScene
@onready var musicPlayer: AudioStreamPlayer = $AudioStreamPlayer
@onready var cameraManager = $CameraManager
@onready var camera = $CameraManager/Camera2D
@onready var line = $CharacterHolder/Line
@onready var lineSprite = $CharacterHolder/Line/Sprite2D
@onready var character_holder:Node2D = $CharacterHolder
@onready var pausedPanelHolder: Control = $"../CanvasLayer/Control/PausedPanelHolder"

var characters: Array[Character]

var time: float
var need_refresh_tutorial: bool = true
var started_tutorial: bool = false
var music_started = false
var music_play_requested = false
var game_finished = false
var time_start_tick_usec: int

# 오디오 믹스 사이를 보간하고, 실제 출력 지연을 제외한 음악 시각을 계산하기 위한 상태
var audio_output_latency_sec: float = 0.0
var music_clock_switch_usec: int = 0
var last_audio_time_ms: float = -1.0e20

# 인게임에서만 누적 입력을 비활성화하고, 씬을 떠날 때 이전 값을 복원
var previous_use_accumulated_input: bool
#어느 레인까지 캐릭터가 생성되었는지 체크하는 용도
var lane_index: int

var noteHolders: Array[NoteHolder]

const COUNTDOWN_TIME = 3000
var level_path: String

# ============================== 일시정지 ==================================
var paused_time: float = 0.0
# 재개 버튼을 누른 순간부터 (되감기 + 음악이 일시정지 시점까지 다시 따라잡을 때까지) true.
# 이 동안엔 음악이 -80db로 음소거된 채로 미리 재생되고 있음 (그대로 musicPlayer 재생 위치가 time 계산에 쓰임)
var is_resuming_animation: bool = false
var pre_pause_volume_db: float = 0.0
# music_started == false일 때 time은 마이크로초 단위 시스템 시계와 time_offset으로 계산.
# 평소엔 -COUNTDOWN_TIME(곡 시작 전 카운트다운), 되감기 목표 시점이 0보다 작으면 (paused_time - 2000)로 바뀜
var time_offset: float = -COUNTDOWN_TIME

var loaded: bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	previous_use_accumulated_input = Input.use_accumulated_input
	Input.use_accumulated_input = false
	# get_output_latency()는 매 프레임 호출 비용이 있으므로 인게임 시작 시 한 번만 캐시
	audio_output_latency_sec = AudioServer.get_output_latency()

	#입력 연결
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
	InputManager.pressed_esc.connect(_on_pressed_esc)
	PausedInputManager.pressed_a.connect(_on_pause_resume_pressed)
	PausedInputManager.pressed_s.connect(_on_pause_restart_pressed)
	PausedInputManager.pressed_d.connect(_on_pause_quit_pressed)

	#채보 경로 설정
	level_path = "res://Charts/Tutorial" if Setting.is_tutorial else Setting.selected_chart_dir 
	
	#noteHolder 생성
	for i in range(4):
		noteHolders.append(NoteHolder.new(i))
	
	#채보 파싱
	levelData = ChartParser.parse(level_path, 0 if Setting.is_tutorial else Setting.selected_difficulty)
	
	#IngameDataManager 설정
	$IngameDataManager.set_total_notes(levelData.noteDatas)
	$IngameDataManager.all_notes_cleared.connect(end_game, CONNECT_ONE_SHOT)
	$IngameDataManager.game_over_triggered.connect(game_over, CONNECT_ONE_SHOT)
	$IngameDataManager._setup_track_skip(level_path)
	
	#IngameUIManager 설정
	$IngameUIManager.setup()
	
	#레인 정렬
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
	
	
	time_start_tick_usec = Time.get_ticks_usec()
	
	await get_tree().create_timer(0.34).timeout
	
	TransitionOverlay.open()


func _exit_tree() -> void:
	Input.use_accumulated_input = previous_use_accumulated_input


# 음악 시작 전에는 시스템 시계, 시작 후에는 오디오 하드웨어 시계를 사용한다.
# 입력 콜백에서도 이 함수를 직접 호출해 마지막 physics frame의 캐시된 time을 사용하지 않는다.
func get_chart_time_ms() -> float:
	if not music_started:
		return _get_countdown_time_ms(Time.get_ticks_usec())
	return _get_audio_time_ms()


func _get_countdown_time_ms(now_usec: int) -> float:
	return (now_usec - time_start_tick_usec) / 1000.0 + time_offset


func _get_audio_time_ms() -> float:
	var audio_time_ms = (
		musicPlayer.get_playback_position()
		+ AudioServer.get_time_since_last_mix()
		- audio_output_latency_sec
	) * 1000.0 + Setting.sound_offset

	# 오디오 스레드 측정값이 순간적으로 뒤로 움직이는 경우 이전 시각을 유지
	audio_time_ms = max(audio_time_ms, last_audio_time_ms)
	last_audio_time_ms = audio_time_ms
	return audio_time_ms


func _update_game_time() -> void:
	var now_usec = Time.get_ticks_usec()

	if not music_started:
		if Setting.is_tutorial and (now_usec - time_start_tick_usec) / 1000.0 > 1000.0 and need_refresh_tutorial:
			time_start_tick_usec = now_usec
			need_refresh_tutorial = false

		time = _get_countdown_time_ms(now_usec)

		# play() 호출과 실제 출력 사이의 지연만큼 먼저 재생을 요청한다.
		# music_started 전환 시점까지는 시스템 시계를 유지해 두 시계의 경계를 연속적으로 만든다.
		if not music_play_requested:
			var start_delay_sec = AudioServer.get_time_to_next_mix() + audio_output_latency_sec
			if time >= Setting.sound_offset - start_delay_sec * 1000.0:
				musicPlayer.play()
				music_play_requested = true
				music_clock_switch_usec = now_usec + roundi(start_delay_sec * 1000000.0)

		if music_play_requested and now_usec >= music_clock_switch_usec:
			music_started = true
			last_audio_time_ms = time
			time = _get_audio_time_ms()
	else:
		time = _get_audio_time_ms()


func place_character(lane: Lane):
	if (Setting.gamemode != Setting.GAMEMODE.Normal_Character):
		return
	var character = CHARACTER_SCENE.instantiate() as Character
	character.set_lane(lane)
	lane.character = character
	characters.append(character)
	character_holder.add_child(character)

	
func _physics_process(_delta: float) -> void:
	if (not game_finished):
		_update_game_time()
		if is_resuming_animation and time >= paused_time:
			musicPlayer.volume_db = pre_pause_volume_db
			is_resuming_animation = false
		
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
	var track_same_time_lines = Setting.same_time_note_line
	# 각 원소: {"time": float, "notes": Array} - time은 그룹의 기준(가장 먼저 들어온 노트) 시각
	var same_time_notes: Array = []
	for noteData in levelData.noteDatas:
		pos_x = PositionCalculator.get_posx_from_time(noteData.time)
		var cur_note = place_note(noteData, pos_x, false, self)
		assign_note(cur_note)
		if track_same_time_lines:
			var bucket = null
			for b in same_time_notes:
				if abs(b["time"] - noteData.time) < Setting.EPSILON:
					bucket = b
					break
			if bucket == null:
				bucket = {"time": noteData.time, "notes": []}
				same_time_notes.append(bucket)
			bucket["notes"].append(cur_note)
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

	if track_same_time_lines:
		place_same_time_lines(same_time_notes)

# 입력 시간이 같은 노트들을 흰 선으로 연결 (Suregi 모드 전용 설정)
func place_same_time_lines(same_time_notes: Array) -> void:
	for bucket in same_time_notes:
		var notes: Array = bucket["notes"]
		if notes.size() < 2:
			continue
		notes.sort_custom(func(a, b): return a.global_position.y < b.global_position.y)
		var line := Line2D.new()
		line.default_color = Color(1, 1, 1, 1)
		line.width = 4.0
		line.z_index = -1
		for note in notes:
			line.add_point(note.global_position)
		add_child(line)

# 단노트, 롱노트 시작점 밑 끝점 생성
func place_note(data:NoteData, pos_x: float, p_is_marker:bool, parent: Node2D) -> Note:
	
	#노트 데이터 설정
	var note = (LONG_NOTE_SCENE if not p_is_marker and data.type == 1 else NOTE_SCENE).instantiate()
	note.set_data(data)
	note.is_marker = p_is_marker
	var lane = Lane.find_lane(levelData.lanes, data.lane)
	parent.add_child(note)
	
	#노트 비주얼 설정(색깔 및 크기)
	note.select_color()
	note.sprite.scale.y = Setting.note_width_scale()
	if !p_is_marker:
		var height = lane.get_height(data.time)
		note.global_position = Vector2(pos_x, Setting.mirror_y(height))
		if data.adjusted == 1:
			note.set_line()
			note.set_line_scale()
		lane.adjust_keyframe(data.time, height)
	else:
		var height = lane.get_height(data.end_time)
		note.global_position = Vector2(pos_x, Setting.mirror_y(height))
		lane.adjust_keyframe(data.end_time, height)
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
		place_suregi_connector(-1, start_time, end_time, lane.lane_index, false, self, Vector2(PositionCalculator.get_posx_from_time(start_time),Setting.mirror_y(lane.keyframes[0].kf.y)))
	else:
		place_connector(-1, start_time, end_time, lane.lane_index, false, self, Vector2(PositionCalculator.get_posx_from_time(start_time),Setting.mirror_y(lane.keyframes[0].kf.y)))
	

# 레인의 마지막 노트 이후의 Connector 생성 또는 노트가 없는 레인의 Connector 생성
func place_final_connector(lane: Lane):
	if (!lane.notes.is_empty()):
		var last_note_time = lane.notes[-1].get_data().end_time #find last note or marker
		var connector_time = PositionCalculator.get_time_from_posx(PositionCalculator.get_posx_from_time(last_note_time) + Setting.NOTE_WIDTH / 2.0)
		if lane.keyframes[-1].kf.x > connector_time:
			if (Setting.gamemode == Setting.GAMEMODE.Suregi):
				var final_connector = place_suregi_connector(-1, connector_time, lane.keyframes[-1].kf.x, lane.lane_index, true,\
								  self,  Vector2(PositionCalculator.get_posx_from_time(connector_time), Setting.mirror_y(lane.get_height(last_note_time))))
			else:
				var final_connector = place_connector(-1, connector_time, lane.keyframes[-1].kf.x, lane.lane_index, true,\
								  self,  Vector2(PositionCalculator.get_posx_from_time(connector_time), Setting.mirror_y(lane.get_height(last_note_time))))
	else:
		if (Setting.gamemode == Setting.GAMEMODE.Suregi):
			var final_connector = place_suregi_connector(-1, lane.keyframes[0].kf.x, lane.keyframes[-1].kf.x, lane.lane_index, false,\
							  self, Vector2(PositionCalculator.get_posx_from_time(lane.keyframes[0].kf.x), Setting.mirror_y(lane.keyframes[0].kf.y)))
		else:
			var final_connector = place_connector(-1, lane.keyframes[0].kf.x, lane.keyframes[-1].kf.x, lane.lane_index, false,\
							  self, Vector2(PositionCalculator.get_posx_from_time(lane.keyframes[0].kf.x), Setting.mirror_y(lane.keyframes[0].kf.y)))

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
	if (Setting.is_tutorial):
		Setting.is_tutorial = false
	PositionCalculator.reset()
	$IngameDataManager.on_song_end(level_path)
	var result = $IngameDataManager.get_result_data()
	$IngameUIManager.show_result_2(result)

func game_over():
	end_game()
	musicPlayer.stop()

#================================== Input Reading =================================

func _on_pressed(p_color:int, is_left: bool):
	if not game_finished:
		noteHolders[p_color].process_input(get_chart_time_ms(), is_left)

func _on_released(p_color:int, is_left: bool):
	if not game_finished:
		noteHolders[p_color].process_release(get_chart_time_ms(), is_left)

#================================== 일시정지 =================================

func _on_pressed_esc():
	if game_finished or get_tree().paused or Setting.is_tutorial:
		return
	var pause_time = get_chart_time_ms()
	if pause_time < 0:
		return
	_pause_game(pause_time)

func _pause_game(at_time: float):
	paused_time = at_time
	$IngameDataManager.record_disabled = true
	for holder in noteHolders:
		holder.force_pause(paused_time)
	pre_pause_volume_db = musicPlayer.volume_db
	musicPlayer.stop()
	pausedPanelHolder.visible = true
	get_tree().paused = true

func _on_pause_resume_pressed():
	if not get_tree().paused or is_resuming_animation:
		return
	is_resuming_animation = true
	pausedPanelHolder.visible = false
	var rewind_target = paused_time - 2000.0
	var rewind_tween = create_tween()
	rewind_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	rewind_tween.tween_method(_update_rewind_visual, paused_time, rewind_target, 1.0)
	rewind_tween.tween_callback(_start_resume_catchup.bind(rewind_target))

# 되감기 애니메이션 도중 매 프레임 호출: 카메라와 스크롤 기준점을 되감기 시점에 맞춤
# (캐릭터 개별 위치는 PositionCalculator의 단조증가 가정 때문에 되감기 중엔 갱신하지 않고
#  정상 진행이 재개되면 _physics_process가 다시 정확히 따라잡음)
func _update_rewind_visual(t: float) -> void:
	cameraManager.scrub_to(t)
	character_holder.position = Vector2(PositionCalculator.get_posx_from_time(t), cameraManager.position.y)

func _start_resume_catchup(resume_target: float) -> void:
	PositionCalculator.reset_monotonic_index()
	cameraManager.reset_trigger_state()
	musicPlayer.volume_db = -80.0
	if resume_target < Setting.sound_offset:
		# 되감기 목표가 곡 시작 전이면 카운트다운 시계로 돌아간 뒤,
		# 출력 지연을 고려해 음악 재생을 다시 예약한다.
		music_started = false
		music_play_requested = false
		time_start_tick_usec = Time.get_ticks_usec()
		time_offset = resume_target
		last_audio_time_ms = -1.0e20
	else:
		var seek_pos = (resume_target - Setting.sound_offset) / 1000.0
		musicPlayer.play(seek_pos)
		music_started = true
		music_play_requested = false
		# seek 직후 오디오 시계가 출력 지연만큼 과거를 가리켜도 화면이 뒤로 튀지 않게 고정
		last_audio_time_ms = resume_target
	get_tree().paused = false

func _on_pause_restart_pressed():
	if not get_tree().paused or is_resuming_animation:
		return
	is_resuming_animation = true
	get_tree().paused = false
	await TransitionOverlay.close()
	get_tree().reload_current_scene()

func _on_pause_quit_pressed():
	if not get_tree().paused or is_resuming_animation:
		return
	is_resuming_animation = true
	get_tree().paused = false
	await TransitionOverlay.close()
	get_tree().change_scene_to_file("res://Scenes/SelectSong.tscn")


#===================================================================================
