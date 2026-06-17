extends Node

@onready var judgement_text = $JudgementText
@onready var combo_text = $ComboText

func show_text(judgement: int, combo: int):
	match judgement:
		0:
			judgement_text.text = "VEXATONIC"
			judgement_text.modulate = Color(1.0, 0.0, 1.0, 1.0)
		1:
			judgement_text.text = "SPARKLIC"
			judgement_text.modulate = Color(0.0, 1.0, 1.0, 1.0)
		2:
			judgement_text.text = "WILD"
			judgement_text.modulate = Color(0.766, 0.354, 0.0, 1.0)
		3:
			judgement_text.text = "MISS"
	if (combo > 0):
		combo_text.text = str(combo)
