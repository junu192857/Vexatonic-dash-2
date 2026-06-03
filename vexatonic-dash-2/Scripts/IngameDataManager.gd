extends Node

const MAX_NOTE_SCORE = 990000.0
const MAX_LONG_BONUS = 10000.0

var score: float = 0
var score_per_note: float = 0
var combo: int
var total_long_length: float = 0.0
var pressed_long_length: float = 0.0

var test_processed_count = 0

signal status_updated(score: float, combo: int)

func catch_judgement(judgement: int, note: Note, is_long_end: bool):
	match judgement:
		0: #Vexatonic
			score += score_per_note
			combo += 1
		1: #Sparklic
			score += 0.9 * score_per_note
			combo += 1
		2: #Wild
			score += 0.5 * score_per_note
			combo = 0
		3: #miss
			combo = 0
		_:
			push_error("Invalid judgement")
	test_processed_count += 1
	
	if (is_long_end):
		total_long_length += (note.get_data().end_time - note.get_data().time)
		pressed_long_length += note.get_parent().total_pressed_time
		print("LongNote: currently %f / %f pressed" % [pressed_long_length, total_long_length])
	
	status_updated.emit(score, combo)

func set_total_notes(noteDatas: Array[NoteData]):
	var single_count = noteDatas.filter(func(n): return n.type == 0).size()
	var long_count = noteDatas.filter(func(n): return n.type == 1).size()
	
	if (single_count + long_count != noteDatas.size()):
		push_error("Note count do not match")
	
	score_per_note = MAX_NOTE_SCORE / (single_count + 2 * long_count)
