extends TextureRect
class_name SettingHolder

@onready var speedValue: Label = $SpeedValue
@onready var soundOffsetValue: Label = $SoundOffsetValue2
@onready var judgeOffsetValue: Label = $JudgeOffsetValue

func refresh():
	speedValue.text = str(Setting.speed)
	soundOffsetValue.text = str(Setting.sound_offset)
	judgeOffsetValue.text = str(Setting.judge_offset)
