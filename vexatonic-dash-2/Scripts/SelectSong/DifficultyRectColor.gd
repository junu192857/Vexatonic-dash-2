extends TextureRect

@export var easy_gradient: GradientTexture2D
@export var hard_gradient: GradientTexture2D
@export var vex_gradient: GradientTexture2D

func set_gradient_texture(diff: int):
	match diff:
		0:
			texture = easy_gradient
		1:
			texture = hard_gradient
		2:
			texture = vex_gradient
		_:
			pass
