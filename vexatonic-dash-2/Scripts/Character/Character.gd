extends Node2D
class_name Character

var lane: Lane

enum JumpState { None, Falling, Jumping }
var jump_state: JumpState = JumpState.None
var jumping_note: Note = null
var jump_aborted_note: Note = null
var pending_jump_notes: Array[Note]

var jump_start_y: float
var jump_start_time: float
var jump_end_y: float
var fall_start_y: float
var jump_initialized: bool = false
var jump_peak: float

const GRAVITY: float = 1500.0   # px/s^2 (아래 방향)
const PEAK_PER_MS: float = 0.30   # ms당 peak 증가량 (px/ms)

func set_lane(p_lane: Lane):
	lane = p_lane
	pending_jump_notes = lane.pending_jump_notes

func start_jump(note: Note):
	if note == jump_aborted_note:
		return  # Case 3: 이미 중단된 노트 — 무시
	jump_start_y = global_position.y
	jump_end_y = lane.get_height(note.get_data().end_time) + Setting.CHARACTER_POS_Y
	var duration = note.get_data().end_time - note.get_data().time
	jump_peak = duration * PEAK_PER_MS
	jumping_note = note
	jump_initialized = false
	jump_state = JumpState.Jumping
	pending_jump_notes.erase(note)

func set_character_position(time: float) -> bool:
	if 0 < time and time < lane.get_start_time():
		queue_free()
		return true
	if time > lane.get_end_time():
		queue_free()
		return true

	global_position.x = Setting.get_posx_from_time(time)

	match jump_state:
		JumpState.None:
			if not pending_jump_notes.is_empty():
				var next: Note = pending_jump_notes[0]
				if time >= next.get_data().end_time:
					# Case 3: 처리 전에 end_time 도달 → 낙하 없이 바로 착지 무효화
					jump_aborted_note = next
					pending_jump_notes.pop_front()
				elif time >= next.get_data().time and not next.is_hit:
					# note.time 통과, 미처리 → Falling 시작
					fall_start_y = lane.get_height(next.get_data().time) + Setting.CHARACTER_POS_Y
					jumping_note = next
					pending_jump_notes.pop_front()
					jump_state = JumpState.Falling
			global_position.y = lane.get_height(time) + Setting.CHARACTER_POS_Y

		JumpState.Falling:
			if time >= jumping_note.get_data().end_time:
				# Case 3: Falling 중에 end_time 도달 → 착지 후 레인 복귀
				jump_aborted_note = jumping_note
				jumping_note = null
				jump_state = JumpState.None
				global_position.y = lane.get_height(time) + Setting.CHARACTER_POS_Y
			else:
				var fall_t = (time - jumping_note.get_data().time) / 1000.0  # ms → s
				global_position.y = fall_start_y + 0.5 * GRAVITY * fall_t * fall_t

		JumpState.Jumping:
			if not jump_initialized:
				jump_start_time = time
				jump_initialized = true
			var total_dur = jumping_note.get_data().end_time - jump_start_time
			var elapsed = time - jump_start_time
			if total_dur <= 0.0 or elapsed >= total_dur:
				# 착지
				jumping_note = null
				jump_state = JumpState.None
				global_position.y = jump_end_y
			else:
				var ratio = elapsed / total_dur
				global_position.y = lerp(jump_start_y, jump_end_y, ratio) \
					- jump_peak * sin(PI * ratio)

	return false
