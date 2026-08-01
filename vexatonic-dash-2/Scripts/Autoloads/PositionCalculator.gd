extends Node

# Speed 트리거 목록: [{time: float, speed: float}, ...] time 오름차순 정렬
# 인게임 시작 전 RhythmManager에서 세팅, 게임 종료 후 초기화
var speed_segments: Array = []

# speed_segments[i].time 시점의 누적 x 좌표 (미리 계산)
var _seg_cumulative_pos: Array = []

# 단조증가 탐색용 인덱스 (physics loop 전용)
var _cur_seg_index: int = 0

# speed_segments와 누적 캐시를 세팅. 인게임 시작 전에 호출.
func setup(segments: Array) -> void:
	speed_segments = segments
	_seg_cumulative_pos = []
	var pos = 0.0
	var prev_time = 0.0
	var cur_speed = Setting.speed
	for seg in speed_segments:
		pos += (seg.time - prev_time) * Setting.PX_PER_MS * cur_speed
		_seg_cumulative_pos.append(pos)
		prev_time = seg.time
		cur_speed = seg.speed
	_cur_seg_index = 0

func reset() -> void:
	speed_segments = []
	_seg_cumulative_pos = []
	_cur_seg_index = 0

# 단조증가 탐색 인덱스 초기화 (physics loop 재시작 시 호출)
func reset_monotonic_index() -> void:
	_cur_seg_index = 0

# O(n) 버전: time이 임의 순서여도 동작. 렌더링·에디터 전용.
func get_posx_from_time(time: float) -> float:
	if speed_segments.is_empty():
		return time * Setting.PX_PER_MS * Setting.speed
	var pos = 0.0
	var prev_time = 0.0
	var cur_speed = Setting.speed
	for i in range(speed_segments.size()):
		if time <= speed_segments[i].time:
			break
		pos = _seg_cumulative_pos[i]
		prev_time = speed_segments[i].time
		cur_speed = speed_segments[i].speed
	return pos + (time - prev_time) * Setting.PX_PER_MS * cur_speed

# O(n) 버전: posx → time 역산. 렌더링·에디터 전용.
func get_time_from_posx(posx: float) -> float:
	if speed_segments.is_empty():
		return posx / (Setting.PX_PER_MS * Setting.speed)
	var remaining = posx
	var prev_time = 0.0
	var cur_speed = Setting.speed
	for i in range(speed_segments.size()):
		var seg_px = _seg_cumulative_pos[i] - (_seg_cumulative_pos[i - 1] if i > 0 else 0.0)
		if remaining <= seg_px + Setting.EPSILON:
			return prev_time + remaining / (Setting.PX_PER_MS * cur_speed)
		remaining -= seg_px
		prev_time = speed_segments[i].time
		cur_speed = speed_segments[i].speed
	return prev_time + remaining / (Setting.PX_PER_MS * cur_speed)

# O(1) 상각 버전: time이 단조증가할 때만 정확. 인게임 캐릭터 위치 전용.
func get_posx_from_time_fast(time: float) -> float:
	while _cur_seg_index < speed_segments.size() and time >= speed_segments[_cur_seg_index].time:
		_cur_seg_index += 1
	if _cur_seg_index == 0:
		return time * Setting.PX_PER_MS * Setting.speed
	var seg = speed_segments[_cur_seg_index - 1]
	return _seg_cumulative_pos[_cur_seg_index - 1] + (time - seg.time) * Setting.PX_PER_MS * seg.speed
