extends TextureRect
class_name SettingHolder

enum SettingItem { Speed = 0, SoundOffset = 1, JudgeOffset = 2 }
const SELECTED_COLOR = Color(1.0, 1.0, 0.3)
const NORMAL_COLOR = Color(1.0, 1.0, 1.0)

@onready var speedValue: Label = $SpeedValue
@onready var soundOffsetValue: Label = $SoundOffsetValue2
@onready var judgeOffsetValue: Label = $JudgeOffsetValue

var selected: SettingItem = SettingItem.Speed

func refresh():
	speedValue.text = "%.1f" % Setting.speed
	soundOffsetValue.text = str(Setting.sound_offset)
	judgeOffsetValue.text = str(Setting.judge_offset)
	_update_selection_color()

func select_next():
	selected = (selected + 1) % 3
	_update_selection_color()

func select_prev():
	selected = (selected - 1 + 3) % 3
	_update_selection_color()

func change_value(increase: bool):
	match selected:
		SettingItem.Speed:
			var delta = 0.1 if increase else -0.1
			Setting.speed = clampf(snappedf(Setting.speed + delta, 0.1), 0.5, 10.0)
		SettingItem.SoundOffset:
			Setting.sound_offset = clampf(Setting.sound_offset + (1 if increase else -1), -1000.0, 1000.0)
		SettingItem.JudgeOffset:
			Setting.judge_offset = clampf(Setting.judge_offset + (1 if increase else -1), -1000.0, 1000.0)
	refresh()

func _update_selection_color():
	speedValue.add_theme_color_override("font_color", SELECTED_COLOR if selected == SettingItem.Speed else NORMAL_COLOR)
	soundOffsetValue.add_theme_color_override("font_color", SELECTED_COLOR if selected == SettingItem.SoundOffset else NORMAL_COLOR)
	judgeOffsetValue.add_theme_color_override("font_color", SELECTED_COLOR if selected == SettingItem.JudgeOffset else NORMAL_COLOR)
