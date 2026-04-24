extends Node

signal note_pressed(note_color: int)

enum NoteColor { RED = 0, BLUE = 1, YELLOW = 2 }

		
func _input(event):
	if event.is_action_pressed("a") or \
	   event.is_action_pressed("l"):
		note_pressed.emit(NoteColor.RED)
	if event.is_action_pressed("s") or \
	   event.is_action_pressed("k"):
		note_pressed.emit(NoteColor.BLUE)
	if event.is_action_pressed("d") or \
	   event.is_action_pressed("j"):
		note_pressed.emit(NoteColor.YELLOW)
		
		
