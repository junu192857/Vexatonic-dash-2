extends LongNote
class_name ELongNote


func _ready():
	return

func set_color(color: int):
	sprite.modulate = PROCESSED_COLORS[color]

func select_color():
	sprite.modulate = SELECTED_COLORS[get_data().color]
