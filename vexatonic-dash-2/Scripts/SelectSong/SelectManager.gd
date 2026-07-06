extends Node2D

@export var leftSongHolder: SongHolder
@export var middleSongHolder: SongHolder
@export var rightSongHolder: SongHolder
@export var songDataHolder: SongDataHolder
@export var settingHolder: SettingHolder
@onready var difficultyRect = $CanvasLayer/Control/DifficultyRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_game_start():
	get_tree().change_scene_to_file("res://Scenes/RhythmScene.tscn")
