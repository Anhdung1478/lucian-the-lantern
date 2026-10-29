class_name ConfirmPopup
extends CanvasLayer
## A question over everything else: Yes / No (ask), Yes / No / Cancel
## (ask_or_cancel) or an action / Cancel (confirm). Swallows all keys while
## open. ESC is Cancel when the question has one; on a Yes / No question it
## answers No when the question allows it.

const BUTTON_SIZE := Vector2(200, 56)
## Above the menus. A pop-up that must stay on top of another one (Game's
## "Save before leaving?") gets a higher layer: it is drawn over the other and
## gets clicks first.
const LAYER := 80

var _on_yes := Callable()
var _on_no := Callable()
var _on_cancel := Callable()
var _escape_means_no := true
var _message: Label
## Built once; each question shows and labels the ones it needs.
var _yes: Button
var _no: Button
var _cancel: Button


func _init(on_layer := LAYER) -> void:
	layer = on_layer


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	visible = false
	_build()


func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.55)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", UiStyle.panel())
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 18)
	panel.add_child(box)
	_message = Label.new()
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.add_theme_color_override(&"font_color", UiStyle.TITLE_COLOR)
	_message.add_theme_font_size_override(&"font_size", 26)
	box.add_child(_message)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 16)
	box.add_child(row)
	_yes = _button(row, "Yes", answer.bind(true))
	_no = _button(row, "No", answer.bind(false))
	_cancel = _button(row, "Cancel", cancel)


func _button(row: HBoxContainer, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = BUTTON_SIZE
	UiStyle.style_button(button)
	button.pressed.connect(action)
	row.add_child(button)
	return button


## Yes / No: Overwrite, Reset tree, "Could not save…". ESC answers No when
## `escape_means_no`, else does nothing.
func ask(text: String, on_yes: Callable, on_no := Callable(), escape_means_no := true) -> void:
	_open(text, "Yes", true, false)
	_on_yes = on_yes
	_on_no = on_no
	_escape_means_no = escape_means_no


## Yes / No / Cancel: "Save before leaving?". The Cancel button and ESC call
## `on_cancel`.
func ask_or_cancel(text: String, on_yes: Callable, on_no: Callable, on_cancel := Callable()) -> void:
	_open(text, "Yes", true, true)
	_on_yes = on_yes
	_on_no = on_no
	_on_cancel = on_cancel


## [action_label] / Cancel: "Exit the game?" Exit / Cancel. The action
## answers like Yes; the Cancel button and ESC call `on_cancel`.
func confirm(text: String, action_label: String, on_action: Callable, on_cancel := Callable()) -> void:
	_open(text, action_label, false, true)
	_on_yes = on_action
	_on_cancel = on_cancel


## Shows the question with these buttons; the last question's answers are dropped.
func _open(text: String, yes_label: String, with_no: bool, with_cancel: bool) -> void:
	_message.text = text
	_yes.text = yes_label
	_no.visible = with_no
	_cancel.visible = with_cancel
	_on_yes = Callable()
	_on_no = Callable()
	_on_cancel = Callable()
	_escape_means_no = false
	visible = true


func is_open() -> bool:
	return visible


## Hides the pop-up, then calls the matching callable (which may ask again).
## Does nothing while the pop-up is closed, so an old question never answers,
## nor No on a question without a No.
func answer(yes: bool) -> void:
	if not visible or (not yes and not _no.visible):
		return
	visible = false
	var action := _on_yes if yes else _on_no
	if action.is_valid():
		action.call()


## The Cancel button and ESC: hides the pop-up, then calls `on_cancel`. Does
## nothing while the pop-up is closed or on a question without Cancel.
func cancel() -> void:
	if not visible or not _cancel.visible:
		return
	visible = false
	if _on_cancel.is_valid():
		_on_cancel.call()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			if _cancel.visible:
				cancel()
			elif _escape_means_no:
				answer(false)
		get_viewport().set_input_as_handled()
