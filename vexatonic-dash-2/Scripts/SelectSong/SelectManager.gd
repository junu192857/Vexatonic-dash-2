extends Node2D

@export var songSelectionHolder: Control
@export var leftSongHolder: SongHolder
@export var middleSongHolder: SongHolder
@export var rightSongHolder: SongHolder
@export var songDataHolder: SongDataHolder
@export var settingHolder: SettingHolder
@onready var difficultyRect: TextureRect = $CanvasLayer/Control/DifficultyRect
@onready var settingButton: TextureButton = $CanvasLayer/Control/SettingButton
@onready var startButton: TextureButton = $CanvasLayer/Control/StartButton

@export var settingRectScene: PackedScene
var settingRect

var setting_open: bool = false

const CHARTS_DIR = "user://Charts"

var song_list: Array[LevelMetaData] = []
var current_index: int = 0

func _ready() -> void:
	InputManager.pressed_a.connect(_on_move_left)
	InputManager.pressed_d.connect(_on_move_right)
	InputManager.pressed_tab.connect(_on_change_difficulty)
	InputManager.pressed_enter.connect(_on_game_start)
	InputManager.pressed_down.connect(func(): if not setting_open: settingHolder.select_next())
	InputManager.pressed_up.connect(func(): if not setting_open: settingHolder.select_prev())
	InputManager.pressed_left.connect(func(): if not setting_open: settingHolder.change_value(false))
	InputManager.pressed_right.connect(func(): if not setting_open: settingHolder.change_value(true))
	InputManager.pressed_f10.connect(_on_enter_setting)
	InputManager.pressed_esc.connect(_on_return_to_main)
	
	settingRect = settingRectScene.instantiate()
	$CanvasLayer/Control.add_child(settingRect)
	settingRect.visible = false
	settingRect.close_setting.connect(close_setting)
	
	_ensure_user_charts()
	_scan_charts()
	if song_list.is_empty():
		return
	if Setting.selected_chart_dir != "":
		for i in range(song_list.size()):
			if CHARTS_DIR + "/" + song_list[i].name == Setting.selected_chart_dir:
				current_index = i
				break
	_refresh_all()
	_refresh_start_button()

func _ensure_user_charts():
	# user://Charts가 이미 있으면 건너뜀
	#if DirAccess.open("user://Charts") != null:
	#	return
	DirAccess.make_dir_recursive_absolute("user://Charts")

	# res://Charts의 폴더 목록을 index.txt로 읽기
	var index_file = FileAccess.open("res://Charts/index.txt", FileAccess.READ)
	if index_file == null:
		return

	while not index_file.eof_reached():
		var folder = index_file.get_line().strip_edges()
		if folder.is_empty():
			continue

		var src = "res://Charts/" + folder
		var dst = "user://Charts/" + folder
		DirAccess.make_dir_recursive_absolute(dst)

		# METADATA.txt 복사
		_copy_file(src + "/METADATA.txt", dst + "/METADATA.txt")

		# 난이도 파일 복사
		for diff in Setting.DIFFICULTY_NAMES:
			var fname = diff + ".txt"
			if FileAccess.file_exists(src + "/" + fname):
				_copy_file(src + "/" + fname, dst + "/" + fname)

		# 음악 파일 복사 (METADATA에서 경로 읽기)
		var meta = LevelMetaData.new()
		ChartParser.parse_metadata(dst, meta)
		if meta.music_path != "":
			_copy_file(src + "/" + meta.music_path, dst + "/" + meta.music_path)

func _copy_file(src: String, dst: String):
	var data = FileAccess.get_file_as_bytes(src)
	if data.size() == 0:
		return
	var f = FileAccess.open(dst, FileAccess.WRITE)
	if f:
		f.store_buffer(data)

