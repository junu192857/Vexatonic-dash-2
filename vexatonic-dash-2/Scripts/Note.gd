extends Node2D
class_name Note

const UNPROCESSED_COLORS: Array[Color] = [Color(1, 0.4, 0.4), Color(0.4, 0.4, 1.0),Color(1.0, 1.0, 0.4)]
const PROCESSED_COLORS: Array[Color] = [Color(0.8,0,0),Color(0.0, 0.0, 0.7),Color(0.8, 0.7, 0.0)]

const VEXATONIC_MS = 40
const SPARKLIC_MS = 80
const WILD_MS = 120

enum Judgement { VEXATONIC = 0, SPARKLIC = 1, WILD = 2, MISS = 3, PASS = 4 }

@onready var sprite:Sprite2D = $Sprite2D

var data: NoteData

var is_hit := false
var is_marker
var is_holding := false  # 롱노트: 현재 키가 눌려 있는지
var end_judged := false  # 롱노트: 끝점 판정 완료 여부

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

# 스포너에서 노트 생성 후 가장 먼저 호출되어 색상을 정함.
func set_data(p_data: NoteData):
	if (is_marker):
		get_parent().data = p_data
	else:
		data = p_data

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite.modulate = UNPROCESSED_COLORS[data.color]


# 단노트 처리
func process_input(p_color: int, pressed_ms: float) -> int:
	if is_hit:
		return Judgement.PASS
	if (data.color != p_color):
		return Judgement.PASS

	var deltaTime = absf(pressed_ms - data.time)
	if (deltaTime > WILD_MS):
		return Judgement.PASS

	var judgement = (
		Judgement.VEXATONIC if deltaTime <= VEXATONIC_MS else
		Judgement.SPARKLIC if deltaTime <= SPARKLIC_MS else
		Judgement.WILD
	)
	process_color()
	is_hit = true
	print("Hello! Your Judgement is %d" % judgement)
	spread_judgement(judgement, self)
	return judgement

# 롱노트 시작점 판정. 윈도우 밖이더라도 is_holding은 항상 true로 설정.
func process_long_press(p_color: int, pressed_ms: float) -> int:
	if data.color != p_color:
		return Judgement.PASS
	is_holding = true
	if is_hit:
		return Judgement.PASS  # 시작점 이미 판정됨
	var deltaTime = absf(pressed_ms - data.time)
	if deltaTime > WILD_MS:
		return Judgement.PASS  # 윈도우 밖 — holding만 설정
	is_hit = true
	process_color()
	var judgement = (
		Judgement.VEXATONIC if deltaTime <= VEXATONIC_MS else
		Judgement.SPARKLIC if deltaTime <= SPARKLIC_MS else
		Judgement.WILD
	)
	print("Long note start! Judgement: %d" % judgement)
	spread_judgement(judgement, self)
	return judgement

# 롱노트 끝점 판정 (키 릴리즈). end_time - WILD_MS ~ end_time 사이 릴리즈 시 VEXATONIC.
func process_long_release(p_color: int, released_ms: float) -> int:
	if data.color != p_color or end_judged:
		return Judgement.PASS
	is_holding = false
	var delta = released_ms - data.end_time
	if delta >= -WILD_MS and delta <= 0:
		end_judged = true
		print("Long note end! VEXATONIC from release")
		get_marker().process_color()
		spread_judgement(Judgement.VEXATONIC, get_marker())
		return Judgement.VEXATONIC
	return Judgement.PASS

# 매 프레임 끝점 상태 체크. end_time 도달 시 holding이면 VEXATONIC, 아니면 MISS.
func check_long_end(time: float) -> int:
	if end_judged:
		return Judgement.PASS
	if time >= data.end_time:
		end_judged = true
		if not is_hit:
			is_hit = true
		if is_holding:
			print("Long note end! VEXATONIC from hold")
			get_marker().process_color()
			spread_judgement(Judgement.VEXATONIC, get_marker())
			return Judgement.VEXATONIC
		else:
			print("Long note end! MISS")
			spread_judgement(Judgement.MISS, get_marker())
			return Judgement.MISS
	return Judgement.PASS

func process_color():
	sprite.modulate = PROCESSED_COLORS[get_data().color]

func missed(time: float) -> bool:
	if get_data().type == 1:
		# 롱노트: 시작점 윈도우가 지났으면 시작점 Miss
		if get_data().time + WILD_MS < time and !is_hit:
			is_hit = true
			spread_judgement(Judgement.MISS, self)
			return true
		return false
	# 단노트
	if get_data().time + WILD_MS < time and !is_hit:
		is_hit = true
		spread_judgement(Judgement.MISS, self)
		return true
	return false

func spread_judgement(judgement: int, note: Note):
	print("Detect judgement: %d" % judgement)

func get_marker() -> Note:
	if is_marker:
		return null
	for child in get_children():
		if child is Note:
			return child
	return null

func get_data() -> NoteData:
	if is_marker:
		return get_parent().data
	else:
		return data
