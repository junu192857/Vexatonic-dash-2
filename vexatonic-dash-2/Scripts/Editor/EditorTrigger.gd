class_name EditorTrigger
extends Trigger

var editor_position: Vector2
var node: Node2D
var length_line: ColorRect
var sprite: Sprite2D

func select_trigger():
	sprite.modulate = Color(1,1,1)

func unselect_trigger():
	sprite.modulate = Color(0.5,0.5,0.5)

func _init(p_type: TYPE, p_start: float, p_c: float, p_t: float, p_position: Vector2) -> void:
	super(p_type, p_start, p_c, p_t)
	editor_position = p_position


func assign_node(p_node: Node2D):
	node = p_node
	length_line = node.get_child(0)
	sprite = node.get_child(1)

func show_length_line():
	length_line.size = Vector2(Setting.get_posx_from_time(t), 6.0)
