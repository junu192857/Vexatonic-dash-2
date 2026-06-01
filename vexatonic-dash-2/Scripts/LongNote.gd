extends Note
class_name LongNote

var is_holding_left := false
var is_holding_right := false

func get_marker() -> Note:
	for child in get_children():
		if child is Note:
			return child
	return null

func start_hold(is_left: bool) -> void:
	if is_left:
		is_holding_left = true
	else:
		is_holding_right = true

func release_hold(is_left: bool) -> void:
	if is_left:
		is_holding_left = false
	else:
		is_holding_right = false

func get_is_holding(is_left: bool) -> bool:
	return is_holding_left if is_left else is_holding_right

func is_holding_anyway() -> bool:
	return is_holding_left or is_holding_right
