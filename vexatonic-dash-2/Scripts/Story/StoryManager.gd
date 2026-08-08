extends Control

@export var storyHolder: Control
@export var live2d: TextureRect
@export var storyScript: Label
@export var enterLabel: Label
@export var storySpeaker: Label
@export var skipLabel: Label
@export var leftButton: TextureRect
@export var rightButton: TextureRect

var script_path: String

var script_tween
var script_lines: Array[String] = []
var current_line: int = 0
var is_typing: bool = false

var phases: Array[Callable] = [
	start_explanation,
	quit_story,
	hide_live2D,
	show_live2D
]
const CHARS_PER_SECOND = 30.0

signal story_end

func start_story(path: String, skipable: bool):
	current_line = 0
	script_lines = []
	script_path = path
	visible = true
	skipLabel.visible = skipable
	if skipable and not PausedInputManager.pressed_esc.is_connected(quit_story):
		PausedInputManager.pressed_esc.connect(quit_story)
	elif not skipable and PausedInputManager.pressed_esc.is_connected(quit_story):
		PausedInputManager.pressed_esc.disconnect(quit_story)
	_load_script()
	start_explanation()

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
				5:
					change_name("버그" if parts.size() < 3 else parts[2])
				6:
					show_buttons(parts[2], parts[3])
				_:
					push_error("need more argument for special phase")
		return
	is_typing = true
	typewrite(storyScript, line, line.length() / CHARS_PER_SECOND)
	script_tween.tween_callback(func(): is_typing = false)

func _on_click():
	if is_typing:
		force_typewrite(storyScript)
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
	PausedInputManager.blocked = true
	PausedInputManager.pressed_l.connect(_on_click)
	PausedInputManager.pressed_enter.connect(_on_click)
	get_tree().paused = true
	storyHolder.visible = true
	_show_line(current_line)

func quit_story():
	if PausedInputManager.pressed_l.is_connected(_on_click):
		PausedInputManager.pressed_l.disconnect(_on_click)
	if PausedInputManager.pressed_enter.is_connected(_on_click):
		PausedInputManager.pressed_enter.disconnect(_on_click)
	storyHolder.visible = false
	InputManager.blocked = true
	get_tree().paused = false
	story_end.emit()

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

func change_name(speaker: String):
	storySpeaker.text = speaker
	_show_line(current_line)

func show_buttons(leftText: String, rightText: String):
	pass
