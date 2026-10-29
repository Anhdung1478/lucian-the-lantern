class_name GameMenu
extends CanvasLayer
## The ESC menu: Resume, Settings, Leave this stage, Exit the game. The last
## two only emit; under the game root they ask first (Leave / Cancel, Yes /
## No / Cancel), and Cancel comes back to this menu, still paused.

signal resume_requested
signal settings_requested
signal leave_requested
signal exit_requested

const BUTTON_SIZE := Vector2(340, 56)
const NOT_AVAILABLE := "Not available yet"

var _leave: Button


func _ready() -> void:
	layer = 40
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
	box.add_theme_constant_override(&"separation", 14)
	panel.add_child(box)
	var title := Label.new()
	title.text = "MENU"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override(&"font_color", UiStyle.TITLE_COLOR)
	title.add_theme_font_size_override(&"font_size", 30)
	box.add_child(title)
	box.add_child(HSeparator.new())
	_button(box, "Resume", func() -> void: resume_requested.emit())
	_button(box, "Settings", func() -> void: settings_requested.emit())
	_leave = _button(box, "Leave this stage", func() -> void: leave_requested.emit())
	_button(box, "Exit the game", func() -> void: exit_requested.emit())


## Leave this stage is shown disabled, with a hover note, when nothing would
## take the player anywhere (the stage running alone).
func set_leave_enabled(enabled: bool) -> void:
	_leave.disabled = not enabled
	if enabled:
		_leave.remove_meta(&"hover_text")
	else:
		_leave.set_meta(&"hover_text", NOT_AVAILABLE)


## A button without an action is shown disabled, with a hover note.
func _button(parent: Control, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = BUTTON_SIZE
	UiStyle.style_button(button)
	if action.is_valid():
		button.pressed.connect(action)
	else:
		button.disabled = true
		button.set_meta(&"hover_text", NOT_AVAILABLE)
	parent.add_child(button)
	return button
