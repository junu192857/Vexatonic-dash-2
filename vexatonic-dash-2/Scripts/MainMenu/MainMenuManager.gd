extends Node

var button_array: Array
var index: int
@export var settingRectScene: PackedScene
var settingRect
@export var goTutorialPanel: TextureRect
enum MainMenuState {Main, SettingOpen, EnteringTutorial }
var state : MainMenuState

func _ready():
	button_array.append($CanvasLayer/Control/GameStartButton)
	button_array.append($CanvasLayer/Control/SettingButton)
	button_array.append($CanvasLayer/Control/GameEndButton)
	index = 0
	_refresh_selection()
	InputManager.pressed_up.connect(_on_pressed_up)
	InputManager.pressed_down.connect(_on_pressed_down)
	InputManager.pressed_enter.connect(_on_pressed_enter)
	InputManager.pressed_esc.connect(_on_pressed_esc)
	settingRect = settingRectScene.instantiate()
	$CanvasLayer/Control.add_child(settingRect)
	settingRect.visible = false
	settingRect.close_setting.connect(close_setting)
	state = MainMenuState.Main

func _refresh_selection():
	for i in range(button_array.size()):
		if i == index:
			button_array[i].activate()
		else:
			button_array[i].deactivate()


# =================== 메인 메뉴 입력 ===================

func _on_pressed_up():
	if state == MainMenuState.Main:
		index = (index - 1 + button_array.size()) % button_array.size()
		_refresh_selection()

func _on_pressed_down():
	if state == MainMenuState.Main:
		index = (index + 1) % button_array.size()
		_refresh_selection()

func _on_pressed_enter():
	if state == MainMenuState.SettingOpen:
		close_setting()
	elif state == MainMenuState.EnteringTutorial:
		_on_tutorial_start()
	else:
		match index:
			0:
				_on_game_start()
			1:
				_on_enter_setting()
			2:
				_on_game_end()

func _on_pressed_esc():
	if state == MainMenuState.SettingOpen:
		close_setting()
	elif state == MainMenuState.EnteringTutorial:
		close_tutorial_warning()
		_on_game_start()

# =================== 설정 창 ===================

func _on_game_start():
	if (!Setting.tutorial_played):
		open_tutorial_warning()
	else:
		Setting.is_tutorial = false
		get_tree().change_scene_to_file("res://Scenes/SelectSong.tscn")

func _on_tutorial_start():
	Setting.is_tutorial = true
	Setting.speed = 1.0
	Setting.gamemode = Setting.GAMEMODE.Normal_Character
	get_tree().change_scene_to_file("res://Scenes/TutorialScene.tscn")

func _on_game_end():
	get_tree().quit()

func _on_enter_setting():
	Setting.load()
	settingRect._initialize()
	settingRect.visible = true
	state = MainMenuState.SettingOpen

func open_tutorial_warning():
	Setting.tutorial_played = true
	goTutorialPanel.visible = true
	state = MainMenuState.EnteringTutorial

func close_tutorial_warning():
	goTutorialPanel.visible = false
	state = MainMenuState.Main

func close_setting():
	settingRect.visible = false
	Setting.save()
	state = MainMenuState.Main
