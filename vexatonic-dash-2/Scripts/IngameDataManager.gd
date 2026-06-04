extends Node

const MAX_NOTE_SCORE = 990000.0
const MAX_LONG_BONUS = 10000.0

var score: float = 0
var score_per_note: float = 0
var combo: int
var total_long_length: float
var total_long_length_current: float
var pressed_long_length: float = 0.0
var pressed_note_count: int = 0


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
			return
	
	pressed_note_count += 1
	
	if (is_long_end):
		pressed_long_length += note.get_parent().total_pressed_time
		total_long_length_current += note.get_data().end_time - note.get_data().time
	
	var current_score = score + calculate_longNote_score(pressed_long_length)
	
	match Setting.score_display:
		Setting.SCORE_DISPLAY.Increasing:
			status_updated.emit(judgement, current_score, combo, note)
		Setting.SCORE_DISPLAY.Decreasing:
			var perfect_score = pressed_note_count * score_per_note + calculate_longNote_score(total_long_length_current)
			status_updated.emit(judgement, 1000000 - (perfect_score - current_score), combo, note)
	

func set_total_notes(noteDatas: Array[NoteData]):
	var single_count = noteDatas.filter(func(n): return n.type == 0).size()
	var long_notes = noteDatas.filter(func(n): return n.type == 1)
	var long_count = long_notes.size()
	total_long_length = long_notes.reduce(func(acc, n): return acc + n.end_time - n.time, 0.0)
	print("total_long_length = %f" % total_long_length)
	if (single_count + long_count != noteDatas.size()):
		push_error("Note count do not match")
	
	score_per_note = MAX_NOTE_SCORE / (single_count + 2 * long_count)
	
func calculate_longNote_score(pressed: float):
	var ratio = pressed / total_long_length
	if (ratio < 0.9):
		return ratio * 5000
	else:
		return 4500 + (ratio - 0.9) * 55000
	
