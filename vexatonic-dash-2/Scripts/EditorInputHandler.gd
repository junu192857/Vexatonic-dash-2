extends Node

signal move_camera(delta: Vector2)
signal zoom_camera(zoom: int)
signal move_preview(mouse_pos: Vector2)
signal put_note()

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
			
	if event is InputEventMouseMotion:
		if dragging:
			var delta = event.position - drag_start
			drag_start = event.position
			move_camera.emit(delta)
		else:
			move_preview.emit()
