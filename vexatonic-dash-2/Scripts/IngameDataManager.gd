extends Node

const MAX_NOTE_SCORE = 990000.0
const MAX_LONG_BONUS = 10000.0

var score: float = 0
var score_per_note: float = 0
var long_adjusted: float = 0
var combo: int
var total_long_length: float = 0.0
var pressed_long_length: float = 0.0


signal status_updated(judgement: int, score: float, combo: int, note: Note)

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
	
	if (is_long_end):
		pressed_long_length += note.get_parent().total_pressed_time
		long_adjusted = pow(pressed_long_length / total_long_length, 5) * 10000
	
	status_updated.emit(judgement, score + long_adjusted, combo, note)

func set_total_notes(noteDatas: Array[NoteData]):
	var single_count = noteDatas.filter(func(n): return n.type == 0).size()
	var long_notes = noteDatas.filter(func(n): return n.type == 1)
	var long_count = long_notes.size()
	var total_long_length = long_notes.reduce(func(acc, n): return acc + n.get_data().end_time() - n.get_data().start_time(), 0.0)
	
	if (single_count + long_count != noteDatas.size()):
		push_error("Note count do not match")
	
	score_per_note = MAX_NOTE_SCORE / (single_count + 2 * long_count)
	
	total_long_length = long_count.sum()
