extends Node

const MAX_NOTE_SCORE = 990000.0
const MAX_LONG_BONUS = 10000.0
const PLAY_DATA_PATH = "user://play_data.cfg"

enum ComboLamp { None = 0, FullCombo = 1, FullVexatonic = 2 }
enum Rank { None = 0, D = 1, C = 2, B = 3, A = 4, AA = 5, AAA = 6, S = 7, SS = 8, SSS = 9, V = 10 }

var score: float = 0
var score_per_note: float = 0
var combo: int
var total_long_length: float
var total_long_length_current: float
var pressed_long_length: float = 0.0
var pressed_note_count: int = 0
var vexatonic_count: int = 0
var _combo_lamp: ComboLamp = ComboLamp.FullVexatonic

signal status_updated(judgement: int, score: float, combo: int, note: Note, fastslow: Note.Fastslow)


func catch_judgement(judgement: int, note: Note, is_long_end: bool, fastslow: Note.Fastslow):
	match judgement:
		0: #Vexatonic
			score += score_per_note
			combo += 1
			vexatonic_count += 1
		1: #Sparklic
			score += 0.9 * score_per_note
			combo += 1
			if _combo_lamp == ComboLamp.FullVexatonic:
				_combo_lamp = ComboLamp.FullCombo
		2: #Wild
			score += 0.5 * score_per_note
			combo = 0
			_combo_lamp = ComboLamp.None
		3: #miss
			combo = 0
			_combo_lamp = ComboLamp.None
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
			status_updated.emit(judgement, current_score, combo, note, fastslow)
		Setting.SCORE_DISPLAY.Decreasing:
			var perfect_score = pressed_note_count * score_per_note + calculate_longNote_score(total_long_length_current)
			status_updated.emit(judgement, 1000000 - (perfect_score - current_score), combo, note, fastslow)
	

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
	
func _get_rank(final_score_int: int) -> Rank:
	if final_score_int >= 1000000:	return Rank.V
	if final_score_int >= 997500:	return Rank.SSS
	if final_score_int >= 995000:	return Rank.SS
	if final_score_int >= 990000:	return Rank.S
	if final_score_int >= 980000:	return Rank.AAA
	if final_score_int >= 970000:	return Rank.AA
	if final_score_int >= 950000:	return Rank.A
	if final_score_int >= 900000:	return Rank.B
	if final_score_int >= 750000:	return Rank.C
	return Rank.D


func on_song_end(chart_path: String) -> void:
	var final_score = roundi(score + calculate_longNote_score(pressed_long_length))
	var paint = roundi(calculate_longNote_score(pressed_long_length)) == 10000
	var rank = _get_rank(final_score)

	var cfg = ConfigFile.new()
	cfg.load(PLAY_DATA_PATH)
	var s = "%s|%d" % [chart_path, Setting.selected_difficulty]

	var old_score = cfg.get_value(s, "best_score", 0)
	var old_judge = cfg.get_value(s, "best_judge", 0)
	var old_lamp  = cfg.get_value(s, "combo_lamp", ComboLamp.None)
	var old_paint = cfg.get_value(s, "paint_lamp", false)
	var old_rank  = cfg.get_value(s, "rank",       Rank.None)

	if final_score > old_score:
		cfg.set_value(s, "best_score", final_score)
	if vexatonic_count > old_judge:
		cfg.set_value(s, "best_judge", vexatonic_count)
	if int(_combo_lamp) > old_lamp:
		cfg.set_value(s, "combo_lamp", int(_combo_lamp))
	if paint and not old_paint:
		cfg.set_value(s, "paint_lamp", true)
	if int(rank) > old_rank:
		cfg.set_value(s, "rank", int(rank))

	cfg.save(PLAY_DATA_PATH)
