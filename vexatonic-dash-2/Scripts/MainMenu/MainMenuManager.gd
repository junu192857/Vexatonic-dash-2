extends Node

var button_array: Array
var index: int
@export var settingRect: TextureRect

var setting_open: bool = false

enum SettingItem { Speed, SoundOffset, JudgeOffset, Gamemode, ScoreDisplay }
var setting_index: int = 0

const SETTING_INFO = [
	"게임의 속도를 설정합니다.",
	"음악 싱크를 설정합니다.\nFast가 많다면 (+)방향, Late가 많다면 (-)방향으로 조절하세요.",
	"판정 싱크를 설정합니다.\nFast가 많다면 (+)방향, Late가 많다면 (-)방향으로 조절하던가 말던가..",
	"게임 모드를 설정합니다.",
	"스코어 표시 방식을 설정합니다.",
]

const GAMEMODE_SETTING_INFO = [
	"TypeA: 캐릭터가 보입니다.",
	"TypeB: 판정선이 보입니다.",
	"TypeC: 노트가 위에서 내려옵니다. 판정선이 보이고 하얀색 플랫폼이 보이지 않습니다."
]

@onready var speed_value: Label = $CanvasLayer/Control/SettingRect/CategoryLabels/Speed/Value
@onready var sound_offset_value: Label = $CanvasLayer/Control/SettingRect/CategoryLabels/SoundOffset/Value
@onready var judge_offset_value: Label = $CanvasLayer/Control/SettingRect/CategoryLabels/JudgeOffset/Value
@onready var gamemode_value: Label = $CanvasLayer/Control/SettingRect/CategoryLabels/Gamemode/Value
@onready var score_display_value: Label = $CanvasLayer/Control/SettingRect/CategoryLabels/ScoreDisplay/Value
@onready var information: Label = $CanvasLayer/Control/SettingRect/CategoryLabels/Information

var value_nodes: Array

func _ready():
	button_array.append($CanvasLayer/Control/GameStartButton)
	button_array.append($CanvasLayer/Control/SettingButton)
	button_array.append($CanvasLayer/Control/GameEndButton)
	value_nodes = [speed_value, sound_offset_value, judge_offset_value, gamemode_value, score_display_value]
	index = 0
	_refresh_selection()
	InputManager.pressed_up.connect(_on_pressed_up)
	InputManager.pressed_down.connect(_on_pressed_down)
	InputManager.pressed_left.connect(_on_pressed_left)
	InputManager.pressed_right.connect(_on_pressed_right)
	InputManager.pressed_enter.connect(_on_pressed_enter)

func _refresh_selection():
	for i in range(button_array.size()):
		if i == index:
			button_array[i].activate()
		else:
			button_array[i].deactivate()

func _refresh_setting_selection():
	for i in range(value_nodes.size()):
		value_nodes[i].add_theme_color_override("font_color", Color(1.0, 0.275, 0.133, 1.0) if i == setting_index else Color(0, 0, 0))
	information.text = SETTING_INFO[setting_index]

# =================== 메인 메뉴 입력 ===================

func _on_pressed_up():
	if setting_open:
		setting_index = (setting_index - 1 + value_nodes.size()) % value_nodes.size()
		_refresh_setting_selection()
	else:
		index = (index - 1 + button_array.size()) % button_array.size()
		_refresh_selection()

func _on_pressed_down():
	if setting_open:
		setting_index = (setting_index + 1) % value_nodes.size()
		_refresh_setting_selection()
	else:
		index = (index + 1) % button_array.size()
		_refresh_selection()

func _on_pressed_left():
	if setting_open:
		_change_setting_value(false)

func _on_pressed_right():
	if setting_open:
		_change_setting_value(true)

func _on_pressed_enter():
	if setting_open:
		close_setting()
	else:
		button_array[index].emit_signal("pressed")

# =================== 설정 창 ===================

func _on_game_start():
	get_tree().change_scene_to_file("res://Scenes/SelectSong.tscn")

func _on_game_end():
	get_tree().quit()

func _on_enter_setting():
	Setting.load()
	_load_setting_values()
	setting_index = 0
	_refresh_setting_selection()
	settingRect.visible = true
	setting_open = true
	for button in button_array:
		button.disabled = true

func close_setting():
	settingRect.visible = false
	Setting.save()
	setting_open = false
	for button in button_array:
		button.disabled = false

func _load_setting_values():
	speed_value.text = "%.1f" % Setting.speed
	sound_offset_value.text = str(int(Setting.sound_offset))
	judge_offset_value.text = str(int(Setting.judge_offset))
	gamemode_value.text = _gamemode_to_string(Setting.gamemode)
	score_display_value.text = _score_display_to_string(Setting.score_display)

func _change_setting_value(increase: bool):
	match setting_index:
		SettingItem.Speed:
			Setting.speed = snappedf(clampf(Setting.speed + (0.1 if increase else -0.1), 0.5, 10.0), 0.1)
			speed_value.text = "%.1f" % Setting.speed
		SettingItem.SoundOffset:
			Setting.sound_offset = clampf(Setting.sound_offset + (1 if increase else -1), -1000, 1000)
			sound_offset_value.text = str(int(Setting.sound_offset))
		SettingItem.JudgeOffset:
			Setting.judge_offset = clampf(Setting.judge_offset + (1 if increase else -1), -1000, 1000)
			judge_offset_value.text = str(int(Setting.judge_offset))
		SettingItem.Gamemode:
			var modes = [Setting.GAMEMODE.Normal_Character, Setting.GAMEMODE.Normal_Line, Setting.GAMEMODE.Suregi]
			var cur = modes.find(Setting.gamemode)
			var target = (cur + (1 if increase else -1) + modes.size()) % modes.size()
			Setting.gamemode = modes[(cur + (1 if increase else -1) + modes.size()) % modes.size()]
			gamemode_value.text = _gamemode_to_string(Setting.gamemode)
			information.text = GAMEMODE_SETTING_INFO[target]
		SettingItem.ScoreDisplay:
			Setting.score_display = Setting.SCORE_DISPLAY.Increasing if Setting.score_display == Setting.SCORE_DISPLAY.Decreasing else Setting.SCORE_DISPLAY.Decreasing
			score_display_value.text = _score_display_to_string(Setting.score_display)

func _gamemode_to_string(mode) -> String:
	match mode:
		Setting.GAMEMODE.Normal_Character: return "TypeA"
		Setting.GAMEMODE.Normal_Line: return "TypeB"
		Setting.GAMEMODE.Suregi: return "TypeC"
	return ""

func _score_display_to_string(mode) -> String:
	match mode:
		Setting.SCORE_DISPLAY.Increasing: return "Increase"
		Setting.SCORE_DISPLAY.Decreasing: return "Decrease"
	return ""
