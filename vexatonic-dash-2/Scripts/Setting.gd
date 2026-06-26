class_name Setting

# ================== 상수 ==============================

static var PX_PER_MS = 0.5
#단노트의 좌우 길이
static var NOTE_WIDTH = 24
#Connector의 높이의 절반
static var HALF_CONNECTOR_HEIGHT = 25

#레인 중앙 기준 캐릭터의 발 위치
static var CHARACTER_POS_Y = -26

const DIFFICULTY_NAMES = ["Easy", "Hard", "Vex"]

static var EPSILON = 0.1

static var INFINITE = 99999999

static var EDITOR_LINE_WIDTH = 6.0

# ==================== 플레이어 세팅 ========================

static var speed = 1.5

enum SCORE_DISPLAY {Increasing, Decreasing}
enum GAMEMODE {Normal_Character, Normal_Line, Suregi}

static var score_display = SCORE_DISPLAY.Decreasing
static var gamemode = GAMEMODE.Normal_Character
static var sound_offset: float = 0
static var judge_offset: float = 0
static var selected_difficulty: int = 0

# ==================== 관련 함수 ============================

const SETTINGS_PATH = "user://settings.cfg"
const SECTION = "player"

#Setting.save()를 호출해야 저장이 됨. 아직은 안 됨
static func save() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value(SECTION, "speed", speed)
	cfg.set_value(SECTION, "score_display", score_display)
	cfg.set_value(SECTION, "gamemode", gamemode)
	cfg.set_value(SECTION, "sound_offset", sound_offset)
	cfg.set_value(SECTION, "judge_offset", judge_offset)
	cfg.save(SETTINGS_PATH)

static func load() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	speed         = cfg.get_value(SECTION, "speed",         speed)
	score_display = cfg.get_value(SECTION, "score_display", score_display)
	gamemode      = cfg.get_value(SECTION, "gamemode",      gamemode)
	sound_offset  = cfg.get_value(SECTION, "sound_offset",  sound_offset)
	judge_offset  = cfg.get_value(SECTION, "judge_offset",  judge_offset)

static var time_per_note_width = NOTE_WIDTH / (PX_PER_MS * speed)

static func get_posx_from_time(time: float) -> float:
	return time * PX_PER_MS * speed
	
static func get_time_from_posx(posx_float: float) -> float:
	return posx_float / (PX_PER_MS * speed)
	
