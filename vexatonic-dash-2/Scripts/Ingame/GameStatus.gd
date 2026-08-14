class_name GameStatus

var judgement: int
var score: float
var possible_score: float
var combo: int
var note: Note
var fastslow: Note.Fastslow
var combo_cut: bool = true
# 트랙 스킵이 랭크/최고기록 기준일 때만 유효 (FVPP/FV/FC 등은 점수 기반이 아니므로 false)
var track_skip_margin_applicable: bool = false
var track_skip_margin: int = 0

func _init(p_judgement: int, p_score: float, p_possible_score: float, p_combo: int, p_note: Note, p_fastslow: Note.Fastslow, p_combo_cut: bool, p_track_skip_margin_applicable: bool = false, p_track_skip_margin: int = 0):
	judgement = p_judgement
	score = p_score
	possible_score = p_possible_score
	combo = p_combo
	note = p_note
	fastslow = p_fastslow
	combo_cut = p_combo_cut
	track_skip_margin_applicable = p_track_skip_margin_applicable
	track_skip_margin = p_track_skip_margin
