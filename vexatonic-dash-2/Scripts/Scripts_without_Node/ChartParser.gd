class_name ChartParser



static func parse(chart_dir: String, difficulty: int) -> LevelData:
	var data = LevelData.new()
	
	# METADATA 파싱
	var meta_file = FileAccess.open(chart_dir + "/METADATA.txt", FileAccess.READ)
	if meta_file == null:
		push_error("ERROR: METADATA.txt를 열 수 없습니다.: " + chart_dir)
		return null
	
	while not meta_file.eof_reached():
		var line = meta_file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var parts = line.split(" ")
		match parts[0]:
			"NAME":   data.name = parts[1]
			"MUSIC":  data.music_path = parts[1]
			"LEVEL":  data.difficulty = [int(parts[1]), int(parts[2]), int(parts[3])]
			"LENGTH": data.length = int(parts[1])
	
	# 채보 파싱
	var chart_path = chart_dir + "/" + Setting.DIFFICULTY_NAMES[difficulty] + ".txt"
	parse_chart(chart_path, data, false)
	
	return data

static func parse_chart(chart_path: String, data: LevelData, is_editor: bool):
	var chart_file = FileAccess.open(chart_path, FileAccess.READ)
	if chart_file == null:
		push_error("ERROR: 채보 파일을 열 수 없습니다.: " + chart_path)
		return null
	
	var current_lane: Lane = null
	while not chart_file.eof_reached():
		var line = chart_file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var parts = line.split(" ")
		
		if parts[0] == "BPM":
			data.bpm.append(Vector2(float(parts[1]), float(parts[2])))
			print("BPM added")
			continue
		
		if parts[0] == "LANE":
			var index = int(parts[1])
			var is_init = int(parts[2]) == 1
			current_lane = Lane.new(index, is_init)
			data.lanes.append(current_lane)
			continue
		
		if parts[0] == "END":
			current_lane = null
			continue
		
		if current_lane and parts.size() == 2:
			current_lane.add_keyframe(float(parts[0]), float(parts[1]))
			continue
		
		if current_lane == null and parts.size() >= 5:
			data.noteDatas.append(NoteData.new(float(parts[0]), int(parts[1]), int(parts[2]), \
					float(parts[3]) if int(parts[2]) == 1 else float(parts[0]), int(parts[4])))
