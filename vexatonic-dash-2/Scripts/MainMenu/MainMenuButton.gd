extends TextureRect
class_name MainMenuButton

func activate():
	$ReferenceRect.visible = true

func deactivate():
	$ReferenceRect.visible = false
