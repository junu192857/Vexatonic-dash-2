extends Node
class_name IngameDataManager

const MAX_NOTE_SCORE = 990000.0
const MAX_LONG_BONUS = 10000.0
const PLAY_DATA_PATH = "user://play_data.cfg"

enum ComboLamp { GameOver = 0, None = 1, FullCombo = 2, FullVexatonic = 3 }
enum Rank { None = 0, D = 1, C = 2, B = 3, A = 4, AA = 5, AAA = 6, S = 7, SS = 8, SSS = 9, V = 10 }
enum RankBorder { D = 0, C = 750000, B = 900000, A = 950000, AA = 970000, AAA = 980000, S = 990000, SS = 995000, SSS = 997500, V = 1000000 }



var score: float = 0
var score_per_note: float = 0
var combo: int
var total_long_length: float
var total_long_length_current: float
var pressed_long_length: float = 0.0
var pressed_note_count: int = 0
var total_note_calls: int = 0
var vexatonic_count: int = 0
var sparklic_count: int = 0
var wild_count: int = 0
var miss_count: int = 0
var track_skip_border: int = 0
var margin_applicable: bool = false
var _combo_lamp: ComboLamp = ComboLamp.FullVexatonic
var best_score_border: int = 0

signal status_updated(status: GameStatus)
signal all_notes_cleared
signal game_over_triggered

func _ready():
	_setup_track_skip()

func catch_judgement(judgement: int, note: Note, is_long_end: bool, fastslow: Note.Fastslow):
	match judgement:
		0: #Vexatonic
			score += score_per_note
			combo += 1
			vexatonic_count += 1
		1: #Sparklic
			score += 0.9 * score_per_note
			combo += 1
			sparklic_count += 1
			if _combo_lamp == ComboLamp.FullVexatonic:
				_combo_lamp = ComboLamp.FullCombo
		2: #Wild
			score += 0.5 * score_per_note
			combo = 0
			wild_count += 1
			_combo_lamp = ComboLamp.None
		3: #miss
			combo = 0
			miss_count += 1
			_combo_lamp = ComboLamp.None
		_:
			push_error("Invalid judgement")
			return
	
	pressed_note_count += 1
	
	if (is_long_end):
		pressed_long_length += note.get_parent().total_pressed_time
		total_long_length_current += note.get_data().end_time - note.get_data().time
	
	var current_score = score + calculate_longNote_score(pressed_long_length)
	var possible_score = get_possible_max(score, pressed_long_length)
	var margin = roundi(possible_score) - track_skip_border if margin_applicable else 0
	var status = GameStatus.new(judgement, current_score, possible_score, combo, note, fastslow, _combo_lamp == ComboLamp.None, margin_applicable, margin)
	status_updated.emit(status)

	if _combo_lamp != ComboLamp.GameOver and _check_track_skip(possible_score):
		_combo_lamp = ComboLamp.GameOver
		game_over_triggered.emit()
		return

	if total_note_calls > 0 and pressed_note_count >= total_note_calls:
		all_notes_cleared.emit()

		

# 트랙 스킵 관련 값들을 미리 계산. RhythmManager가 아니라 여기서 자체적으로 chart_path를 구해야
# _ready() 시점(= IngameUIManager._ready()보다 먼저)에 best_score_border까지 확정할 수 있음
func _setup_track_skip() -> void:
	if Setting.track_skip == Setting.TRACK_SKIP.BestScore:
		var chart_path = "res://Charts/Tutorial" if Setting.is_tutorial else Setting.selected_chart_dir
		var cfg = ConfigFile.new()
		if cfg.load(PLAY_DATA_PATH) == OK:
			var s = "%s|%d" % [chart_path, Setting.selected_difficulty]
			best_score_border = cfg.get_value(s, "best_score", 0)
	track_skip_border = _track_skip_border()
	margin_applicable = _is_score_based_track_skip()

func _is_score_based_track_skip() -> bool:
	return Setting.track_skip in [Setting.TRACK_SKIP.SSS, Setting.TRACK_SKIP.SS, Setting.TRACK_SKIP.S, Setting.TRACK_SKIP.BestScore]

func _track_skip_border() -> int:
	match Setting.track_skip:
		Setting.TRACK_SKIP.SSS: return RankBorder.SSS
		Setting.TRACK_SKIP.SS: return RankBorder.SS
		Setting.TRACK_SKIP.S: return RankBorder.S
		Setting.TRACK_SKIP.BestScore: return best_score_border
	return 0

