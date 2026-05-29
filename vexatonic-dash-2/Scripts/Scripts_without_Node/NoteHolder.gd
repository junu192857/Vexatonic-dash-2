class_name NoteHolder

var notes: Array[Note]
var color
var current_index
var earliest_unprocessed_index
var current_note

func _init(p_color: int):
	notes = []
	current_index = 0
	earliest_unprocessed_index = 0
	color = p_color

func sort_notes():
	notes.sort_custom(func(a:Note, b:Note):
		return a.get_data().time < b.get_data().time
	)
	if (not notes.is_empty()):
		current_note = notes[0]
		print("Set current note")

func check_miss(time: float):
	if (notes.size() - 1 < current_index): #모든 노트 처리 완료
		return
	
	check_current_note(time)
	
	while earliest_unprocessed_index < current_index:
		if notes[earliest_unprocessed_index].missed(time):
			#Judgement_Miss 처리
			earliest_unprocessed_index += 1
		elif notes[earliest_unprocessed_index].is_hit:
			earliest_unprocessed_index += 1
		else:
			break
	
	if (current_note.missed(time)):
		#TODO: Judgement_Miss 처리
		move_to_next_note()
	

func check_current_note(time:float):
	if (notes.size() - 2 < current_index):
		return
	var next_note = notes[current_index + 1]
	if (next_note.get_data().time - time < time - current_note.get_data().time):
		move_to_next_note()

func process_input(time: float):
	if (notes.size() - 1 < current_index): # 모든 노트 처리 완료
		return
	var judgement = current_note.process_input(color, time)
	if (0 <= judgement and judgement < 4):
		if (earliest_unprocessed_index == current_index):
			earliest_unprocessed_index += 1
		#TODO: Judgement 전파하기
		move_to_next_note()

func move_to_next_note():
	current_index += 1
	if (notes.size() -1 < current_index):
		return
	current_note = notes[current_index]
