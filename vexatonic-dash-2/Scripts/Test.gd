extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	InputHandler.note_pressed.connect(_on_pressed)

func _on_pressed(color: int):
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
