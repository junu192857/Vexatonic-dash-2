extends Node

var blocked: bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = PROCESS_MODE_WHEN_PAUSED

func _process(float):
	if blocked:
		blocked = false

signal pressed_l
signal pressed_enter
signal pressed_esc
signal pressed_a
signal pressed_d

func _input(event):
	if blocked:
		return
	if event is InputEventKey:
		match event.keycode:
			KEY_L:
				if event.pressed and not event.is_echo():
					pressed_l.emit()
			KEY_ENTER:
				if event.pressed and not event.is_echo():
					pressed_enter.emit()
			KEY_ESCAPE:
				if event.pressed and not event.is_echo():
					pressed_esc.emit()
			KEY_A:
				if event.pressed and not event.is_echo():
					pressed_a.emit()
			KEY_D:
				if event.pressed and not event.is_echo():
					pressed_d.emit()
