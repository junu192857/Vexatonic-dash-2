class_name Setting

static var speed = 5

static var PX_PER_MS = 0.5
#단노트의 좌우 길이
static var NOTE_WIDTH = 24
#레인 중앙 기준 캐릭터의 발 위치
static var CHARACTER_POS_Y = 26

static func get_speed() -> float:
	return speed

static func get_posx_from_time(time: float) -> float:
	return time * PX_PER_MS * speed
	
static var time_per_note_width = NOTE_WIDTH / (PX_PER_MS * speed)

static var EPSILON = 0.001
