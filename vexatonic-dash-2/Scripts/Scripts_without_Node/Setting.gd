class_name Setting

static var speed = 1

static var PX_PER_MS = 0.5
static var NOTE_WIDTH = 24

static func get_speed() -> float:
	return speed

static func get_posx_from_time(time: float) -> float:
	return time * PX_PER_MS * speed
	
static var time_per_note_width = NOTE_WIDTH / (PX_PER_MS * speed)
