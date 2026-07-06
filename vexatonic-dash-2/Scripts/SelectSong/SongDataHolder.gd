extends TextureRect
class_name SongDataHolder

const PLAY_DATA_PATH = "user://play_data.cfg"

const RANK_NAMES = ["", "D", "C", "B", "A", "AA", "AAA", "S", "SS", "SSS", "V"]
const LAMP_NAMES = ["", "Full Combo", "Full Vexatonic"]

@onready var scoreValue: Label = $ScoreValue
@onready var vexatonicValue: Label = $VexatonicValue
@onready var rank: Label = $Rank
@onready var fcfvLamp: Label = $FCFVlamp
@onready var paintLamp: Label = $PaintLamp

func load_play_data(chart_dir: String, total_notes: int):
	var s = "%s|%d" % [chart_dir, Setting.selected_difficulty]
	var cfg = ConfigFile.new()
	cfg.load(PLAY_DATA_PATH)

	var best_score = cfg.get_value(s, "best_score", 0)
	var best_judge = cfg.get_value(s, "best_judge", 0)
	var combo_lamp = cfg.get_value(s, "combo_lamp", 0)
	var paint = cfg.get_value(s, "paint_lamp", false)
	var rank_val = cfg.get_value(s, "rank", 0)

	scoreValue.text = str(best_score)
	vexatonicValue.text = "%d / %d" % [best_judge, total_notes]
	rank.text = RANK_NAMES[rank_val]
	fcfvLamp.text = LAMP_NAMES[combo_lamp]
	paintLamp.text = "Perfect Paint" if paint else ""
