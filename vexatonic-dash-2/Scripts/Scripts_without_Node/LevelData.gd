class_name LevelData

var lanes: Array[Lane]
var noteDatas: Array[NoteData]

#레벨 이름
var name: String
# (시간(ms단위), bpm) 형태의 Array로 작성.
# Editor에서는 내부적으로 마지막에 (Setting.INFINITE, 60)을 넣지만 채보 파일에 반영되지는 않음.
var bpm: Array[Vector2]
# 채보 폴더 내 음악 파일의 경로. file.mp3 형태
var music_path: String
# [Easy, Hard, Vex] 순서의 난이도. METADATA에서 직접 수정해야 함
var difficulty: Array
# 곡의 길이(ms단위).
var length: float
