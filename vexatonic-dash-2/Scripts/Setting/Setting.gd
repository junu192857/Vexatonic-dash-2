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

# ==================== 플레이어 상태 관련 ========================

static var speed = 2.0

enum SCORE_DISPLAY {Increasing, Decreasing}
enum GAMEMODE {Normal_Character, Normal_Line, Suregi}

static var score_display = SCORE_DISPLAY.Decreasing
static var gamemode = GAMEMODE.Suregi
static var sound_offset: float = 0
static var judge_offset: float = -20
static var selected_difficulty: int = 1
static var tutorial_played = false

# ==================== 싱글톤 목적 변수 =====================

static var is_tutorial = false
static var selected_chart_dir: String = ""

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
	cfg.set_value(SECTION, "selected_difficulty", selected_difficulty)
	cfg.set_value(SECTION, "tutorial_played", tutorial_played)
	cfg.save(SETTINGS_PATH)

static func load() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	speed         = cfg.get_value(SECTION, "speed",         1.0)
	score_display = cfg.get_value(SECTION, "score_display", SCORE_DISPLAY.Increasing)
	gamemode      = cfg.get_value(SECTION, "gamemode",      GAMEMODE.Normal_Character)
	sound_offset  = cfg.get_value(SECTION, "sound_offset",  0)
	judge_offset  = cfg.get_value(SECTION, "judge_offset",  0)
	selected_difficulty = cfg.get_value(SECTION, "selected_difficulty", 0)
	#tutorial_played = cfg.get_value(SECTION, "tutorial_played", false)

static func time_per_note_width():
	return NOTE_WIDTH / (PX_PER_MS * speed)

static func get_posx_from_time(time: float) -> float:
	return time * PX_PER_MS * speed
	
static func get_time_from_posx(posx_float: float) -> float:
	return posx_float / (PX_PER_MS * speed)

static func change_difficulty():
	selected_difficulty = (selected_difficulty + 1) % 3
