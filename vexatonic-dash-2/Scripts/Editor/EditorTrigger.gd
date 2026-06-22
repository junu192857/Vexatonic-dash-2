class_name EditorTrigger
extends Trigger

var position: Vector2
var node: Node2D

func select_trigger():
	var sprite: Sprite2D = node.get_child(0)
	sprite.modulate = Color(1,1,1)

func unselect_trigger():
	var sprite: Sprite2D = node.get_child(0)
	sprite.modulate = Color(0.5,0.5,0.5)
