extends Note
class_name ENote

func _ready():
	return

const SELECTED_COLORS = [Color(1,0,1), Color(0,1,1), Color(1,1,0.7)]

func set_color(color: int):
	sprite.modulate = PROCESSED_COLORS[color]

func select_color():
	sprite.modulate = SELECTED_COLORS[data.color]
