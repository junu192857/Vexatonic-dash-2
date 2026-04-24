class_name ChartParser

enum NoteColor { RED = 0, BLUE = 1, YELLOW = 2 }
enum NoteType { SHORT = 0, LONG = 1 }


static func parse(path:String, lanes: Array[Lane], noteDatas: Array[NoteData]):
	#var notes: Array[NoteData]
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("ERROR: 채보 파일을 열 수 없습니다.: "+ path)
		return
	
	var current_lane: Lane
	
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		print(line)
		
		if line == "" or line.begins_with("#"):
			continue
		
		var parts = line.split(" ")
		
		if parts[0] == "LANE":
			var index = int(parts[1])
			if (Lane.find_lane(lanes, index)) == null:
				current_lane = Lane.new(index)
				lanes.append(current_lane)
			else:
				push_error("ERROR: lane index %d already exist" % index)
			continue
		
		if parts[0] == "END" and current_lane:
			current_lane = null
			continue
		
		if parts.size() == 2 and current_lane:
			current_lane.add_keyframe(float(parts[0]), float(parts[1]))
			continue
			
		if current_lane == null and parts.size() >= 5:
			var time = float(parts[0])
			var color = int(parts[1])
			var type = int(parts[2])
			var end_time = float(parts[3])
			var lane = int(parts[4])

			noteDatas.append(NoteData.new(time, color, type, end_time, lane))
			print("append done")
		
	return
	
