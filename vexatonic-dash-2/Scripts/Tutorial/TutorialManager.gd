extends Node2D

@export var tutorialHolder: Control
@export var live2d: TextureRect
@export var tutorial_script: Label
@export var tutorial_speaker: Label

var script_tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func typewrite(label: Label, text: String, duration: float = 1.0):
	label.text = text
	label.visible_characters = 0
	
	script_tween = create_tween()
	script_tween.tween_property(label, "visible_characters", text.length(), duration)

func force_typerwite(label: Label):
	if script_tween and script_tween.is_valid():
		script_tween.kill()
	label.visible_characters = -1
