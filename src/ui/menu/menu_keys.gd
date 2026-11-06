class_name MenuKeys
extends RefCounted
## Arrow keys and Enter for one menu page, beside the mouse. Up and Down
## (Left and Right too, for a pop-up's buttons side by side) light the next
## button, skipping hidden and disabled ones and wrapping around; Enter or the
## keypad's Enter presses the lit one, with its click (UiStyle.add_click hangs
## it on `pressed`). Nothing is lit until the first arrow key, unless the
## owner lights one (a pop-up's confirm button). A lit button wears its own
## hover look; once one is lit, the mouse entering another moves the light
## there, so the keys go on from where the mouse is. No focus is used, so
## Space keeps meaning Center camera. The owner passes keys from its _input
## and calls set_buttons() whenever a page is shown or rebuilt (before the old
## buttons are freed).

## Set on a lit button: the normal looks it had, put back when the light leaves.
const UNLIT_META := &"menu_keys_unlit"
## The lit look: each normal theme item and the hover one copied into it.
const LIT_LOOK := {&"normal": &"hover", &"font_color": &"font_hover_color", &"icon_normal_color": &"icon_hover_color"}

## The page's buttons, in key order (top to bottom, or left to right).
var buttons: Array[Button] = []
## The lit button's index in `buttons`; -1 while none is.
var lit := -1

## Each button's mouse_entered connection, undone when the page changes.
var _hovers: Array[Callable] = []


## The buttons under `page` in tree order (top to bottom in a column).
static func buttons_in(page: Node) -> Array[Button]:
	var found: Array[Button] = []
	for child in page.get_children():
		if child is Button:
			found.append(child)
		else:
			found.append_array(buttons_in(child))
	return found


## The page shown is now `page`: the old light goes out and nothing is lit.
func set_buttons(page: Array[Button]) -> void:
	clear()
	for i in buttons.size():
		if buttons[i].mouse_entered.is_connected(_hovers[i]):
			buttons[i].mouse_entered.disconnect(_hovers[i])
	buttons = page.duplicate()
	_hovers.clear()
	for button in buttons:
		var hover := _on_mouse_entered.bind(button)
		button.mouse_entered.connect(hover)
		_hovers.append(hover)


## Reads one key press; true when it was used (the owner marks it handled).
func handle(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key == null or not key.pressed:
		return false
	match key.keycode:
		KEY_UP, KEY_LEFT:
			return _move(-1)
		KEY_DOWN, KEY_RIGHT:
			return _move(1)
		KEY_ENTER, KEY_KP_ENTER:
			return not key.echo and _press()
	return false


## Lights button `index` of the page; the one lit before gets its look back.
func light(index: int) -> void:
	if index == lit or index < 0 or index >= buttons.size():
		return
	clear()
	lit = index
	var button := buttons[index]
	var looks := {}
	for state: StringName in LIT_LOOK:
		var hover: Variant = _override(button, LIT_LOOK[state])
		if hover != null:
			looks[state] = [_override(button, state), hover]
			_set_override(button, state, hover)
	button.set_meta(UNLIT_META, looks)


## Puts the light out: the lit button gets its own look back.
func clear() -> void:
	if lit >= 0 and lit < buttons.size():
		_unlight(buttons[lit])
	lit = -1


## The lit button, or null.
func lit_button() -> Button:
	return buttons[lit] if lit >= 0 and lit < buttons.size() else null


## Lights the next usable button `step` away, wrapping; with none lit, Down
## starts at the top and Up at the bottom. False when none can be lit.
func _move(step: int) -> bool:
	var count := buttons.size()
	var index := lit if lit >= 0 else (-1 if step > 0 else count)
	for i in count:
		index = wrapi(index + step, 0, count)
		if _usable(buttons[index]):
			light(index)
			return true
	return false


## Presses the lit button as a click does; false when none can be pressed.
func _press() -> bool:
	var button := lit_button()
	if button == null or not _usable(button):
		return false
	button.pressed.emit()
	return true


func _on_mouse_entered(button: Button) -> void:
	if lit >= 0 and _usable(button):
		light(buttons.find(button))


static func _usable(button: Button) -> bool:
	return button.is_visible_in_tree() and not button.disabled


## Puts back the looks a lit button had. A look restyled since (a slot list
## refresh) is kept.
static func _unlight(button: Button) -> void:
	if not button.has_meta(UNLIT_META):
		return
	var looks: Dictionary = button.get_meta(UNLIT_META)
	button.remove_meta(UNLIT_META)
	for state: StringName in looks:
		if _override(button, state) == looks[state][1]:
			_set_override(button, state, looks[state][0])


## `button`'s own stylebox or color for `state`, or null when it has none.
static func _override(button: Button, state: StringName) -> Variant:
	if state == &"normal" or state == &"hover":
		return button.get_theme_stylebox(state) if button.has_theme_stylebox_override(state) else null
	return button.get_theme_color(state) if button.has_theme_color_override(state) else null


## Sets `button`'s own stylebox or color for `state`; null removes it.
static func _set_override(button: Button, state: StringName, value: Variant) -> void:
	if state == &"normal":
		if value == null:
			button.remove_theme_stylebox_override(state)
		else:
			button.add_theme_stylebox_override(state, value)
	elif value == null:
		button.remove_theme_color_override(state)
	else:
		button.add_theme_color_override(state, value)
