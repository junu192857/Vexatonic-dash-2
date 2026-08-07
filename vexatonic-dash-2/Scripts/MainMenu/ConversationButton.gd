extends MainMenuButton


# Called when the node enters the scene tree for the first time.
func activate():
	scale = 1.3 * Vector2.ONE

func deactivate():
	scale = Vector2.ONE
