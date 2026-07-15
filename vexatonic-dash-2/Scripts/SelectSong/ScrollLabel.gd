extends Control

@export var scroll_speed: float = 100.0  # 초당 이동 픽셀
@export var gap: float = 40.0           # 원본과 복사본 사이 간격

var label: Label
var label2: Label
var text_width: float = 0.0
var scrolling: bool = false
var offset: float = 0.0

func _ready():
	clip_contents = true
	label = $Label1
	label2 = $Label2

func _setup(text: String):
	if not label:
		return
	label.text = text
	label2.text = text
	await get_tree().process_frame  # 폰트 반영 후 크기 측정하려고 한 프레임 대기
	text_width = label.get_minimum_size().x
	offset = 0.0
	if text_width > size.x:
		scrolling = true
		label2.visible = true
	else:
		scrolling = false
		label2.visible = false
		label.position.x = 0

func _process(delta):
	if not scrolling:
		return
	offset += scroll_speed * delta
	if offset >= text_width + gap:
		offset -= text_width + gap
	label.position.x = -offset
	label2.position.x = -offset + text_width + gap