# 현재 상태로 트랙 스킵 조건에 해당하는지 체크. FVPP/FV/FC는 콤보 램프 기준, 나머지는 possible_score 기준
func _check_track_skip(possible_score: float) -> bool:
	match Setting.track_skip:
		Setting.TRACK_SKIP.Off:
			return false
		Setting.TRACK_SKIP.FVPP:
			# Full Vexatonic이 깨졌거나, 지금부터 남은 롱노트를 전부 완벽히 잡아도 Perfect Paint(10000) 달성이 불가능한 경우
			if _combo_lamp != ComboLamp.FullVexatonic:
				return true
			var best_possible_pressed = pressed_long_length + (total_long_length - total_long_length_current)
			return roundi(calculate_longNote_score(best_possible_pressed)) != 10000
		Setting.TRACK_SKIP.FV:
			return _combo_lamp != ComboLamp.FullVexatonic
		Setting.TRACK_SKIP.FC:
			return _combo_lamp == ComboLamp.None
		Setting.TRACK_SKIP.SSS, Setting.TRACK_SKIP.SS, Setting.TRACK_SKIP.S, Setting.TRACK_SKIP.BestScore:
			return roundi(possible_score) < _track_skip_border()
	return false

func set_total_notes(noteDatas: Array[NoteData]):
	var single_count = noteDatas.filter(func(n): return n.type != 1).size()
	var long_notes = noteDatas.filter(func(n): return n.type == 1)
	var long_count = long_notes.size()
	total_long_length = long_notes.reduce(func(acc, n): return acc + n.end_time - n.time, 0.0)
	if (single_count + long_count != noteDatas.size()):
		push_error("Note count do not match")
	
	total_note_calls = single_count + 2 * long_count
	score_per_note = (MAX_NOTE_SCORE + MAX_LONG_BONUS) / total_note_calls if long_count == 0 else MAX_NOTE_SCORE / total_note_calls
	
func get_possible_max(note_score: float, pressed: float):
	return note_score + score_per_note * (total_note_calls - pressed_note_count) + \
		   calculate_longNote_score(total_long_length - total_long_length_current + pressed)

func calculate_longNote_score(pressed: float):
	if (total_long_length == 0): return 0
	var ratio = pressed / total_long_length
	if (ratio < 0.9):
		return ratio * 0.5 * MAX_LONG_BONUS
	else:
		return 0.45 * MAX_LONG_BONUS + (ratio - 0.9) * 5.5 * MAX_LONG_BONUS
	
func _get_rank(final_score_int: int) -> Rank:
	if final_score_int >= RankBorder.V:	return Rank.V
	if final_score_int >= RankBorder.SSS:	return Rank.SSS
	if final_score_int >= RankBorder.SS:	return Rank.SS
	if final_score_int >= RankBorder.S:	return Rank.S
	if final_score_int >= RankBorder.AAA:	return Rank.AAA
	if final_score_int >= RankBorder.AA:	return Rank.AA
	if final_score_int >= RankBorder.A:	return Rank.A
	if final_score_int >= RankBorder.B:	return Rank.B
	if final_score_int >= RankBorder.C:	return Rank.C
	return Rank.D

func on_song_end(chart_path: String) -> void:
	var final_score = roundi(score + calculate_longNote_score(pressed_long_length))
	var paint = roundi(calculate_longNote_score(pressed_long_length)) == 10000
	var paint_ratio = pressed_long_length / total_long_length if total_long_length > 0 else 1.0
	var rank = _get_rank(final_score)

	var cfg = ConfigFile.new()
	cfg.load(PLAY_DATA_PATH)
	var s = "%s|%d" % [chart_path, Setting.selected_difficulty]

	var old_score = cfg.get_value(s, "best_score", 0)
	var old_judge = cfg.get_value(s, "best_judge", 0)
	var old_lamp  = cfg.get_value(s, "combo_lamp", ComboLamp.None)
	var old_paint = cfg.get_value(s, "paint_lamp", false)
	var old_rank  = cfg.get_value(s, "rank",       Rank.None)
	var old_paint_ratio = cfg.get_value(s, "best_paint_ratio", 0.0)

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
	if paint_ratio > old_paint_ratio:
		cfg.set_value(s, "best_paint_ratio", paint_ratio)

	cfg.save(PLAY_DATA_PATH)

func get_result_data() -> Dictionary:
	var final_score = roundi(score + calculate_longNote_score(pressed_long_length))
	var paint_ratio = pressed_long_length / total_long_length if total_long_length > 0 else 1.0
	return {
		"score": final_score,
		"vexatonic": vexatonic_count,
		"sparklic": sparklic_count,
		"wild": wild_count,
		"miss": miss_count,
		"paint_ratio": paint_ratio,
		"perfect_paint": roundi(calculate_longNote_score(pressed_long_length)) == 10000,
		"combo_lamp": _combo_lamp,
		"rank": _get_rank(final_score),
	}
