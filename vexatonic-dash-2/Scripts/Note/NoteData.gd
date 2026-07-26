class_name NoteData

# 노트를 처리해야 하는 시간
var time: float
# RED = 0, BLUE = 1, YELLOW = 2, GREEN(jump) = 3
var color: int
# single = 0, long = 1, jump = 2
var type: int
# single이면 time과 동일, long이면 롱노트 끝 시각, jump이면 착지 시각
var end_time: float
#해당 노트가 속한 레인 번호
var lane: int
# 1이면 보정 노트 (Sparklic/Wild → Vexatonic으로 보정), 0이면 일반 노트
var adjusted: int

func _init(p_time: float, p_color: int, p_type: int, p_end_time: float, p_lane: int, p_adjusted: int = 0):
	time = p_time
	color = p_color
	type = p_type
	end_time = p_end_time
	lane = p_lane
	adjusted = p_adjusted
