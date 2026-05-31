extends Node

signal note_pressed(note_color: int, is_left: bool)
signal note_released(note_color: int, is_left: bool)
signal right_pressed(released: bool)

enum NoteColor { RED = 0, BLUE = 1, YELLOW = 2 }

const KEY_MAP = [
	["a", NoteColor.RED, true],
	["l", NoteColor.RED, false],
	["s", NoteColor.BLUE, true],
	["k", NoteColor.BLUE, false],
	["d", NoteColor.YELLOW, true],
	["j", NoteColor.YELLOW, false],
]

		
func _input(event):
	for entry in KEY_MAP:
		var action = entry[0]
		var color = entry[1]
		var is_left = entry[2]
		if event.is_action_pressed(action):
			note_pressed.emit(color, is_left)
		elif event.is_action_released(action):
			note_released.emit(color, is_left)
