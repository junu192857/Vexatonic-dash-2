extends Note
class_name LongNote

var is_holding_left := false
var is_holding_right := false
var long_connector: Connector = null
var hold_paint_from: float = 0.0
var hold_paint_until: float = 0.0
var visual_finalized: bool = false
var target_visual_connector: Connector = null

func get_marker() -> Note:
	for child in get_children():
		if child is Note:
			return child
	return null

func set_long_connector(c: Connector) -> void:
	long_connector = c

func start_hold(is_left: bool, time: float, start_adjust: bool) -> void:
	var before = is_holding_anyway()
	if is_left:
		is_holding_left = true
	else:
		is_holding_right = true
	if (not before and is_holding_anyway()):
		hold_paint_from = get_data().time if start_adjust else time

func release_hold(is_left: bool) -> void:
	var before = is_holding_anyway()
	if is_left:
		is_holding_left = false
	else:
		is_holding_right = false
	if (before and not is_holding_anyway() and long_connector):
		long_connector.make_new_polygon()
		print("Move to new polygon")
		

func get_is_holding(is_left: bool) -> bool:
	return is_holding_left if is_left else is_holding_right

func is_holding_anyway() -> bool:
	return is_holding_left or is_holding_right


func update_hold_visual(to_time: float) -> void:
	if long_connector == null or visual_finalized:
		return
	if end_judged:
		long_connector.paint_range(hold_paint_from, to_time)
		visual_finalized = true
		return
	if not is_holding_anyway():
		return
	long_connector.paint_range(hold_paint_from, to_time)
