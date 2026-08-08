extends TextureRect

signal close_setting

enum SettingItem {
	Speed, SoundOffset, JudgeOffset, Gamemode, MirrorMode, TrackSkip,
	MasterVolume, TapSound, GuideSound, GuideSoundOffset, JudgementSFX,
	ScoreDisplay, VexatonicDisplay, SparklicDisplay, WildDisplay, ComboDisplay, Cover1, Cover2,
}
enum Category { Gameplay, Sound, IngameDisplay, Etc }

const CATEGORY_ITEMS = [
	[SettingItem.Speed, SettingItem.SoundOffset, SettingItem.JudgeOffset, SettingItem.Gamemode, SettingItem.MirrorMode, SettingItem.TrackSkip],
	[SettingItem.MasterVolume, SettingItem.TapSound, SettingItem.GuideSound, SettingItem.GuideSoundOffset, SettingItem.JudgementSFX],
	[SettingItem.ScoreDisplay, SettingItem.VexatonicDisplay, SettingItem.SparklicDisplay, SettingItem.WildDisplay, SettingItem.ComboDisplay, SettingItem.Cover1, SettingItem.Cover2],
	[],
]

const ROW_HEIGHT = 52.0
const ROW_VALUE_WIDTH = 260.0

const ON_OFF_LABELS = ["OFF", "ON"]
const GAMEMODE_LABELS = ["TypeA", "TypeB", "TypeC"]
const GAMEMODE_INFO = [
	"TypeA: 캐릭터가 보입니다.",
	"TypeB: 판정선이 보입니다.",
	"TypeC: 노트가 위에서 내려옵니다. 판정선이 보이고 하얀색 플랫폼이 보이지 않습니다."
]
const TRACK_SKIP_LABELS = ["FVPP", "FV", "FC", "SSS", "SS", "S", "최고기록"]
const TRACK_SKIP_INFO = [
	"Full Vexatonic과 Perfect Paint 중 하나라도 만족하지 못하게 되면 종료합니다.",
	"Full Vexatonic을 만족하지 못하게 되면 종료합니다.",
	"Full Combo를 만족하지 못하게 되면 종료합니다.",
	"SSS를 달성하지 못하게 되면 종료합니다.",
	"SS를 달성하지 못하게 되면 종료합니다.",
	"S를 달성하지 못하게 되면 종료합니다.",
	"자신의 최고기록을 달성하지 못하게 되면 종료합니다.",
]
const JUDGEMENT_SFX_LABELS = ["Sparklic 이하", "Wild 이하", "Miss", "Off"]
const JUDGEMENT_DISPLAY_LABELS = ["Fast/Slow만", "판정만", "전체", "Off"]

var category_index: int = Category.Gameplay
var setting_index: int = 0

@export var unselected_category_texture: Texture2D
@export var selected_category_texture: Texture2D
@export var item_font: FontFile

@onready var information: Label = $CategoryLabels/Information

@onready var category_scrolls: Array = [
	$CategoryLabels/Gameplay, $CategoryLabels/Sound, $CategoryLabels/IngameDisplay, $CategoryLabels/Etc
]
@onready var category_vboxes: Array = [
	$CategoryLabels/Gameplay/VBox, $CategoryLabels/Sound/VBox, $CategoryLabels/IngameDisplay/VBox, $CategoryLabels/Etc/VBox
]
@onready var category_buttons: Array = [
	$GameplayButton, $SoundButton, $IngameDisplayButton, $EtcButton
]

var item_specs: Dictionary = {}
var item_row_nodes: Dictionary = {}
var item_value_labels: Dictionary = {}

func _ready():
	InputManager.pressed_up.connect(_on_pressed_up)
	InputManager.pressed_down.connect(_on_pressed_down)
	InputManager.pressed_left.connect(_on_pressed_left)
	InputManager.pressed_right.connect(_on_pressed_right)
	InputManager.pressed_a.connect(_on_pressed_category_left)
	InputManager.pressed_d.connect(_on_pressed_category_right)

	_build_item_specs()
	_build_rows()

func _initialize():
	_load_setting_values()
	category_index = Category.Gameplay
	setting_index = 0
	_refresh_category_selection()
	_refresh_setting_selection()

#============================== Input =====================================

