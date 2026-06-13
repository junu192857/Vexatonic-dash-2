extends Node2D

@onready var camera = $Camera2D

var triggers: Array[Trigger]

# 트리거별 누적 적용값 추적 (보간 계산용)
# { trigger_index -> progress(0.0~1.0) }
var _trigger_progress: Array[float]

# 트리거 시작 시점의 초기값 스냅샷
# { trigger_index -> initial_value }
var _trigger_initial: Array[float]

var triggered_delta_position : Vector2
var triggered_delta_rotation: Vector2

var _initialized: bool = false

func _ready() -> void:
	set_camera_position()

func set_triggers(p_triggers: Array[Trigger]) -> void:
	triggers = p_triggers
	_trigger_progress.resize(triggers.size())
	_trigger_progress.fill(0.0)
	_trigger_initial.resize(triggers.size())
	_trigger_initial.fill(0.0)
	_initialized = false

func set_camera_position():
	if (Setting.gamemode == Setting.GAMEMODE.Suregi):
		camera.rotation = deg_to_rad(90)
		var vp_height = get_viewport().get_visible_rect().size.y / camera.zoom.y
		camera.position = Vector2(vp_height * 0.2, 0.0)
	else:
		var vp = get_viewport().get_visible_rect().size.x / camera.zoom.x
		camera.position = Vector2(vp * 0.3, 0.0)

# RhythmManager가 매 프레임 호출
func move(time: float) -> void:

	_apply_triggers(time)
	position = Vector2(Setting.get_posx_from_time(time), 0.0) + triggered_delta_position

func _apply_triggers(time: float) -> void:
	if triggers.is_empty():
		return

	# 첫 프레임: 현재 camera 상태를 초기값으로 스냅샷
	if not _initialized:
		for i in range(triggers.size()):
			_snapshot_initial(i)
		_initialized = true

	for i in range(triggers.size()):
		var tr: Trigger = triggers[i]

		if time < tr.start:
			continue

		var prev_progress = _trigger_progress[i]

		var new_progress: float
		if tr.t <= 0.0:
			new_progress = 1.0
		else:
			new_progress = clampf((time - tr.start) / tr.t, 0.0, 1.0)

		if new_progress == prev_progress:
			continue

		var delta_ratio = new_progress - prev_progress
		_trigger_progress[i] = new_progress

		match tr.type:
			Trigger.TYPE.Move:
				if (new_progress == 1.0):
					triggered_delta_position.y += (tr.c - tr.progress)
				else:
					triggered_delta_position.y += tr.c * delta_ratio
					tr.progress += tr.c * delta_ratio


			Trigger.TYPE.Rotate:
				var pivot = _get_rotation_pivot()
				var delta_rad = deg_to_rad(tr.c * delta_ratio)
				# 판정선 기준점을 중심으로 Camera2D 회전
				var offset = camera.position - pivot
				var rotated_offset = offset.rotated(delta_rad)
				camera.position = pivot + rotated_offset
				camera.rotation += delta_rad

			Trigger.TYPE.Zoom:
				var zoom_delta = tr.c * delta_ratio
				camera.zoom += Vector2(zoom_delta, zoom_delta)
				# 줌 변경 시 판정선 위치 보정
				set_camera_position()

func _snapshot_initial(i: int) -> void:
	var tr: Trigger = triggers[i]
	match tr.type:
		Trigger.TYPE.Move:
			_trigger_initial[i] = position.y
		Trigger.TYPE.Rotate:
			_trigger_initial[i] = camera.rotation
		Trigger.TYPE.Zoom:
			_trigger_initial[i] = camera.zoom.x

# 판정선 중앙 위치 반환 (Camera2D 로컬 좌표)
func _get_rotation_pivot() -> Vector2:
	var vp = get_viewport().get_visible_rect().size
	if Setting.gamemode == Setting.GAMEMODE.Suregi:
		return Vector2(vp.x * 0.5 / camera.zoom.x, vp.y * 0.7 / camera.zoom.y)
	else:
		return Vector2(vp.x * 0.2 / camera.zoom.x, vp.y * 0.5 / camera.zoom.y)
