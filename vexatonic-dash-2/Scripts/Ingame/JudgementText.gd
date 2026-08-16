extends Node

@onready var judgement_text = $JudgementText
@onready var combo_text = $ComboText
@onready var fastslow_text = $FastSlowText
@onready var labelSettings = $ComboText.label_settings

func show_text(judgement: int, combo: int, fastslow: Note.Fastslow, combo_cut: bool):
	match judgement:
		0:
			judgement_text.text = "VEXATONIC"
			judgement_text.modulate = Color(1.0, 0.0, 1.0, 1.0)
			_apply_display_setting(Setting.vexatonic_display)
		1:
			judgement_text.text = "SPARKLIC"
			judgement_text.modulate = Color(0.0, 1.0, 1.0, 1.0)
			_apply_display_setting(Setting.sparklic_display)
		2:
			judgement_text.text = "WILD"
			judgement_text.modulate = Color(0.766, 0.354, 0.0, 1.0)
			_apply_display_setting(Setting.wild_display)
		3:
			judgement_text.text = "MISS"
			judgement_text.visible = true
			fastslow_text.visible = true
	combo_text.visible = Setting.combo_display
	if (combo > 0):
		combo_text.text = str(combo)
	else:
		combo_text.text = ""
	if (!combo_cut):
		labelSettings.font_color = Color(0.984, 0.118, 0.0, 1.0)
	else:
		labelSettings.font_color = Color(1,1,1,1)
	match fastslow:
		Note.Fastslow.NOTHING:
			fastslow_text.text = ""
		Note.Fastslow.FAST:
			fastslow_text.text = "Fast"
			fastslow_text.modulate = Color(0,0,1,1)
		Note.Fastslow.SLOW:
			fastslow_text.text = "Slow"
			fastslow_text.modulate = Color(1,0,0,1)

func _apply_display_setting(display: Setting.JUDGEMENT_DISPLAY) -> void:
	match display:
		Setting.JUDGEMENT_DISPLAY.All:
			judgement_text.visible = true
			fastslow_text.visible = true
		Setting.JUDGEMENT_DISPLAY.JudgeOnly:
			judgement_text.visible = true
			fastslow_text.visible = false
		Setting.JUDGEMENT_DISPLAY.FastSlowOnly:
			judgement_text.visible = false
			fastslow_text.visible = true
		Setting.JUDGEMENT_DISPLAY.Off:
			judgement_text.visible = false
			fastslow_text.visible = false
