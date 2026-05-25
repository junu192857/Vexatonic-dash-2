class_name Lane

var lane_index: int
var keyframes: Array[Keyframe]
var notes: Array[Note]

var note_index: int
var is_init: bool

var editor_connectors: Array[EConnector]

func _init(p_index: int, p_is_init: bool):
	lane_index = p_index
	is_init = p_is_init
	note_index = 0

func adjust_keyframe(note_time: float, note_height: float):
	var first_time = note_time - Setting.time_per_note_width / 2
	var second_time = note_time + Setting.time_per_note_width / 2
	insert_keyframe(first_time, note_height)
	insert_keyframe(second_time, note_height)
	var deleted = delete_middle_keyframe(first_time, second_time)
	if (deleted != null):
		if (deleted.kf.y != note_height):
			var deleted2 = delete_middle_keyframe(second_time, second_time + Setting.EPSILON)
			if (deleted2 != null):
				insert_keyframe(second_time + Setting.EPSILON, deleted2.kf.y)
			else: insert_keyframe(second_time + Setting.EPSILON, deleted.kf.y)

func add_keyframe(keyframe: Keyframe):
	delete_middle_keyframe(keyframe.kf.x - Setting.EPSILON, keyframe.kf.x + Setting.EPSILON)
	keyframes.append(keyframe)

func insert_keyframe(time: float, height: float):
	delete_middle_keyframe(time - Setting.EPSILON, time + Setting.EPSILON)
	var new_kf = Keyframe.new(time, height)
	new_kf.set_lane(lane_index)
	for i in range(keyframes.size()):
		if keyframes[i].kf.x > time:
			keyframes.insert(i, new_kf)
			return
	keyframes.append(new_kf)

func delete_middle_keyframe(time1: float, time2: float):
	var deleted = keyframes.filter(func(kf: Keyframe): return kf.kf.x > time1 and kf.kf.x < time2)
	keyframes = keyframes.filter(func(kf: Keyframe): return kf.kf.x <= time1 or kf.kf.x >= time2)

	if deleted.is_empty():
		return null

	deleted.sort_custom(func(a: Keyframe, b: Keyframe): return a.kf.x < b.kf.x)
	return deleted[-1]

func print_data():
	print("INDEX: %d" % lane_index)
	for kf: Keyframe in keyframes:
		print("time: %f and height: %f" % [kf.kf.x, kf.kf.y])
	print("Note Count:%d" % notes.size())
	for note: Note in notes:
		print("Note: time %f, color %d, type %d" % [note.get_time(), note.get_color(), note.get_type()])

func check_note_error() -> bool:
	var lane_start = keyframes[0].kf.x
	var lane_end = keyframes[-1].kf.x

	for note: Note in notes:
		if (note.get_time() < lane_start or note.get_time() > lane_end):
			push_error("ERROR: 레인 시작 전 또는 종료 후에 노트가 있습니다.")
			return true
		if (note.get_type() == 1 and note.get_end_time() > lane_end):
			push_error("ERROR: 롱노트의 끝점이 레인 끝 이후입니다")
			return true
	return false

func get_height(time_ms: float) -> float:
	if time_ms < keyframes[0].kf.x:
		if (!is_init):
			push_error("ERROR: 레인 %d 시작 전에는 높이를 찾을 수 없습니다. (time: %sms)" % [lane_index, time_ms])
			return 0.0
		else:
			return keyframes[0].kf.y

	if time_ms > keyframes[-1].kf.x:
		push_error("ERROR: 레인 %d 종료 후에는 높이를 찾을 수 없습니다. (time: %sms)" % [lane_index, time_ms])
		return 0.0

	for i in range(keyframes.size() - 1):
		var kf_curr = keyframes[i]
		var kf_next = keyframes[i + 1]

		if time_ms >= kf_curr.kf.x and time_ms <= kf_next.kf.x:
			var t = (time_ms - kf_curr.kf.x) / (kf_next.kf.x - kf_curr.kf.x)
			return lerpf(kf_curr.kf.y, kf_next.kf.y, t)

	return 0.0

func add_note(note: Note):
	notes.append(note)

func sort_notes():
	notes.sort_custom(func(a: Note, b: Note): return a.data.time < b.data.time)

func get_start_time():
	return keyframes[0].kf.x

func get_end_time():
	return keyframes[-1].kf.x

func add_editor_connector(connector: EConnector):
	editor_connectors.append(connector)

func find_editor_connector(keyframe: Keyframe):
	for connector in editor_connectors:
		pass

static func find_lane(lanes: Array[Lane], index: int) -> Lane:
	for lane: Lane in lanes:
		if (lane.lane_index == index):
			return lane
	return null

static func sort_lanes(lanes: Array[Lane]):
	lanes.sort_custom(func(a: Lane, b: Lane): return a.keyframes[0].kf.x < b.keyframes[0].kf.x)

static func find_free_index(lanes: Array[Lane]) -> int:
	if lanes.is_empty():
		return 0

	var used_indices = lanes.map(func(lane: Lane): return lane.lane_index)
	var i = 0
	while i in used_indices:
		i += 1
	return i
