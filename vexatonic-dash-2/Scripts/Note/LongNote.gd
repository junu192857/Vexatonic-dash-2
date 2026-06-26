extends Note
class_name LongNote

var is_holding_left := false
var is_holding_right := false
var hold_paint_from: float = 0.0
var hold_paint_until: float = 0.0
var last_press_start: float = 0.0
var total_pressed_time: float = 0.0
var visual_finalized: bool = false
var target_visual_connector: Connector = null

# 동타 보정을 위한 값. 0: 클릭 없음, 1: 왼쪽, 2: 오른쪽
var previously_clicked: int = 0

func get_marker() -> Note:
	for child in get_children():
		if child is Note:
			return child
	return null

func set_target_connector(connector: Connector):
	target_visual_connector = connector

func start_hold(is_left: bool, time: float, start_adjust: bool) -> void:
	var before = is_holding_anyway()
	if is_left:
		is_holding_left = true
	else:
		is_holding_right = true
	if (not before and is_holding_anyway()):
		if (start_adjust):
			last_press_start = get_data().time
			hold_paint_from = target_visual_connector.c_start_time
		last_press_start = get_data().time if start_adjust else time
		hold_paint_from = target_visual_connector.c_start_time if start_adjust else time
		update_visual_polygon(time)
		

func release_hold(is_left: bool, time: float) -> void:
	var before = is_holding_anyway()
	if is_left:
		is_holding_left = false
	else:
		is_holding_right = false
	if before and not is_holding_anyway() and not end_judged:
		finalize_hold_time(time)

func finalize_hold_time(end_time: float) -> void:
	last_press_start = clamp(last_press_start, get_data().time, get_data().end_time)
	end_time = clamp(end_time, get_data().time, get_data().end_time)
	
	var pressed_time = end_time - last_press_start
	if (pressed_time > 0.0):
		total_pressed_time += end_time - last_press_start
		

func get_is_holding(is_left: bool) -> bool:
	return is_holding_left if is_left else is_holding_right

func is_holding_anyway() -> bool:
	return is_holding_left or is_holding_right

func update_visual_polygon(time: float):
	while (target_visual_connector != null and target_visual_connector.c_end_time < time):
		target_visual_connector = find_child_connector()
	if (target_visual_connector):
		target_visual_connector.make_new_polygon()

func update_hold_visual(to_time: float) -> void:
	var move_to_new_connector = false
	
	if (not is_holding_anyway() or end_judged):
		return
	
	while (target_visual_connector != null and to_time > target_visual_connector.c_end_time):
		target_visual_connector.paint_range(hold_paint_from, target_visual_connector.c_end_time)
		hold_paint_from = target_visual_connector.c_end_time
		target_visual_connector = find_child_connector()
		print("moved to child connector")
		move_to_new_connector = true
	if (target_visual_connector != null and move_to_new_connector):
		target_visual_connector.make_new_polygon()
	
	if target_visual_connector == null or visual_finalized:
		return

	target_visual_connector.paint_range(hold_paint_from, to_time)


func update_last_hold_visual():
	while (target_visual_connector != null):
		target_visual_connector.paint_range(hold_paint_from, target_visual_connector.c_end_time)
		hold_paint_from = target_visual_connector.c_end_time
		target_visual_connector = find_child_connector()
		if (target_visual_connector != null):
			target_visual_connector.make_new_polygon()
	visual_finalized = true
	return
	

func find_child_connector():
	var child_connector = null
	for child in target_visual_connector.get_children():
		if child is Connector:
			child_connector = child
	return child_connector
	
