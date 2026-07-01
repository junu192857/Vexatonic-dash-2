class_name NoteHolder

var notes: Array[Note]
var color: int
var current_index: int
var earliest_unprocessed_index: int
var current_note: Note

func _init(p_color: int):
	notes = []
	current_index = 0
	earliest_unprocessed_index = 0
	color = p_color

func sort_notes():
	notes.sort_custom(func(a: Note, b: Note):
		return a.get_data().time < b.get_data().time
	)
	if not notes.is_empty():
		current_note = notes[0]
		print("Set current note")

# 매 프레임 호출: 처리 안 된 롱노트 끝점 체크 + current_note Miss 체크
func check_miss(time: float):
	# [eu, ci) 범위의 롱노트 끝점 체크 (current_note 이전)
	for i in range(earliest_unprocessed_index, current_index):
		if i >= notes.size():
			break
		var note = notes[i]
		if note.get_data().type == 0 and not note.is_hit and time >= note.get_data().time + Note.WILD_MS:
			_force_start_miss(note)
		elif note.get_data().type == 1 and not note.end_judged and time >= note.get_data().end_time:
			print("Trying judge long end: note %d at time %f" % [i, time])
			_judge_long_end(note)
	_advance_earliest_unprocessed(time)

	if notes.size() - 1 < current_index:
		return

	# current_note가 롱노트이고 end_time 경과
	if current_note.get_data().type == 1 and not current_note.end_judged and time >= current_note.get_data().end_time:
		print("Trying judge long end: current note %d" % current_index)
		_judge_long_end(current_note)
		move_to_next_note()
		_advance_earliest_unprocessed()
		return


	# 시작점 윈도우 경과 → Miss
	while (current_index < notes.size() and not current_note.is_hit and time > current_note.get_data().time + Note.WILD_MS):
		_force_start_miss(current_note)
		move_to_next_note()
		_advance_earliest_unprocessed()

# 완전히 처리된 노트를 earliest_unprocessed_index에서 건너뜀
# 단노트: is_hit 시 완료 / 롱노트: end_judged 시 완료
func _advance_earliest_unprocessed(time: float = 0):
	while earliest_unprocessed_index < notes.size():
		var note = notes[earliest_unprocessed_index]
		var done = (note.get_data().type == 1 and note.end_judged) or \
				   (note.get_data().type != 1 and note.is_hit)
		if done:
			print("Note index %d: done. time: %f" % [earliest_unprocessed_index, time])
			earliest_unprocessed_index += 1
		else:
			break

func _force_start_miss(note: Note):
	if note.is_hit:
		return
	note.is_hit = true
	note.spread_judgement(Note.Judgement.MISS, note, false)

# end_time 도달 시 끝점 판정. 시작점 미처리이면 강제 MISS 후 끝점 판정.
func _judge_long_end(note: Note):
	if note.end_judged:
		return
	note.end_judged = true
	if not note.is_hit:
		note.is_hit = true
		note.spread_judgement(Note.Judgement.MISS, note, false)
	if note.is_holding_anyway():
		note.finalize_hold_time(note.get_data().end_time)
		note.get_marker().process_color()
		note.spread_judgement(Note.Judgement.VEXATONIC, note.get_marker(), true)
		note.update_last_hold_visual()
	else:
		note.spread_judgement(Note.Judgement.MISS, note.get_marker(), true)

# 키 누름: [eu, ci) 범위 롱노트 재홀드 + current_note 시작점 판정
func process_input(time: float, is_left: bool):
	for i in range(earliest_unprocessed_index, current_index):
		if i >= notes.size():
			break
		var note = notes[i]
		if note.get_data().type == 1 and not note.end_judged and time <= note.get_data().end_time:
			note.start_hold(is_left, time, false)

	if notes.size() - 1 < current_index:
		return
	
	var judgement = current_note.process_input(color, time)
	
	if judgement != Note.Judgement.PASS:
		if current_note.get_data().type == 1:
			current_note.start_hold(is_left, time, true)
			match (current_note as LongNote).previously_clicked:
				1:
					current_note.is_holding_left = true
				2:
					current_note.is_holding_right = true
		if move_to_next_note():
			if current_note.get_data().type == 1 and current_note.get_data().time - Note.WILD_MS < time and \
			time < current_note.get_data().time + Note.WILD_MS:
				(current_note as LongNote).previously_clicked = 1 if is_left else 2
		_advance_earliest_unprocessed()
	elif current_note.get_data().type == 1:
		# 시작점 윈도우 밖이지만 노트 지속 구간 내: 홀드 추적 시작
		if time >= current_note.get_data().time and time <= current_note.get_data().end_time:
			current_note.start_hold(is_left, time, false)

# 키 뗌: [eu, ci] 범위 롱노트 is_holding 해제 + 끝점 윈도우 내 릴리즈 시 최고 판정
func process_release(time: float, is_left: bool):
	var upper = min(current_index, notes.size() - 1)
	for i in range(earliest_unprocessed_index, upper + 1):
		var note = notes[i]
		if note.get_data().type != 1 or note.end_judged:
			continue
		if note.get_is_holding(is_left):
			if time >= note.get_data().end_time - Note.WILD_MS and time <= note.get_data().end_time + Note.WILD_MS:
				note.end_judged = true
				note.release_hold(is_left, time)
				note.finalize_hold_time(note.get_data().end_time)
				note.get_marker().process_color()
				note.spread_judgement(Note.Judgement.VEXATONIC, note.get_marker(), true)
				note.update_last_hold_visual()
			else:
				note.release_hold(is_left, time)
	_advance_earliest_unprocessed()

func move_to_next_note() -> bool:
	current_index += 1
	if notes.size() - 1 < current_index:
		return false
	current_note = notes[current_index]
	return true
	
func update_visuals(time: float) -> void:
	#print("Update_visuals at time %f" % time)
	var upper = min(current_index, notes.size() - 1)
	for i in range(earliest_unprocessed_index, upper + 1):
		var note = notes[i]
		if note.get_data().type == 1:
			(note as LongNote).update_hold_visual(time)
