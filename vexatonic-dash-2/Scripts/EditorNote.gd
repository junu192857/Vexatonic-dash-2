extends Node2D

const UNPROCECSSED_COLORS: Array[Color] = [Color(1, 0.4, 0.4), Color(0.4, 0.4, 1.0),Color(1.0, 1.0, 0.4)]
const PROCESSED_COLORS: Array[Color] = [Color(0.8,0,0),Color(0.0, 0.0, 0.7),Color(0.8, 0.7, 0.0)]

@onready var sprite:Sprite2D = $Sprite2D

var data: NoteData

var is_hit := false


# 스포너에서 노트 생성 후 가장 먼저 호출되어 색상을 정함.
func set_data(p_data: NoteData):
	data = p_data

func set_color(color: int):
	sprite.modulate = PROCESSED_COLORS[color]
