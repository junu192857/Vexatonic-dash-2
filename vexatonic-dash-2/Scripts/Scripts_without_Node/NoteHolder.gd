class_name NoteHolder

var notes: Array[Note]
var color
var current_index
var current_note

func _init(p_color: int):
	notes = []
	current_index = 0
	color = p_color

func sort_notes():
	notes.sort_custom(func(a:Note, b:Note):
		return a.get_data().time < b.get_data().time
	)
	if (not notes.is_empty()):
		current_note = notes[0]
		print("Set current note")

func check_miss(time: float):
	if (notes.size() - 1 < current_index):
		return
	if (current_note.missed(time)):
		#TODO: Judgement-Miss 전파하기
		move_to_next_note()

func process_input(time: float):
	if (notes.size() - 1 < current_index):
		return
	var judgement = current_note.process_input(color, time)
	if (0 <= judgement and judgement < 4):
		#TODO: Judgement 전파하기
		move_to_next_note()

func move_to_next_note():
	current_index += 1
	if (notes.size() -1 < current_index):
		return
	current_note = notes[current_index]
