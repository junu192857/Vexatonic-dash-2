class_name LevelData

var lanes: Array[Lane]
var noteDatas: Array[NoteData]
var triggers: Array[Trigger]

var metadata: LevelMetaData

func _init():
	metadata = LevelMetaData.new()

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
	
