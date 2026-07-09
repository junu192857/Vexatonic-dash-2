extends Node

# Directional keys
signal pressed_up
signal pressed_down
signal pressed_left
signal pressed_right

# Action keys
signal pressed_enter
signal pressed_tab
signal pressed_delete
signal pressed_f
signal toggled_shift(pressed: bool)
signal pressed_f10

# Note / movement keys (with release)
signal pressed_a
signal released_a
signal pressed_s
signal released_s
signal pressed_d
signal released_d
signal pressed_j
signal released_j
signal pressed_k
signal released_k
signal pressed_l
signal released_l

# Mouse
signal mouse_left_pressed
signal mouse_right_toggled(pressed: bool)
signal mouse_scrolled_up
signal mouse_scrolled_down
signal mouse_moved(position: Vector2)

func _input(event):
	if event is InputEventKey:
		match event.keycode:
			KEY_UP:
				if event.pressed: pressed_up.emit()
			KEY_DOWN:
				if event.pressed: pressed_down.emit()
			KEY_LEFT:
				if event.pressed: pressed_left.emit()
			KEY_RIGHT:
				if event.pressed: pressed_right.emit()
			KEY_ENTER:
				if event.pressed: pressed_enter.emit()
			KEY_TAB:
				if event.pressed: pressed_tab.emit()
			KEY_DELETE:
				if event.pressed: pressed_delete.emit()
			KEY_F:
				if event.pressed: pressed_f.emit()
			KEY_SHIFT:
				toggled_shift.emit(event.pressed)
			KEY_A:
				if event.pressed and not event.is_echo(): pressed_a.emit()
				elif event.is_released(): released_a.emit()
			KEY_S:
				if event.pressed and not event.is_echo(): pressed_s.emit()
				elif event.is_released(): released_s.emit()
			KEY_D:
				if event.pressed and not event.is_echo(): pressed_d.emit()
				elif event.is_released(): released_d.emit()
			KEY_J:
				if event.pressed and not event.is_echo(): pressed_j.emit()
				elif event.is_released(): released_j.emit()
			KEY_K:
				if event.pressed and not event.is_echo(): pressed_k.emit()
				elif event.is_released(): released_k.emit()
			KEY_L:
				if event.pressed and not event.is_echo(): pressed_l.emit()
				elif event.is_released(): released_l.emit()
			KEY_F10:
				if event.pressed: pressed_f10.emit()

	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed: mouse_left_pressed.emit()
			MOUSE_BUTTON_RIGHT:
				mouse_right_toggled.emit(event.pressed)
			MOUSE_BUTTON_WHEEL_UP:
				mouse_scrolled_up.emit()
			MOUSE_BUTTON_WHEEL_DOWN:
				mouse_scrolled_down.emit()

	if event is InputEventMouseMotion:
		mouse_moved.emit(event.position)
