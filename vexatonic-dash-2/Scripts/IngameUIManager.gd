extends Node


func _on_status_update(score: float, combo: int) -> void:
	print("Score: %f, combo: %d" % [score, combo])
