extends Node2D

@export var leftSongHolder: SongHolder
@export var middleSongHolder: SongHolder
@export var rightSongHolder: SongHolder
@export var songDataHolder: SongDataHolder
@export var settingHolder: SettingHolder
@onready var difficultyRect: ColorRect = $CanvasLayer/Control/DifficultyRect
@onready var startButton: Button = $CanvasLayer/Control/StartButton

const CHARTS_DIR = "res://Charts"
const DIFFICULTY_COLORS = [Color(0.5, 0.85, 0.3), Color(1.0, 0.55, 0.1), Color(0.6, 0.2, 0.9)]

var song_list: Array[LevelMetaData] = []
var current_index: int = 0

func _ready() -> void:
	InputManager.pressed_a.connect(_on_move_left)
	InputManager.pressed_d.connect(_on_move_right)
	InputManager.pressed_tab.connect(_on_change_difficulty)
	InputManager.pressed_enter.connect(_on_game_start)
	InputManager.pressed_down.connect(func(): settingHolder.select_next())
	InputManager.pressed_up.connect(func(): settingHolder.select_prev())
	InputManager.pressed_left.connect(func(): settingHolder.change_value(false))
	InputManager.pressed_right.connect(func(): settingHolder.change_value(true))
	_scan_charts()
	if song_list.is_empty():
		return
	_refresh_all()

func _scan_charts():
	var dir = DirAccess.open(CHARTS_DIR)
	if dir == null:
		push_error("Cannot open Charts directory")
		return
	dir.list_dir_begin()
	var folder = dir.get_next()
	while folder != "":
		if dir.current_is_dir():
			var metadata = LevelMetaData.new()
			ChartParser.parse_metadata(CHARTS_DIR + "/" + folder, metadata)
			if metadata.name != "":
				song_list.append(metadata)
		folder = dir.get_next()
	dir.list_dir_end()

func _get_metadata(offset: int) -> LevelMetaData:
	var size = song_list.size()
	return song_list[(current_index + offset + size) % size]

func _refresh_holders():
	middleSongHolder.set_song_metadata(_get_metadata(0))
	rightSongHolder.set_song_metadata(_get_metadata(1))
	leftSongHolder.set_song_metadata(_get_metadata(-1))

func _refresh_difficulty():
	var diff = Setting.selected_difficulty
	difficultyRect.color = DIFFICULTY_COLORS[diff]
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
		elif not in_lane and parts.size() >= 5 and not parts[0] in ["MOVE","ROTATE","ZOOM","BPM"]:
			if int(parts[2]) == 0:
				single += 1
			else:
				long += 1
	return single + 2 * long

func _on_move_left():
	current_index = (current_index - 1 + song_list.size()) % song_list.size()
	_refresh_holders()
	_refresh_song_data()
	_refresh_start_button()

func _on_move_right():
	current_index = (current_index + 1) % song_list.size()
	_refresh_holders()
	_refresh_song_data()
	_refresh_start_button()

func _on_change_difficulty():
	Setting.selected_difficulty = (Setting.selected_difficulty + 1) % 3
	_refresh_all()
	_refresh_start_button()

func _on_game_start():
	if not startButton.disabled:
		var meta = _get_metadata(0)
		Setting.selected_chart_dir = CHARTS_DIR + "/" + meta.name
		get_tree().change_scene_to_file("res://Scenes/RhythmScene.tscn")
		
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
