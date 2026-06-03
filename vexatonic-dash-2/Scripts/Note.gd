extends Node2D
class_name Note

const UNPROCESSED_COLORS: Array[Color] = [Color(1, 0.4, 0.4), Color(0.4, 0.4, 1.0),Color(1.0, 1.0, 0.4)]
const PROCESSED_COLORS: Array[Color] = [Color(0.8,0,0),Color(0.0, 0.0, 0.7),Color(0.8, 0.7, 0.0)]

const VEXATONIC_MS = 42
const SPARKLIC_MS = 84
const WILD_MS = 126

enum Judgement { VEXATONIC = 0, SPARKLIC = 1, WILD = 2, MISS = 3, PASS = 4 }

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
	var deltaTime = absf(pressed_ms - data.time)
	if deltaTime > WILD_MS: return Judgement.PASS
	var judgement = (
		Judgement.VEXATONIC if deltaTime <= VEXATONIC_MS else
		Judgement.SPARKLIC if deltaTime <= SPARKLIC_MS else
		Judgement.WILD
	)
	process_color()
	is_hit = true
	spread_judgement(judgement, self)
	return judgement

func process_color(): 
	sprite.modulate = PROCESSED_COLORS[get_data().color]

func spread_judgement(judgement: int, note: Note):
	print("Detect judgement: %d" % judgement)

func get_data() -> NoteData:
	if is_marker:
		return get_parent().data
	else:
		return data

# 롱노트 전용 메서드 스텁 — LongNote에서 오버라이드
func get_marker() -> Note: return null
func start_hold(_is_left: bool, _time: float, _start_adjust: bool) -> void: pass
func release_hold(_is_left: bool) -> void: pass
func get_is_holding(_is_left: bool) -> bool: return false
func is_holding_anyway() -> bool: return false
