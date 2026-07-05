extends Node2D
class_name Note

const UNPROCESSED_COLORS: Array[Color] = [Color(1, 0.4, 0.4), Color(0.4, 0.4, 1.0),Color(1.0, 1.0, 0.4)]
const PROCESSED_COLORS: Array[Color] = [Color(0.8,0,0),Color(0.0, 0.0, 0.7),Color(0.8, 0.7, 0.0)]

const VEXATONIC_MS = 42
const SPARKLIC_MS = 84
const WILD_MS = 126

enum Judgement { VEXATONIC = 0, SPARKLIC = 1, WILD = 2, MISS = 3, PASS = 4 }
enum Fastslow { NOTHING = 0, FAST = 1, SLOW = 2 }
signal judgement_spread(judgement: int, note: Note, is_long_end: bool, fastslow: Fastslow)

@onready var sprite:Sprite2D = $Sprite2D

var data: NoteData

var is_hit := false
var is_marker
var end_judged := false

#=============== NoteData 값 가져오기 =======================
func get_time() -> float:
	return data.time

func get_color() -> int:
	return data.color

func get_type() -> int:
	return data.type

func get_end_time() -> float:
	return data.end_time

func get_lane() -> int:
	return data.lane

func set_data(p_data: NoteData):
	if (is_marker):
		get_parent().data = p_data
	else:
		data = p_data

func _ready() -> void:
	sprite.modulate = UNPROCESSED_COLORS[data.color]

func process_input(p_color: int, pressed_ms: float) -> int:
	print("Processing input: pressed time: %f, note time: %f" % [pressed_ms, data.time])
	if is_hit: return Judgement.PASS
	if data.color != p_color: return Judgement.PASS
	var deltaTime = pressed_ms - data.time
	if abs(deltaTime) > WILD_MS: return Judgement.PASS
	var judgement = (
		Judgement.VEXATONIC if abs(deltaTime) <= VEXATONIC_MS else
		Judgement.SPARKLIC if abs(deltaTime) <= SPARKLIC_MS else
		Judgement.WILD
	)
	var fs = (
		Fastslow.NOTHING if judgement == Judgement.VEXATONIC or judgement == Judgement.MISS else
		Fastslow.FAST if deltaTime < 0.0 else
		Fastslow.SLOW
	)
	process_color()
	is_hit = true
	spread_judgement(judgement, self, false, fs)
	return judgement

func process_color(): 
	sprite.modulate = PROCESSED_COLORS[get_data().color]

func spread_judgement(judgement: int, note: Note, is_long_end: bool, fastslow: Fastslow = Fastslow.NOTHING):
	judgement_spread.emit(judgement, note, is_long_end, fastslow)

func get_data() -> NoteData:
	if is_marker:
		return get_parent().data
	else:
		return data

# 롱노트 전용 메서드 스텁 — LongNote에서 오버라이드
func get_marker() -> Note:
	if (data.type != 1):
		return null
	for child in get_children():
		if child is Note:
			return child
	return null

func start_hold(_is_left: bool, _time: float, _start_adjust: bool) -> void: pass
func release_hold(_is_left: bool, _time: float) -> void: pass
func get_is_holding(_is_left: bool) -> bool: return false
func is_holding_anyway() -> bool: return false
func finalize_hold_time(_end_time: float) -> void: pass
