class_name EditorTrigger
extends Trigger

var editor_pos_y: float
var node: Node2D
var length_line: Line2D
var sprite: Sprite2D
var bpmText: Label

func select_trigger():
	sprite.modulate = Color(1,1,1)

func unselect_trigger():
	sprite.modulate = Color(0.5,0.5,0.5)

func _init(p_type: TYPE, p_start: float, p_c: float, p_t: float, p_y: float) -> void:
	super(p_type, p_start, p_c, p_t)
	editor_pos_y = p_y


func assign_node(p_node: Node2D):
	node = p_node
	if (type != Trigger.TYPE.BPM):
		length_line = node.get_child(0)
		sprite = node.get_child(1)
	else:
		sprite = node.get_child(0)
		bpmText = node.get_child(1)

func show_data():
	match (type):
		Trigger.TYPE.Move:
			length_line.points = PackedVector2Array([
				Vector2(0, 0),
				Vector2(Setting.get_posx_from_time(t), c)
			])
		Trigger.TYPE.Zoom:
			length_line.points = PackedVector2Array([
				Vector2(0,0),
				Vector2(Setting.get_posx_from_time(t), 0)
			])
		Trigger.TYPE.BPM:
			bpmText.text = "%.2f" % c

func show_line_preview(end_global_point: Vector2):
	match(type):
		Trigger.TYPE.Move:
			length_line.points = PackedVector2Array([
				Vector2(0,0),
				end_global_point - node.position
			])
		Trigger.TYPE.Zoom:
			length_line.points = PackedVector2Array([
				Vector2(0,0),
				Vector2.RIGHT * (end_global_point.x - node.position.x)
			])
		_:
			return

func set_new_data():
	editor_pos_y = node.global_position.y
	match(type):
		Trigger.TYPE.Move:
			c = length_line.points[1].y
			t = Setting.get_time_from_posx(length_line.points[1].x)
		Trigger.TYPE.Zoom:
			t = Setting.get_time_from_posx(length_line.points[1].x)
		_:
			return

func get_editor_position():
	return Vector2(Setting.get_posx_from_time(start), editor_pos_y)
