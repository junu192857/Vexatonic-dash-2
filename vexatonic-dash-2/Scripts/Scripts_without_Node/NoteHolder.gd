class_name NoteHolder

var notes: Array[Note]
var color
var current_index
var earliest_unprocessed_index
var current_note
var active_long_note: Note  # 현재 hold 중인 롱노트 (null이면 없음)

func _init(p_color: int):
	notes = []
	current_index = 0
	earliest_unprocessed_index = 0
	color = p_color

func sort_notes():
	notes.sort_custom(func(a:Note, b:Note):
		return a.get_data().time < b.get_data().time
	)
	if (not notes.is_empty()):
		current_note = notes[0]
		print("Set current note")

func check_miss(time: float):
	# 활성 롱노트 끝점 체크
	if active_long_note != null:
		var end_j = active_long_note.check_long_end(time)
		if end_j != Note.Judgement.PASS:
			#TODO: Judgement 전파하기
			active_long_note = null

	if (notes.size() - 1 < current_index): #모든 노트 처리 완료
		return

	check_current_note(time)

	while earliest_unprocessed_index < current_index:
		if notes[earliest_unprocessed_index].missed(time):
			#TODO: Judgement_Miss 처리
			earliest_unprocessed_index += 1
		elif notes[earliest_unprocessed_index].is_hit:
			earliest_unprocessed_index += 1
		else:
			break

	if (current_note.missed(time)):
		if current_note.get_data().type == 1:
			active_long_note = current_note
		#TODO: Judgement_Miss 처리
		move_to_next_note()


func check_current_note(time: float):
	if (notes.size() - 2 < current_index):
		return
	var next_note = notes[current_index + 1]
	if (next_note.get_data().time - time < time - current_note.get_data().time):
		# 롱노트를 2-2로 넘어갈 경우 시작점 Miss 처리 후 active_long_note에 등록
		if current_note.get_data().type == 1 and not current_note.is_hit:
			current_note.is_hit = true
			active_long_note = current_note
		move_to_next_note()

func process_input(time: float):
	# 활성 롱노트 re-hold 처리 (떼었다가 다시 눌러도 holding 재개)
	if active_long_note != null:
		active_long_note.process_long_press(color, time)

	if (notes.size() - 1 < current_index): # 모든 노트 처리 완료
		return

	if current_note.get_data().type == 1:
		var judgement = current_note.process_long_press(color, time)
		if judgement < Note.Judgement.PASS:  # 시작점 판정 성공 (0~3)
			active_long_note = current_note
			if earliest_unprocessed_index == current_index:
				earliest_unprocessed_index += 1
			#TODO: Judgement 전파하기
			move_to_next_note()
		# PASS: 윈도우 밖이지만 is_holding=true — current_note 유지, missed()가 처리
	else:
		var judgement = current_note.process_input(color, time)
		if (0 <= judgement and judgement < 4):
			if (earliest_unprocessed_index == current_index):
				earliest_unprocessed_index += 1
			#TODO: Judgement 전파하기
			move_to_next_note()

# 키 릴리즈 시 호출. 활성 롱노트 끝점 판정.
func process_release(time: float):
	if active_long_note == null:
		return
	var judgement = active_long_note.process_long_release(color, time)
	if judgement != Note.Judgement.PASS:
		#TODO: Judgement 전파하기
		active_long_note = null

func move_to_next_note():
	current_index += 1
	if (notes.size() -1 < current_index):
		return
	current_note = notes[current_index]
