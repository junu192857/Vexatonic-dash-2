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
	delete_middle_keyframe(time - Setting.EPSILON, time + Setting.EPSILON)
	keyframes.append(Vector2(time,height))

func insert_keyframe(time: float, height: float):
	delete_middle_keyframe(time - Setting.EPSILON, time + Setting.EPSILON)
	var new_kf = Vector2(time, height)
	for i in range(keyframes.size()):
		if keyframes[i].x > time:
			keyframes.insert(i, new_kf)
			return
	keyframes.append(new_kf)

func delete_middle_keyframe(time1: float, time2: float):
	var deleted = keyframes.filter(func(kf: Vector2): return kf.x > time1 and kf.x < time2)
	keyframes = keyframes.filter(func(kf: Vector2): return kf.x <= time1 or kf.x >= time2)
	
	if deleted.is_empty():
		return null
	
	deleted.sort_custom(func(a: Vector2, b: Vector2): return a.x < b.x)
	return deleted[-1]
	
func print_data():
	print("INDEX: %d" % lane_index)
	for kf:Vector2 in keyframes:
		print("time: %f and height: %f" % [kf[0],kf[1]])
	print("Note Count:%d" % notes.size())
	for note:Note in notes:
		print("Note: time %f, color %d, type %d" % [note.get_time(), note.get_color(), note.get_type()])

func check_note_error() -> bool:
	var lane_start = keyframes[0].x
	var lane_end = keyframes[-1].x
	for note:Note in notes:
		if (note.get_time() < lane_start or note.get_time() > lane_end):
			push_error("ERROR: 레인 시작 전 또는 종료 후에 노트가 있습니다.")
			return true
		if (note.get_type() == 1 and note.get_end_time() > lane_end):
			push_error("ERROR: 롱노트의 끝점이 레인 끝 이후입니다")
			return true
	return false
	
func get_height(time_ms: float) -> float:
	#print("My time: %f" % time_ms)
	if time_ms < keyframes[0].x:
		if (!is_init):
			push_error("ERROR: 레인 %d 시작 전에는 높이를 찾을 수 없습니다. (time: %sms)" % [lane_index, time_ms])
			return 0.0
		else:
			return keyframes[0].y

	if time_ms > keyframes[-1].x:
		push_error("ERROR: 레인 %d 종료 후에는 높이를 찾을 수 없습니다. (time: %sms)" % [lane_index, time_ms])
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
	
func get_start_time():
	return keyframes[0].x

func get_end_time():
	return keyframes[-1].x

static func find_lane(lanes: Array[Lane], index: int) -> Lane:
	for lane:Lane in lanes:
		if (lane.lane_index == index):
			return lane
	return null

static func sort_lanes(lanes: Array[Lane]):
	lanes.sort_custom(func(a:Lane, b:Lane): return a.keyframes[0].x < b.keyframes[0].x) 
