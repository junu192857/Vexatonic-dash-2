extends Node2D

const EXPLANATION_TRIGGERS = [182.0, 4545.0, 13273.0, 22000.0, 28000.0, 30727.0]
var trigger_index: int = 0
@export var storyManager: Node

const SCRIPT_PATH = "res://Scripts/Tutorial/script.txt"
const CHARS_PER_SECOND = 30.0

func _ready() -> void:
	if (!Setting.is_tutorial):
		return
	await get_tree().process_frame
	$TutorialBGMPlayer.play()
	storyManager.visible = true
	storyManager._load_script()
	storyManager.start_explanation()
	print("starting tutorial..")

func _process(_delta: float) -> void:
	if (!Setting.is_tutorial):
		return
	if get_tree().paused or trigger_index >= EXPLANATION_TRIGGERS.size():
		return
	if get_parent().time >= EXPLANATION_TRIGGERS[trigger_index]:
		trigger_index += 1
		storyManager.start_explanation()
