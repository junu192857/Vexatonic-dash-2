extends Node2D

signal change_difficulty
signal move_left
signal move_right
signal game_start
signal setting_select_down
signal setting_select_up
signal setting_decrease
signal setting_increase

func _input(event: InputEvent):
	if event is InputEventKey:
		if event.keycode == KEY_TAB and event.pressed:
			change_difficulty.emit()
		elif event.keycode == KEY_A and event.pressed:
			move_left.emit()
		elif event.keycode == KEY_D and event.pressed:
			move_right.emit()
		elif event.keycode == KEY_ENTER and event.pressed:
			game_start.emit()
		elif event.keycode == KEY_DOWN and event.pressed:
			setting_select_down.emit()
		elif event.keycode == KEY_UP and event.pressed:
			setting_select_up.emit()
		elif event.keycode == KEY_LEFT and event.pressed:
			setting_decrease.emit()
		elif event.keycode == KEY_RIGHT and event.pressed:
			setting_increase.emit()
