class_name NoteData

# NoteData의 멤버에 직접 접근하는 것 지양

# 노트를 처리해야 하는 시간
var time: float
# RED = 0, BLUE = 1, YELLOW = 2
var color: int
# single = 0, long = 1
var type: int
# single이면 0으로 고정, long이면 롱노트 끝나는 시각(떼판은 없음)
var end_time: float
#해당 노트가 속한 레인 번호
var lane: int

func _init(p_time: float, p_color: int, p_type: int, p_end_time: float, p_lane: int):
	time = p_time
	color = p_color
	type = p_type
	end_time = p_end_time
	lane = p_lane
