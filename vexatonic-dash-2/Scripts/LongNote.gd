extends Note
class_name LongNote

var is_holding_left := false
var is_holding_right := false
var long_connector: Connector = null
var hold_paint_from: float = 0.0
var hold_paint_until: float = 0.0
var visual_finalized: bool = false

func get_marker() -> Note:
	for child in get_children():
		if child is Note:
			return child
	return null

func set_long_connector(c: Connector) -> void:
	long_connector = c

func start_hold(is_left: bool, time: float) -> void:
	if (!is_holding_anyway() and long_connector and not visual_finalized):
		hold_paint_from = time if is_hit else long_connector.c_start_time
		long_connector.paint_range(hold_paint_from, time, true)
	if is_left:
		is_holding_left = true
	else:
		is_holding_right = true

func release_hold(is_left: bool) -> void:
	if (is_holding_anyway() and long_connector and not visual_finalized):
		if end_judged:
			long_connector.paint_range(hold_paint_from, long_connector.c_end_time, false)
	
	if is_left:
		is_holding_left = false
	else:
		is_holding_right = false
		
	

func get_is_holding(is_left: bool) -> bool:
	return is_holding_left if is_left else is_holding_right

func is_holding_anyway() -> bool:
	return is_holding_left or is_holding_right

func update_hold_visual(time: float) -> void:
	if long_connector == null or not is_holding_anyway() or visual_finalized:
		return
	hold_paint_until = time
	var paint_end: float
	if end_judged:
		paint_end = long_connector.c_end_time
		visual_finalized = true
	else:
		paint_end = hold_paint_until
	long_connector.paint_range(hold_paint_from, paint_end, false)
