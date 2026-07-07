extends Node

var button_array: Array
var index: int
@export var settingRect: TextureRect

func _ready():
	button_array.append($CanvasLayer/Control/GameStartButton)
	button_array.append($CanvasLayer/Control/SettingButton)
	button_array.append($CanvasLayer/Control/GameEndButton)
	index = 0

func _on_game_start():
	get_tree().change_scene_to_file("res://Scenes/SelectSong.tscn")

func _on_game_end():
	get_tree().quit()

func _on_enter_setting():
	settingRect.visible = true
