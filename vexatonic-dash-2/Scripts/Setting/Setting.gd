class_name Setting

# ================== 상수 ==============================

const UNPROCESSED_COLORS: Array[Color] = [Color(1, 0.4, 0.4), Color(0.4, 0.4, 1.0), Color(1.0, 1.0, 0.4), Color(0.4, 1.0, 0.4)]
const PROCESSED_COLORS: Array[Color] = [Color(0.8,0,0), Color(0.0, 0.0, 0.7), Color(0.8, 0.7, 0.0), Color(0.0, 0.6, 0.0)]
const SELECTED_COLORS = [Color(1,0,1), Color(0,1,1), Color(1,1,0.7), Color(0,1,0.5)]

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
enum TRACK_SKIP {FVPP, FV, FC, SSS, SS, S, BestScore}
enum JUDGEMENT_SFX {SparklicBelow, WildBelow, Miss, Off}
enum JUDGEMENT_DISPLAY {FastSlowOnly, JudgeOnly, All, Off}

static var score_display = SCORE_DISPLAY.Decreasing
static var gamemode = GAMEMODE.Suregi
static var sound_offset: float = 0
static var judge_offset: float = -20
static var selected_difficulty: int = 1
static var tutorial_played = false

# ==================== 게임플레이 설정 =====================

static var mirror_mode: bool = false
static var track_skip: TRACK_SKIP = TRACK_SKIP.BestScore

# ==================== 사운드 설정 =====================

static var master_volume: float = 100.0
static var tap_sound: bool = true
static var guide_sound: bool = true
static var guide_sound_offset: float = 0.0
static var judgement_sound_effect: JUDGEMENT_SFX = JUDGEMENT_SFX.Off

# ==================== 인게임 표시 설정 =====================

static var vexatonic_display: JUDGEMENT_DISPLAY = JUDGEMENT_DISPLAY.All
static var sparklic_display: JUDGEMENT_DISPLAY = JUDGEMENT_DISPLAY.All
static var wild_display: JUDGEMENT_DISPLAY = JUDGEMENT_DISPLAY.All
static var combo_display: bool = true
static var cover1: int = 0
static var cover2: int = 0

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
	cfg.set_value(SECTION, "mirror_mode", mirror_mode)
	cfg.set_value(SECTION, "track_skip", track_skip)
	cfg.set_value(SECTION, "master_volume", master_volume)
	cfg.set_value(SECTION, "tap_sound", tap_sound)
	cfg.set_value(SECTION, "guide_sound", guide_sound)
	cfg.set_value(SECTION, "guide_sound_offset", guide_sound_offset)
	cfg.set_value(SECTION, "judgement_sound_effect", judgement_sound_effect)
	cfg.set_value(SECTION, "vexatonic_display", vexatonic_display)
	cfg.set_value(SECTION, "sparklic_display", sparklic_display)
	cfg.set_value(SECTION, "wild_display", wild_display)
	cfg.set_value(SECTION, "combo_display", combo_display)
	cfg.set_value(SECTION, "cover1", cover1)
	cfg.set_value(SECTION, "cover2", cover2)
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
	tutorial_played = cfg.get_value(SECTION, "tutorial_played", false)
	mirror_mode = cfg.get_value(SECTION, "mirror_mode", false)
	track_skip = cfg.get_value(SECTION, "track_skip", TRACK_SKIP.BestScore)
	master_volume = cfg.get_value(SECTION, "master_volume", 100.0)
	tap_sound = cfg.get_value(SECTION, "tap_sound", true)
	guide_sound = cfg.get_value(SECTION, "guide_sound", true)
	guide_sound_offset = cfg.get_value(SECTION, "guide_sound_offset", 0.0)
	judgement_sound_effect = cfg.get_value(SECTION, "judgement_sound_effect", JUDGEMENT_SFX.Off)
	vexatonic_display = cfg.get_value(SECTION, "vexatonic_display", JUDGEMENT_DISPLAY.All)
	sparklic_display = cfg.get_value(SECTION, "sparklic_display", JUDGEMENT_DISPLAY.All)
	wild_display = cfg.get_value(SECTION, "wild_display", JUDGEMENT_DISPLAY.All)
	combo_display = cfg.get_value(SECTION, "combo_display", true)
	cover1 = cfg.get_value(SECTION, "cover1", 0)
	cover2 = cfg.get_value(SECTION, "cover2", 0)

static func change_difficulty():
	selected_difficulty = (selected_difficulty + 1) % 3
