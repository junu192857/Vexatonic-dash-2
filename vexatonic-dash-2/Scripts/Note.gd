extends Node
class_name Note

const UNPROCECSSED_COLORS: Array[Color] = [Color(1, 0.4, 0.4), Color(0.4, 0.4, 1.0),Color(1.0, 1.0, 0.4)]
const PROCESSED_COLORS: Array[Color] = [Color(0.8,0,0),Color(0.0, 0.0, 0.7),Color(0.8, 0.7, 0.0)]

const VEXATONIC_MS = 40
const SPARKLIC_MS = 80
const WILD_MS = 120

enum Judgement { VEXATONIC = 0, SPARKLIC = 1, WILD = 2, MISS = 3, PASS = 4 }

@onready var sprite:Sprite2D = $Sprite2D

var data: NoteData

var is_hit := false

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
	data = p_data

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite.modulate = UNPROCECSSED_COLORS[data.color]

			
# 노트 처리하는 함수.
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
	return judgement
	
func process_color():
	sprite.modulate = PROCESSED_COLORS[data.color]
