extends Node

var button_array: Array
var index: int
@export var settingRect: TextureRect

func _ready():
	button_array.append($CanvasLayer/Control/GameStartButton)
	button_array.append($CanvasLayer/Control/SettingButton)
	button_array.append($CanvasLayer/Control/GameEndButton)
	index = 0
	_refresh_selection()
	InputManager.pressed_up.connect(_on_menu_select_up)
	InputManager.pressed_down.connect(_on_menu_select_down)
	InputManager.pressed_enter.connect(_on_menu_confirm)

func _refresh_selection():
	for i in range(button_array.size()):
		if i == index:
			button_array[i].activate()
		else:
			button_array[i].deactivate()

func _on_menu_select_up():
	index = (index - 1 + button_array.size()) % button_array.size()
	_refresh_selection()

func _on_menu_select_down():
	index = (index + 1) % button_array.size()
	_refresh_selection()

func _on_menu_confirm():
	button_array[index].emit_signal("pressed")

func _on_game_start():
	get_tree().change_scene_to_file("res://Scenes/SelectSong.tscn")

func _on_game_end():
	get_tree().quit()

func _on_enter_setting():
	settingRect.visible = true
