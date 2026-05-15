extends Note
class_name ENote

func _ready():
	return

func set_color(color: int):
	sprite.modulate = PROCESSED_COLORS[color]
