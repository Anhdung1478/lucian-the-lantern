class_name ConfirmPopup
extends CanvasLayer
## A Yes / No question over everything else. Swallows all keys while open;
## ESC answers No when the question allows it.

const BUTTON_SIZE := Vector2(200, 56)

var _on_yes := Callable()
var _on_no := Callable()
var _escape_means_no := true
var _message: Label


func _ready() -> void:
	layer = 80
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
	for yes in [true, false]:
		var button := Button.new()
		button.text = "Yes" if yes else "No"
		button.custom_minimum_size = BUTTON_SIZE
		UiStyle.style_button(button)
		button.pressed.connect(answer.bind(yes))
		row.add_child(button)


func ask(text: String, on_yes: Callable, on_no := Callable(), escape_means_no := true) -> void:
	_message.text = text
	_on_yes = on_yes
	_on_no = on_no
	_escape_means_no = escape_means_no
	visible = true


func is_open() -> bool:
	return visible


## Hides the pop-up, then calls the matching callable.
func answer(yes: bool) -> void:
	visible = false
	var action := _on_yes if yes else _on_no
	if action.is_valid():
		action.call()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_ESCAPE and _escape_means_no:
			answer(false)
		get_viewport().set_input_as_handled()
