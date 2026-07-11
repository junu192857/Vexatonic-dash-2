class_name GameStatus

var judgement: int
var score: float
var combo: int
var note: Note
var fastslow: Note.Fastslow
var combo_cut: bool = true

func _init(p_judgement: int, p_score: float, p_combo: int, p_note: Note, p_fastslow: Note.Fastslow, p_combo_cut: bool):
	judgement = p_judgement
	score = p_score
	combo = p_combo
	note = p_note
	fastslow = p_fastslow
	combo_cut = p_combo_cut
