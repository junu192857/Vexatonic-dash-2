extends Node

@export var JUDGEMENT_TEXT: PackedScene
@export var score_text: Label
@export var canvasLayer: CanvasLayer
@export var lampTextHolder: Control
@export var resultPanelHolder: Control
@export var rightCover: TextureRect
@export var leftCover: TextureRect

@onready var resultPanel = resultPanelHolder.get_node("ResultPanel")
@onready var scoreText = resultPanelHolder.get_node("ResultPanel/VariableLabelHolder/ScoreText")
@onready var paintText = resultPanelHolder.get_node("ResultPanel/VariableLabelHolder/PaintText")
@onready var vexatonicText = resultPanelHolder.get_node("ResultPanel/VariableLabelHolder/VexatonicText")
@onready var sparklicText = resultPanelHolder.get_node("ResultPanel/VariableLabelHolder/SparklicText")
@onready var wildText = resultPanelHolder.get_node("ResultPanel/VariableLabelHolder/WildText")
@onready var missText = resultPanelHolder.get_node("ResultPanel/VariableLabelHolder/MissText")
@onready var rankText = resultPanelHolder.get_node("ResultPanel/VariableLabelHolder/RankText")
@onready var comboLampText = resultPanelHolder.get_node("ResultPanel/VariableLabelHolder/ComboLampText")
@onready var paintLampText = resultPanelHolder.get_node("ResultPanel/VariableLabelHolder/PaintLampText")


func _ready():
	if (Setting.gamemode == Setting.GAMEMODE.Suregi):
		pass
	
	match Setting.score_display:
		Setting.SCORE_DISPLAY.Increasing:
			score_text.text = "SCORE %07d" % 0
		Setting.SCORE_DISPLAY.Decreasing:
			score_text.text = "SCORE %07d" % 1000000
	refresh_UI()

func refresh_UI():
	resultPanelHolder.visible = false
	lampTextHolder.get_node("PerfectPaintText").modulate.a = 0
	for label in resultPanelHolder.get_node("ResultPanel/VariableLabelHolder").get_children():
		label.modulate.a = 0.0
	for i in range(3):
		lampTextHolder.get_child(i).modulate.a = 0.0
		lampTextHolder.get_child(i).visible = true
	await get_tree().process_frame
	for i in range(3):
		lampTextHolder.get_child(i).visible = false
		lampTextHolder.get_child(i).modulate.a = 1.0


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

func show_result_2(data: Dictionary) -> void:
	var tween = create_tween()
	var lamp = data["combo_lamp"]
	var target_text = lampTextHolder.get_child(lamp)
	target_text.visible = true
	
	if data["perfect_paint"]:
		tween.tween_interval(0.7)
		tween.tween_property(lampTextHolder.get_node("PerfectPaintText"), "modulate:a", 1.0, 1.0).from(0.0)
	
	tween.tween_interval(2.0)

  # 텍스트 값 설정 (modulate.a = 0 상태이므로 보이지 않음)
	scoreText.text = "%07d" % data["score"]
	rankText.text = RANK_NAMES[data["rank"]]
	var paint_pct: String
	if data["perfect_paint"]:
		paint_pct = "100.0%"
	else:
		paint_pct = "%.1f%%" % (floor(data["paint_ratio"] * 1000.0) / 10.0)
	paintText.text = "Paint  %s" % paint_pct
	vexatonicText.text = "%04d" % data["vexatonic"]
	sparklicText.text = "%04d" % data["sparklic"]
	wildText.text = "%04d" % data["wild"]
	missText.text = "%04d" % data["miss"]
	if lamp == 2:
		comboLampText.text = "FULL VEXATONIC"
	elif lamp == 1:
		comboLampText.text = "FULL COMBO"

	  # resultPanel을 화면 오른쪽 밖으로 초기 배치
	var vp_width = get_viewport().get_visible_rect().size.x
	var orig_panel_x = resultPanel.position.x
	resultPanel.position.x = orig_panel_x + vp_width

	tween.tween_callback(func():
		target_text.visible = false
		lampTextHolder.get_node("PerfectPaintText").visible = false
		resultPanelHolder.visible = true
	)

	  # 1. ResultPanel - 효과A: 오른쪽에서 날아옴
	tween.tween_property(resultPanel, "position:x", orig_panel_x, 1.0) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	  # 2. scoreText - 효과B: 크게 시작해서 줄어듦
	tween.tween_callback(func(): scoreText.pivot_offset = scoreText.size / 2)
	tween.tween_property(scoreText, "scale", Vector2.ONE, 1.0).from(Vector2(2.0, 2.0)) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(scoreText, "modulate:a", 1.0, 1.0).from(0.0)

	  # 3. rankLabel - 효과B
	tween.tween_callback(func(): rankText.pivot_offset = rankText.size / 2)
	tween.tween_property(rankText, "scale", Vector2.ONE, 1.0).from(Vector2(2.0, 2.0)) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(rankText, "modulate:a", 1.0, 1.0).from(0.0)

	  # 4. 세부 스탯 - 효과C: 아래에서 원래 위치로 올라옴 (순서대로)
	var drop_offset = 30.0
	for node in [paintText, vexatonicText, sparklicText, wildText, missText]:
		var captured: Control = node
		tween.tween_callback(func():
			var sub = create_tween()
			var orig_y = captured.position.y
			sub.tween_property(captured, "position:y", orig_y, 0.3).from(orig_y + drop_offset) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			sub.parallel().tween_property(captured, "modulate:a", 1.0, 0.3)
		)
		tween.tween_interval(0.25)

	  # 5. comboLampText - 효과B (full combo 또는 full vexatonic일 때만)
	if lamp >= 1:
		tween.tween_callback(func(): comboLampText.pivot_offset = comboLampText.size / 2)
		tween.tween_property(comboLampText, "scale", Vector2.ONE, 1.0).from(Vector2(2.0, 2.0)) \
		  .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.parallel().tween_property(comboLampText, "modulate:a", 1.0, 1.0).from(0.0)

	  # 6. paintLampText - 효과B (perfect paint일 때만)
	if data["perfect_paint"]:
		tween.tween_callback(func(): paintLampText.pivot_offset = paintLampText.size / 2)
		tween.tween_property(paintLampText, "scale", Vector2.ONE, 1.0).from(Vector2(2.0, 2.0)) \
		  .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.parallel().tween_property(paintLampText, "modulate:a", 1.0, 1.0).from(0.0)

	tween.tween_callback(func(): InputManager.pressed_enter.connect(_on_result_confirm, CONNECT_ONE_SHOT))
	
func _on_result_confirm():
	get_tree().change_scene_to_file("res://Scenes/SelectSong.tscn")

func get_note_position(note: Note):
	var note_pos = get_viewport().get_canvas_transform() * note.global_position
	if (Setting.gamemode == Setting.GAMEMODE.Suregi):
		note_pos.y = get_viewport().get_visible_rect().size.y * 0.65
	else:
		note_pos.x = get_viewport().get_visible_rect().size.x * 0.2
	return note_pos  # 마지막 canvas_transform 제거
