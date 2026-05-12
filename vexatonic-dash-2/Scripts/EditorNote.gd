extends Note
class_name ENote

func _ready():
	return

# 스포너에서 노트 생성 후 가장 먼저 호출되어 색상을 정함.
func set_data(p_data: NoteData):
	data = p_data

func set_color(color: int):
	sprite.modulate = PROCESSED_COLORS[color]
