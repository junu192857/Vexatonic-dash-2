class_name ConnectorData

var color: int
var length: float
var delta_y: float

func _init(p_color: int, p_length: float, p_delta_y: float):
	color = p_color
	length = p_length
	delta_y = p_delta_y

func set_color(p_color: int):
	color = p_color

func set_length(p_length: float):
	length = p_length

func set_delta_y(p_delta: float):
	delta_y = p_delta
