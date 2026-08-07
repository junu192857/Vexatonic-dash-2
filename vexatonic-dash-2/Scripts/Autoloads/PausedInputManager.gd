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
