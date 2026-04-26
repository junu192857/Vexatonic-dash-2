class_name Lane

var lane_index: int
var keyframes: Array[Vector2]
var notes: Array[Node2D]
var note_index: int
var is_init: bool

func _init(p_index: int, p_is_init: bool):
	lane_index = p_index
	is_init = p_is_init
	note_index = 0

func add_keyframe(time: float, height: float):
	keyframes.append(Vector2(time,height))

func print_data():
	print("INDEX: %d" % lane_index)
	for kf:Vector2 in keyframes:
		print("time: %f and height: %f" % [kf[0],kf[1]])
	print("Note Count:%d" % notes.size())
		
func get_height(time_ms: float) -> float:
	print("My time: %f" % time_ms)
	if time_ms < keyframes[0].x:
		push_error("ERROR: 레인 %d 시작 전에 노트가 있습니다. (time: %sms)" % [lane_index, time_ms])
		return 0.0

	if time_ms > keyframes[-1].x:
		push_error("ERROR: 레인 %d 종료 후에 노트가 있습니다. (time: %sms)" % [lane_index, time_ms])
		return 0.0

	for i in range(keyframes.size() - 1):
		var kf_curr = keyframes[i]
		var kf_next = keyframes[i + 1]

		if time_ms >= kf_curr.x and time_ms <= kf_next.x:
			var t = (time_ms - kf_curr.x) / (kf_next.x - kf_curr.x)
			return lerpf(kf_curr.y, kf_next.y, t)

	return 0.0
	
func add_Note(note: Note):
	notes.append(note)

func sort_notes():
	notes.sort_custom(func(a:Note, b:Note): return a.data.time < b.data.time)
	

static func find_lane(lanes: Array[Lane], index: int) -> Lane:
	for lane:Lane in lanes:
		if (lane.lane_index == index):
			return lane
	return null
