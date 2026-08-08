extends Node


@export var settingRectScene: PackedScene
@export var storyManager: Control

var button_array: Array
var index: int
var settingRect

enum MainMenuState {Main, SettingOpen}
var state : MainMenuState

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	button_array = $CanvasLayer/Control/MainMenuButtons.get_children()
	index = 0
	_refresh_selection()
	InputManager.pressed_up.connect(_on_pressed_up)
	InputManager.pressed_down.connect(_on_pressed_down)
	InputManager.pressed_enter.connect(_on_pressed_enter)
	InputManager.pressed_esc.connect(_on_pressed_esc)
	InputManager.pressed_a.connect(open_random_conversation)
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
	else:
		match index:
			0:
				_on_game_start()
			1:
				_on_enter_setting()
			2:
				_on_game_end()
			3:
				open_random_conversation()

func _on_pressed_esc():
	if state == MainMenuState.SettingOpen:
		close_setting()

# =================== 설정 창 ===================

func _on_game_start():
	if (true):
		open_tutorial_warning()
	else:
		Setting.is_tutorial = false
		get_tree().change_scene_to_file("res://Scenes/SelectSong.tscn")

func _on_tutorial_start():
	Setting.is_tutorial = true
	Setting.speed = 1.0
	Setting.gamemode = Setting.GAMEMODE.Normal_Character
	await TransitionOverlay.close()
	get_tree().change_scene_to_file("res://Scenes/RhythmScene.tscn")

func _on_game_end():
	get_tree().quit()

func _on_enter_setting():
	Setting.load()
	settingRect._initialize()
	settingRect.visible = true
	state = MainMenuState.SettingOpen

func open_tutorial_warning():
	Setting.tutorial_played = true
	if (not storyManager._on_select_left.is_connected(_on_tutorial_start)):
		storyManager._on_select_left.connect(_on_tutorial_start)
	storyManager.start_story("res://Scripts/MainMenu/GoTutorial.txt", true)

func close_setting():
	settingRect.visible = false
	Setting.save()
	state = MainMenuState.Main

func open_random_conversation():
	var random_int = randi() % 3
	storyManager.start_story("res://Scripts/MainMenu/RandomConversation/%d.txt" % random_int, true)