func _on_pressed_up():
	if visible:
		var count = CATEGORY_ITEMS[category_index].size()
		if count > 0:
			setting_index = (setting_index - 1 + count) % count
			_refresh_setting_selection()

func _on_pressed_down():
	if visible:
		var count = CATEGORY_ITEMS[category_index].size()
		if count > 0:
			setting_index = (setting_index + 1) % count
			_refresh_setting_selection()

func _on_pressed_left():
	if visible:
		_apply_value_change(false)

func _on_pressed_right():
	if visible:
		_apply_value_change(true)

func _on_pressed_category_left():
	if visible:
		_change_category(-1)

func _on_pressed_category_right():
	if visible:
		_change_category(1)

func _change_category(delta: int):
	var new_index = clampi(category_index + delta, 0, CATEGORY_ITEMS.size() - 1)
	if new_index == category_index:
		return
	category_index = new_index
	setting_index = 0
	_refresh_category_selection()
	_refresh_setting_selection()

#============================== Row 생성 (데이터 기반) ========================

# 항목이 늘어나도 CATEGORY_ITEMS/item_specs에만 추가하면 UI가 자동으로 생성됨
func _build_item_specs():
	item_specs = {
		SettingItem.Speed: {
			"name": "속도",
			"info": "노트 속도를 설정합니다.\n1.0~3.0 사이의 값을 권장합니다.",
			"type": "range", "min": 0.5, "max": 10.0, "step": 0.1,
			"get": func(): return Setting.speed,
			"set": func(v): Setting.speed = v,
			"format": func(v): return "%.1f" % v,
		},
		SettingItem.SoundOffset: {
			"name": "소리 오프셋",
			"info": "음악 싱크를 설정합니다.\nFast가 많다면 (+)방향, Late가 많다면 (-)방향으로 조절하세요.",
			"type": "range", "min": -1000.0, "max": 1000.0, "step": 1.0,
			"get": func(): return Setting.sound_offset,
			"set": func(v): Setting.sound_offset = v,
			"format": func(v): return str(int(v)),
		},
		SettingItem.JudgeOffset: {
			"name": "판정 오프셋",
			"info": "판정 싱크를 설정합니다.\nFast가 많다면 (+)방향, Late가 많다면 (-)방향으로 조절하세요.",
			"type": "range", "min": -1000.0, "max": 1000.0, "step": 1.0,
			"get": func(): return Setting.judge_offset,
			"set": func(v): Setting.judge_offset = v,
			"format": func(v): return str(int(v)),
		},
		SettingItem.Gamemode: {
			"name": "게임 모드",
			"info": func(): return GAMEMODE_INFO[[Setting.GAMEMODE.Normal_Character, Setting.GAMEMODE.Normal_Line, Setting.GAMEMODE.Suregi].find(Setting.gamemode)],
			"type": "enum",
			"values": [Setting.GAMEMODE.Normal_Character, Setting.GAMEMODE.Normal_Line, Setting.GAMEMODE.Suregi],
			"labels": GAMEMODE_LABELS,
			"get": func(): return Setting.gamemode,
			"set": func(v): Setting.gamemode = v,
		},
		SettingItem.MirrorMode: {
			"name": "미러 모드",
			"info": "게임모드가 TypeC일때는 노트 배치가 좌우반전, 그 외의 경우 상하반전이 됩니다.",
			"type": "enum",
			"values": [false, true],
			"labels": ON_OFF_LABELS,
			"get": func(): return Setting.mirror_mode,
			"set": func(v): Setting.mirror_mode = v,
		},
		SettingItem.TrackSkip: {
			"name": "트랙 스킵",
			"info": func(): return TRACK_SKIP_INFO[Setting.track_skip],
			"type": "enum",
			"values": [Setting.TRACK_SKIP.FVPP, Setting.TRACK_SKIP.FV, Setting.TRACK_SKIP.FC, Setting.TRACK_SKIP.SSS, Setting.TRACK_SKIP.SS, Setting.TRACK_SKIP.S, Setting.TRACK_SKIP.BestScore],
			"labels": TRACK_SKIP_LABELS,
			"get": func(): return Setting.track_skip,
			"set": func(v): Setting.track_skip = v,
		},
		SettingItem.MasterVolume: {
			"name": "마스터 볼륨",
			"info": "모든 소리의 볼륨을 설정합니다.",
			"type": "range", "min": 0.0, "max": 100.0, "step": 1.0,
			"get": func(): return Setting.master_volume,
			"set": func(v): Setting.master_volume = v,
			"format": func(v): return str(int(v)),
		},
		SettingItem.TapSound: {
			"name": "탭음",
			"info": "노트를 처리했을 때 효과음을 설정합니다.",
			"type": "enum", "values": [false, true], "labels": ON_OFF_LABELS,
			"get": func(): return Setting.tap_sound,
			"set": func(v): Setting.tap_sound = v,
		},
		SettingItem.GuideSound: {
			"name": "가이드음",
			"info": "노트가 판정선에 닿을 때의 효과음을 설정합니다.",
			"type": "enum", "values": [false, true], "labels": ON_OFF_LABELS,
			"get": func(): return Setting.guide_sound,
			"set": func(v): Setting.guide_sound = v,
		},
		SettingItem.GuideSoundOffset: {
			"name": "가이드음 오프셋",
			"info": "가이드음의 싱크를 설정합니다.",
			"type": "range", "min": -1000.0, "max": 1000.0, "step": 1.0,
			"get": func(): return Setting.guide_sound_offset,
			"set": func(v): Setting.guide_sound_offset = v,
			"format": func(v): return str(int(v)),
		},
		SettingItem.JudgementSFX: {
			"name": "판정 효과음",
			"info": "특정 판정 이하가 나왔을 때 발생하는 효과음을 설정합니다.",
			"type": "enum",
			"values": [Setting.JUDGEMENT_SFX.SparklicBelow, Setting.JUDGEMENT_SFX.WildBelow, Setting.JUDGEMENT_SFX.Miss, Setting.JUDGEMENT_SFX.Off],
			"labels": JUDGEMENT_SFX_LABELS,
			"get": func(): return Setting.judgement_sound_effect,
			"set": func(v): Setting.judgement_sound_effect = v,
		},
		SettingItem.ScoreDisplay: {
			"name": "점수 표시",
			"info": "스코어 표시 방식을 설정합니다.",
			"type": "enum",
			"values": [Setting.SCORE_DISPLAY.Increasing, Setting.SCORE_DISPLAY.Decreasing],
			"labels": ["Increase", "Decrease"],
			"get": func(): return Setting.score_display,
			"set": func(v): Setting.score_display = v,
		},
		SettingItem.VexatonicDisplay: {
			"name": "Vexatonic 표시",
			"info": "Vexatonic 판정 표시 방법을 설정합니다.",
			"type": "enum",
			"values": [Setting.JUDGEMENT_DISPLAY.FastSlowOnly, Setting.JUDGEMENT_DISPLAY.JudgeOnly, Setting.JUDGEMENT_DISPLAY.All, Setting.JUDGEMENT_DISPLAY.Off],
			"labels": JUDGEMENT_DISPLAY_LABELS,
			"get": func(): return Setting.vexatonic_display,
			"set": func(v): Setting.vexatonic_display = v,
		},
		SettingItem.SparklicDisplay: {
			"name": "Sparklic 표시",
			"info": "Sparklic 판정 표시 방법을 설정합니다.",
			"type": "enum",
			"values": [Setting.JUDGEMENT_DISPLAY.FastSlowOnly, Setting.JUDGEMENT_DISPLAY.JudgeOnly, Setting.JUDGEMENT_DISPLAY.All, Setting.JUDGEMENT_DISPLAY.Off],
			"labels": JUDGEMENT_DISPLAY_LABELS,
			"get": func(): return Setting.sparklic_display,
			"set": func(v): Setting.sparklic_display = v,
		},
		SettingItem.WildDisplay: {
			"name": "Wild 표시",
			"info": "Wild 판정 표시 방법을 설정합니다.",
			"type": "enum",
			"values": [Setting.JUDGEMENT_DISPLAY.FastSlowOnly, Setting.JUDGEMENT_DISPLAY.JudgeOnly, Setting.JUDGEMENT_DISPLAY.All, Setting.JUDGEMENT_DISPLAY.Off],
			"labels": JUDGEMENT_DISPLAY_LABELS,
			"get": func(): return Setting.wild_display,
			"set": func(v): Setting.wild_display = v,
		},
		SettingItem.ComboDisplay: {
			"name": "콤보 표시",
			"info": "콤보의 표시 여부를 설정합니다.",
			"type": "enum", "values": [false, true], "labels": ON_OFF_LABELS,
			"get": func(): return Setting.combo_display,
			"set": func(v): Setting.combo_display = v,
		},
		SettingItem.Cover1: {
			"name": "가리개1",
			"info": "TypeC가 아닌 모드에서, 화면의 오른쪽에 가리개를 배치합니다.",
			"type": "range", "min": 0.0, "max": 10.0, "step": 1.0,
			"get": func(): return float(Setting.cover1),
			"set": func(v): Setting.cover1 = int(v),
			"format": func(v): return str(int(v)),
		},
		SettingItem.Cover2: {
			"name": "가리개2",
			"info": "TypeC 모드에서, 화면의 위쪽에 가리개를 배치합니다.",
			"type": "range", "min": 0.0, "max": 10.0, "step": 1.0,
			"get": func(): return float(Setting.cover2),
			"set": func(v): Setting.cover2 = int(v),
			"format": func(v): return str(int(v)),
		},
	}

