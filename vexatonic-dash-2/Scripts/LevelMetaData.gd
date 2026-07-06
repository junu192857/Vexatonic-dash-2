class_name LevelMetaData

#레벨 이름
var name: String
# 작곡가명
var artist: String
# 채보 폴더 내 음악 파일의 경로. file.mp3 형태
var music_path: String
# [Easy, Hard, Vex] 순서의 난이도. METADATA에서 직접 수정해야 함
var difficulty: Array
# 곡의 길이(ms단위).
var length: float
