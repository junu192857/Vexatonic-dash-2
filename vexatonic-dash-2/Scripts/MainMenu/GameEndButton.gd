extends MainMenuButton

func activate():
	$ReferenceRect.visible = true
	$Label.text = "벌써 갈거야..?"
	pass

func deactivate():
	$ReferenceRect.visible = false
	$Label.text = "게임 종료"
	pass