func _scan_charts():
	var index_file = FileAccess.open("res://Charts/index.txt", FileAccess.READ)
	if index_file == null:
		push_error("Cannot open res://Charts/index.txt")
		return
	while not index_file.eof_reached():
		var folder = index_file.get_line().strip_edges()
		if folder.is_empty():
			continue
		var metadata = LevelMetaData.new()
		ChartParser.parse_metadata(CHARTS_DIR + "/" + folder, metadata)
		if metadata.name != "":
			song_list.append(metadata)

func _get_metadata(offset: int) -> LevelMetaData:
	var size = song_list.size()
	return song_list[(current_index + offset + size) % size]

func _refresh_holders():
	middleSongHolder.set_song_metadata(_get_metadata(0))
	rightSongHolder.set_song_metadata(_get_metadata(1))
	leftSongHolder.set_song_metadata(_get_metadata(-1))

func _refresh_difficulty():
	var diff = Setting.selected_difficulty
	difficultyRect.set_gradient_texture(diff)
	difficultyRect.get_node("Difficulty").text = Setting.DIFFICULTY_NAMES[diff]

func _refresh_song_data():
	var meta = _get_metadata(0)
	var chart_dir = CHARTS_DIR + "/" + meta.name
	var chart_path = chart_dir + "/" + Setting.DIFFICULTY_NAMES[Setting.selected_difficulty] + ".txt"
	var total = _count_notes(chart_path)
	songDataHolder.load_play_data(chart_dir, total)

func _refresh_all():
	_refresh_difficulty()
	_refresh_holders()
	_refresh_song_data()
	settingHolder.refresh()

func _count_notes(chart_path: String) -> int:
	var file = FileAccess.open(chart_path, FileAccess.READ)
	if file == null:
		return 0
	var single = 0
	var long = 0
	var in_lane = false
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var parts = line.split(" ")
		if parts[0] == "LANE":
			in_lane = true
		elif parts[0] == "END":
			in_lane = false
		elif not in_lane and parts.size() >= 5 and not parts[0] in Trigger.TYPE_STRING:
			if int(parts[2]) == 0:
				single += 1
			else:
				long += 1
	return single + 2 * long

func _on_move_left():
	if not setting_open:
		current_index = (current_index - 1 + song_list.size()) % song_list.size()
		_refresh_holders()
		_refresh_song_data()
		_refresh_start_button()

func _on_move_right():
	if not setting_open:
		current_index = (current_index + 1) % song_list.size()
		_refresh_holders()
		_refresh_song_data()
		_refresh_start_button()

func _on_change_difficulty():
	if not setting_open:
		Setting.selected_difficulty = (Setting.selected_difficulty + 1) % 3
		_refresh_all()
		_refresh_start_button()

func _on_game_start():
	if not setting_open:
		if not startButton.disabled:
			var meta = _get_metadata(0)
			Setting.selected_chart_dir = CHARTS_DIR + "/" + meta.name
			get_tree().change_scene_to_file("res://Scenes/RhythmScene.tscn")
	else:
		close_setting()
		
		
func _can_start() -> bool:
	var meta = _get_metadata(0)
	var chart_dir = CHARTS_DIR + "/" + meta.name
	var diff_name = Setting.DIFFICULTY_NAMES[Setting.selected_difficulty]
	var chart_path = chart_dir + "/" + diff_name + ".txt"
	var music_path = chart_dir + "/" + meta.music_path
	if not FileAccess.file_exists(chart_path):
		return false
	if not FileAccess.file_exists(music_path):
		return false
	if _count_notes(chart_path) == 0:
		return false
	return true

func _refresh_start_button():
	startButton.disabled = not _can_start()
	
func _on_enter_setting():
	settingButton.disabled = true
	startButton.disabled = true
	Setting.load()
	settingRect._initialize()
	settingRect.visible = true
	setting_open = true

func close_setting():
	settingRect.visible = false
	Setting.save()
	setting_open = false
	settingHolder.refresh()
	settingButton.disabled = false
	startButton.disabled = false
	
func _on_return_to_main():
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
