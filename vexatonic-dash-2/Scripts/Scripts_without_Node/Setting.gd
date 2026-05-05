class_name Setting

static var speed = 1

static var PX_PER_MS = 0.5
#단노트의 좌우 길이
static var NOTE_WIDTH = 24
#Connector의 높이의 절반
static var HALF_CONNECTOR_HEIGHT = 25

#레인 중앙 기준 캐릭터의 발 위치
static var CHARACTER_POS_Y = 26

static func get_speed() -> float:
	return speed

static func get_posx_from_time(time: float) -> float:
	return time * PX_PER_MS * speed
	
static func get_time_from_posx(posx_float: float) -> float:
	return posx_float / (PX_PER_MS * speed)
	
static var time_per_note_width = NOTE_WIDTH / (PX_PER_MS * speed)

static var EPSILON = 0.001
