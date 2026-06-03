extends Note
class_name LongNote

var is_holding_left := false
var is_holding_right := false
var hold_paint_from: float = 0.0
var hold_paint_until: float = 0.0
var visual_finalized: bool = false
var target_visual_connector: Connector = null

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
		hold_paint_from = get_data().time if start_adjust else time
		update_visual_polygon(time)

func release_hold(is_left: bool) -> void:
	if is_left:
		is_holding_left = false
	else:
		is_holding_right = false
		

func get_is_holding(is_left: bool) -> bool:
	return is_holding_left if is_left else is_holding_right

func is_holding_anyway() -> bool:
	return is_holding_left or is_holding_right

func update_visual_polygon(time: float):
	while (target_visual_connector != null and target_visual_connector.c_end_time < time):
		target_visual_connector = find_child_connector()
	target_visual_connector.make_new_polygon()

func update_hold_visual(to_time: float) -> void:
	var move_to_new_connector = false
	
	if not is_holding_anyway():
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
	if end_judged:
		target_visual_connector.paint_range(hold_paint_from, to_time)
		visual_finalized = true
		return
	target_visual_connector.paint_range(hold_paint_from, to_time)
	print("Try painting from %f, %f" % [hold_paint_from, to_time])
	
func find_child_connector():
	var child_connector = null
	for child in target_visual_connector.get_children():
		if child is Connector:
			child_connector = child
	return child_connector
