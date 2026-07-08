extends Button
class_name MainMenuButton

func activate():
	$ReferenceRect.visible = true
	pass

func deactivate():
	$ReferenceRect.visible = false
	pass
