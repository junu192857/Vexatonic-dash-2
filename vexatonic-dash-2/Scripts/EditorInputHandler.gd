extends Node

signal move_camera(delta: Vector2)
signal zoom_camera(zoom: int)

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
	
	if event is InputEventMouseMotion and dragging:
		var delta = event.position - drag_start
		drag_start = event.position
		move_camera.emit(delta)
			
