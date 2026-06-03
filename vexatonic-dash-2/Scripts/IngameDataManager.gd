extends Node

const MAX_NOTE_SCORE = 1000000.0

var score
var score_per_note
var combo: int

signal status_updated(score: float, combo: int)

func catch_judgement(judgement: int, note: Note):
	match judgement:
		0: #Vexatonic
			score += score_per_note
		1: #Sparklic
			score += 0.9 * score_per_note
		2: #Wild
			score += 0.5 * score_per_note
			combo = 0
		3: #miss
			combo = 0
		_:
			push_error("Invalid judgement")
	status_updated.emit(score, combo)

func set_total_notes(noteDatas: Array[NoteData]):
	var single_count = noteDatas.filter(func(n): return n.type == 0).size()
	var long_count = noteDatas.filter(func(n): return n.type == 1).size()
	
	if (single_count + long_count != noteDatas.size()):
		push_error("Note count do not match")
	
	score_per_note = MAX_NOTE_SCORE / (single_count + 2 * long_count)
