extends Node2D

signal move_left
signal move_right
signal change_difficulty
signal game_start

func _input(event: InputEvent):
	if event.is_action_pressed("ui_left"):
		move_left.emit()
	elif event.is_action_pressed("ui_right"):
		move_right.emit()
	elif event.is_action_pressed("ui_focus_next"):
		change_difficulty.emit()
	elif event.is_action_pressed("ui_accept"):
		game_start.emit()
