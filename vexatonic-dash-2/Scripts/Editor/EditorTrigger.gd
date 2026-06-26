class_name EditorTrigger
extends Trigger

var editor_pos_y: float
var node: Node2D
var length_line: ColorRect
var sprite: Sprite2D

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

func show_length_line():
	if (type != Trigger.TYPE.BPM):
		length_line.size = Vector2(Setting.get_posx_from_time(t), 6.0)

func get_editor_position():
	return Vector2(Setting.get_posx_from_time(start), editor_pos_y)
