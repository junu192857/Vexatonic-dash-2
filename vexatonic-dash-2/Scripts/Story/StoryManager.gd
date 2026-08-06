extends Control

@export var storyHolder: Control
@export var live2d: TextureRect
@export var story_script: Label
@export var enter_label: Label
@export var story_speaker: Label
@export var script_path: String

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
const CHARS_PER_SECOND = 30.0

func _ready() -> void:
	await get_tree().process_frame
	_load_script()

func _load_script():
	var file = FileAccess.open(script_path, FileAccess.READ)
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
	typewrite(story_script, line, line.length() / CHARS_PER_SECOND)
	script_tween.tween_callback(func(): is_typing = false)

func _on_click():
	if is_typing:
		force_typewrite(story_script)
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
	pressed_next.connect(_on_click)
	get_tree().paused = true
	storyHolder.visible = true
	_show_line(current_line)

func start_tutorial_play():
	if pressed_next.is_connected(_on_click):
		pressed_next.disconnect(_on_click)
	storyHolder.visible = false
	get_tree().paused = false

func hide_live2D():
	storyHolder.get_node("Live2D").visible = false
	_show_line(current_line)

func show_live2D():
	storyHolder.get_node("Live2D").visible = true
	_show_line(current_line)

func change_live2D(index: int):
	match(index):
		0:
			live2d.texture = load("res://Textures/Sayane_Live2D.png")
		_:
			pass
	show_live2D()

signal pressed_next

func _input(event):
	if event is InputEventKey:
		match event.keycode:
			KEY_L, KEY_ENTER:
				if event.pressed and not event.is_echo():
					print("hello")
					pressed_next.emit()
