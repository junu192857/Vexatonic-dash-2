class_name LevelData

var lanes: Array[Lane]
var noteDatas: Array[NoteData]
var triggers: Array[Trigger]

#레벨 이름
var name: String
# 채보 폴더 내 음악 파일의 경로. file.mp3 형태
var music_path: String
# [Easy, Hard, Vex] 순서의 난이도. METADATA에서 직접 수정해야 함
var difficulty: Array
# 곡의 길이(ms단위).
var length: float

func sort_noteDatas():
	noteDatas.sort_custom(func(a: NoteData, b: NoteData):
		if a.lane != b.lane:
			return a.lane < b.lane
		return a.time < b.time
	)

func sort_triggers():
	triggers.sort_custom(func(a:Trigger, b:Trigger):
		return a.start < b.start
	)
	
