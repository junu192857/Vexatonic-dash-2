extends Node2D

@export var tutorialHolder: Control
@export var live2d: TextureRect
@export var tutorial_script: Label
@export var tutorial_speaker: Label

var script_tween
var script_lines: Array[String] = []
var current_line: int = 0
var is_typing: bool = false

const SCRIPT_PATH = "res://Scripts/Tutorial/script.txt"
const CHARS_PER_SECOND = 30.0

func _ready() -> void:
	_load_script()
	tutorialHolder.visible = true
	InputManager.mouse_left_pressed.connect(_on_click)
	_show_line(current_line)

func _load_script():
	var file = FileAccess.open(SCRIPT_PATH, FileAccess.READ)
	if file == null:
		return
	while not file.eof_reached():
		var line = file.get_line()
		if not line.is_empty():
			script_lines.append(line)

func _show_line(index: int):
	if index >= script_lines.size():
		tutorialHolder.visible = false
		return
	var line = script_lines[index]
	is_typing = true
	typewrite(tutorial_script, line, line.length() / CHARS_PER_SECOND)
	script_tween.tween_callback(func(): is_typing = false)

func _on_click():
	if is_typing:
		force_typewrite(tutorial_script)
		is_typing = false
	else:
		current_line += 1
		_show_line(current_line)

func typewrite(label: Label, text: String, duration: float = 1.0):
	label.text = text
	label.visible_characters = 0
	script_tween = create_tween()
	script_tween.tween_property(label, "visible_characters", text.length(), duration)

func force_typewrite(label: Label):
	if script_tween and script_tween.is_valid():
		script_tween.kill()
	label.visible_characters = -1
