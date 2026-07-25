extends Node2D

@export var tutorialHolder: Control
@export var live2d: TextureRect
@export var tutorial_script: Label
@export var tutorial_speaker: Label

var script_tween
var script_lines: Array[String] = []
var current_line: int = 0
var is_typing: bool = false

var phases: Array[Callable] = [
	start_explanation,
	start_tutorial_play,
	hide_live2D,
	show_live2D
]

const SCRIPT_PATH = "res://Scripts/Tutorial/script.txt"
const CHARS_PER_SECOND = 30.0

func _ready() -> void:
	await get_tree().process_frame
	$TutorialBGMPlayer.play()
	_load_script()
	start_explanation()
	

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
		return
	var line = script_lines[index]
	var parts = line.split(" ")
	if (parts[0]) == "PHASE":
		current_line += 1
		index = int(parts[1])
		if (index < 4):
			phases[index].call()
		else:
			match(index):
				4:
					change_live2D(0 if parts.size() < 3 else int(parts[2]))
				_:
					push_error("argument tarimasen for special phase")
		return
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
	script_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	script_tween.tween_property(label, "visible_characters", text.length(), duration)

func force_typewrite(label: Label):
	if script_tween and script_tween.is_valid():
		script_tween.kill()
	label.visible_characters = -1



func start_explanation():
	InputManager.mouse_left_pressed.connect(_on_click)
	get_tree().paused = true
	tutorialHolder.visible = true
	_show_line(current_line)

func start_tutorial_play():
	if InputManager.mouse_left_pressed.is_connected(_on_click):
		InputManager.mouse_left_pressed.disconnect(_on_click)
	tutorialHolder.visible = false
	get_tree().paused = false

func hide_live2D():
	tutorialHolder.get_node("Live2D").visible = false
	_show_line(current_line)

func show_live2D():
	tutorialHolder.get_node("Live2D").visible = true
	_show_line(current_line)

func change_live2D(index: int):
	match(index):
		0:
			live2d.texture = load("res://Textures/Sayane_Live2D.png")
		_:
			pass
	show_live2D()
