extends Node

signal move_camera(delta: Vector2)
signal zoom_camera(zoom: int)
signal move_preview(mouse_pos: Vector2)
signal put_note()
signal delete_something()
signal toggle_shifting(pressed: bool)
signal move_to_last_note()
signal move_camera_horizontally(is_left: bool)

var dragging = false
var drag_start: Vector2

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
			drag_start = event.position
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera.emit(true)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera.emit(false)
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			put_note.emit()
	
	if event is InputEventKey:
		if event.keycode == KEY_DELETE and event.pressed:
			delete_something.emit()
		if event.keycode == KEY_SHIFT:
			toggle_shifting.emit(event.pressed)
		if event.keycode == KEY_F and event.pressed:
			move_to_last_note.emit()
		if event.keycode == KEY_A and event.pressed:
			move_camera_horizontally.emit(true)
		if event.keycode == KEY_D and event.pressed:
			move_camera_horizontally.emit(false)
			
	if event is InputEventMouseMotion:
		if dragging:
			var delta = event.position - drag_start
			drag_start = event.position
			move_camera.emit(delta)
		else:
			move_preview.emit()