func _build_rows():
	for category in range(CATEGORY_ITEMS.size()):
		for item in CATEGORY_ITEMS[category]:
			_build_row(category_vboxes[category], item)

func _build_row(parent: VBoxContainer, item):
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	parent.add_child(row)

	var name_label = Label.new()
	name_label.text = item_specs[item]["name"]
	name_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	name_label.add_theme_font_size_override("font_size", 40)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if item_font:
		name_label.add_theme_font_override("font", item_font)
	row.add_child(name_label)

	var value_label = Label.new()
	value_label.add_theme_font_size_override("font_size", 32)
	value_label.custom_minimum_size = Vector2(ROW_VALUE_WIDTH, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if item_font:
		value_label.add_theme_font_override("font", item_font)
	row.add_child(value_label)

	item_row_nodes[item] = row
	item_value_labels[item] = value_label

#============================== 값 조회/변경 (제네릭) ==========================

func _get_item_text(item) -> String:
	var spec = item_specs[item]
	match spec["type"]:
		"range":
			return spec["format"].call(spec["get"].call())
		"enum":
			var idx = spec["values"].find(spec["get"].call())
			return spec["labels"][idx]
	return ""

func _get_item_info(item) -> String:
	var info = item_specs[item]["info"]
	if info is Callable:
		return info.call()
	return info

func _load_setting_values():
	for item in item_specs.keys():
		item_value_labels[item].text = _get_item_text(item)

func _apply_value_change(increase: bool):
	var items = CATEGORY_ITEMS[category_index]
	if items.is_empty():
		return
	var item = items[setting_index]
	var spec = item_specs[item]
	match spec["type"]:
		"range":
			var v = clampf(spec["get"].call() + (spec["step"] if increase else -spec["step"]), spec["min"], spec["max"])
			spec["set"].call(v)
		"enum":
			var values = spec["values"]
			var n = values.size()
			var idx = values.find(spec["get"].call())
			idx = (idx + (1 if increase else -1) + n) % n
			spec["set"].call(values[idx])
	item_value_labels[item].text = _get_item_text(item)
	information.text = _get_item_info(item)

#============================== 화면 갱신 =====================================

func _refresh_category_selection():
	for i in range(category_buttons.size()):
		category_buttons[i].texture = selected_category_texture if i == category_index else unselected_category_texture
	for i in range(category_scrolls.size()):
		category_scrolls[i].visible = i == category_index

func _refresh_setting_selection():
	var items = CATEGORY_ITEMS[category_index]
	for i in range(items.size()):
		var value_label: Label = item_value_labels[items[i]]
		value_label.add_theme_color_override("font_color", Color(1.0, 0.275, 0.133, 1.0) if i == setting_index else Color(0, 0, 0))
	if items.is_empty():
		information.text = ""
		return
	var current_item = items[setting_index]
	information.text = _get_item_info(current_item)
	var scroll: ScrollContainer = category_scrolls[category_index]
	scroll.ensure_control_visible(item_row_nodes[current_item])

func close_setting_by_button():
	close_setting.emit()
