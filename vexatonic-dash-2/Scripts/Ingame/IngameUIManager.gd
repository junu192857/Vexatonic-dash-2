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

func _on_status_update(status: GameStatus) -> void:
	var rounded = roundi(status.score)
	score_text.text = "SCORE %07d" % rounded
	var judgement_text = JUDGEMENT_TEXT.instantiate()
	canvasLayer.add_child(judgement_text)
	judgement_text.global_position = get_note_position(status.note)
	judgement_text.show_text(status.judgement, status.combo, status.fastslow, status.combo_cut)
	
	var tween = judgement_text.create_tween()
	tween.tween_property(judgement_text, "position:y", judgement_text.position.y - 100, 0.6)
	tween.parallel().tween_property(judgement_text, "modulate:a", 0.0, 0.6)
	tween.tween_callback(judgement_text.queue_free)

const RANK_NAMES = ["", "D", "C", "B", "A", "AA", "AAA", "S", "SS", "SSS", "V"]

func show_result(data: Dictionary) -> void:
	var vp = get_viewport().get_visible_rect().size

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvasLayer.add_child(overlay)

	var lamp = data["combo_lamp"]
	var header_text: String
	if lamp == 2:
		header_text = "Full Vexatonic!!"
	elif lamp == 1:
		header_text = "Full Combo!"
	else:
		header_text = "Game Finished"

	var header = Label.new()
	header.text = header_text
	header.add_theme_font_size_override("font_size", 100)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.set_anchors_preset(Control.PRESET_FULL_RECT)
	header.position = Vector2(0, vp.y * 0.05)
	canvasLayer.add_child(header)

	if data["full_paint"]:
		var paint_label = Label.new()
		paint_label.text = "Perfect Paint"
		paint_label.add_theme_font_size_override("font_size", 60)
		paint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		paint_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		paint_label.position = Vector2(0, vp.y * 0.2)
		canvasLayer.add_child(paint_label)

	var panel = PanelContainer.new()
	panel.position = Vector2(vp.x * 0.3, vp.y * 0.3)
	panel.size = Vector2(vp.x * 0.4, vp.y * 0.55)
	canvasLayer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var paint_pct = "%.1f%%" % (data["paint_ratio"] * 100.0)
	var lines = [
		"SCORE  %07d" % data["score"],
		"RANK   %s" % RANK_NAMES[data["rank"]],
		"",
		"Vexatonic  %d" % data["vexatonic"],
		"Sparklic   %d" % data["sparklic"],
		"Wild       %d" % data["wild"],
		"Miss       %d" % data["miss"],
		"",
		"Paint  %s" % paint_pct,
	]
	for line in lines:
		var lbl = Label.new()
		lbl.text = line
		lbl.add_theme_font_size_override("font_size", 36)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl)

	var hint = Label.new()
	hint.text = "Press Enter to continue"
	hint.add_theme_font_size_override("font_size", 28)
	hint.modulate = Color(0.8, 0.8, 0.8)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_preset(Control.PRESET_FULL_RECT)
	hint.position = Vector2(0, vp.y * 0.88)
	canvasLayer.add_child(hint)

	InputManager.pressed_enter.connect(_on_result_confirm, CONNECT_ONE_SHOT)

func _on_result_confirm():
	get_tree().change_scene_to_file("res://Scenes/SelectSong.tscn")

func get_note_position(note: Note):
	var note_pos = get_viewport().get_canvas_transform() * note.global_position
	if (Setting.gamemode == Setting.GAMEMODE.Suregi):
		note_pos.y = get_viewport().get_visible_rect().size.y * 0.65
	else:
		note_pos.x = get_viewport().get_visible_rect().size.x * 0.2
	return note_pos  # 마지막 canvas_transform 제거
