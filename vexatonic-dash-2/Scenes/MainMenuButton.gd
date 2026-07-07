extends Button

func activate():
	disabled = false
	$ReferenceRect.visible = true

func deactivate():
	disabled = true
	$ReferenceRect.visible = false
