extends Node2D

@onready var camera = $Camera2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#camera.zoom = Vector2(2,2)
	set_default_position()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func set_default_position():
	if (Setting.gamemode == Setting.GAMEMODE.Suregi):
		camera.rotation = deg_to_rad(90)
		var vp_height = get_viewport().get_visible_rect().size.y / camera.zoom.y
		camera.position = Vector2(vp_height * 0.2, 0.0)
	else:
		var vp = get_viewport().get_visible_rect().size.x / camera.zoom.x
		camera.position = Vector2(vp * 0.3, 0.0)

func move(time:float):
	position = Vector2(Setting.get_posx_from_time(time), 0.0)
