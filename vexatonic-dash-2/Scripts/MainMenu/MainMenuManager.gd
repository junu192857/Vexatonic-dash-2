extends Node

var button_array: Array
var index: int
@export var settingRectScene: PackedScene
var settingRect

var setting_open: bool = false

func _ready():
	button_array.append($CanvasLayer/Control/GameStartButton)
	button_array.append($CanvasLayer/Control/SettingButton)
	button_array.append($CanvasLayer/Control/GameEndButton)

	index = 0
	_refresh_selection()
	InputManager.pressed_up.connect(_on_pressed_up)
	InputManager.pressed_down.connect(_on_pressed_down)
	InputManager.pressed_enter.connect(_on_pressed_enter)
	settingRect = settingRectScene.instantiate()
	$CanvasLayer/Control.add_child(settingRect)
	settingRect.visible = false
	settingRect.close_setting.connect(close_setting)

func _refresh_selection():
	for i in range(button_array.size()):
		if i == index:
			button_array[i].activate()
		else:
			button_array[i].deactivate()


# =================== 메인 메뉴 입력 ===================

func _on_pressed_up():
	if not setting_open:
		index = (index - 1 + button_array.size()) % button_array.size()
		_refresh_selection()

func _on_pressed_down():
	if not setting_open:
		index = (index + 1) % button_array.size()
		_refresh_selection()

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
	settingRect._initialize()
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
