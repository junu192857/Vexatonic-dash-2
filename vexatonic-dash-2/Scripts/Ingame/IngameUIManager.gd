extends Node

@export var JUDGEMENT_TEXT: PackedScene
@export var score_text: Label
@export var canvasLayer: CanvasLayer


func _ready():
	match Setting.score_display:
		Setting.SCORE_DISPLAY.Increasing:
			score_text.text = "SCORE %07d" % 0
		Setting.SCORE_DISPLAY.Decreasing:
			score_text.text = "SCORE %07d" % 1000000

func _on_status_update(judgement: int, score: float, combo: int, note: Note, fastslow: Note.Fastslow) -> void:
	var rounded = roundi(score)
	score_text.text = "SCORE %07d" % rounded
	var judgement_text = JUDGEMENT_TEXT.instantiate()
	canvasLayer.add_child(judgement_text)
	judgement_text.global_position = get_note_position(note)
	judgement_text.show_text(judgement, combo, fastslow)
	
	var tween = judgement_text.create_tween()
	tween.tween_property(judgement_text, "position:y", judgement_text.position.y - 100, 0.6)
	tween.parallel().tween_property(judgement_text, "modulate:a", 0.0, 0.6)
	tween.tween_callback(judgement_text.queue_free)

func get_note_position(note: Note):
	return get_viewport().get_canvas_transform() * note.global_position
	
