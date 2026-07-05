extends Node

@onready var judgement_text = $JudgementText
@onready var combo_text = $ComboText
@onready var fastslow_text = $FastSlowText

func show_text(judgement: int, combo: int, fastslow = Note.Fastslow):
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
	else:
		combo_text.text = ""
	match fastslow:
		Note.Fastslow.NOTHING:
			fastslow_text.text = ""
		Note.Fastslow.FAST:
			fastslow_text.text = "Fast"
			fastslow_text.modulate = Color(0,0,1,1)
		Note.Fastslow.SLOW:
			fastslow_text.text = "Slow"
			fastslow_text.modulate = Color(1,0,0,1)
