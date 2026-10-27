class_name GameMenu
extends CanvasLayer
## The ESC menu: Resume, Settings, Leave this stage, Exit the game. Settings
## and Leave this stage are not built yet, so they are shown disabled.

signal resume_requested

const BUTTON_SIZE := Vector2(340, 56)
const PANEL_COLOR := Color(0.06, 0.075, 0.1, 0.96)
const BORDER_COLOR := Color(0.79, 0.64, 0.36)
const TITLE_COLOR := Color("ffe9a8")


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
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = BORDER_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(28)
	panel.add_theme_stylebox_override(&"panel", style)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 14)
	panel.add_child(box)
	var title := Label.new()
	title.text = "MENU"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override(&"font_color", TITLE_COLOR)
	title.add_theme_font_size_override(&"font_size", 30)
	box.add_child(title)
	box.add_child(HSeparator.new())
	_button(box, "Resume", func() -> void: resume_requested.emit())
	_button(box, "Settings", Callable())
	_button(box, "Leave this stage", Callable())
	_button(box, "Exit the game", func() -> void: get_tree().quit())


## A button without an action is shown disabled, with a hover note.
func _button(parent: Control, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = BUTTON_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override(&"font_size", 22)
	for state: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
		button.add_theme_stylebox_override(state, _button_style(state))
	button.add_theme_color_override(&"font_hover_color", TITLE_COLOR)
	button.add_theme_color_override(&"font_disabled_color", Color(0.45, 0.48, 0.55))
	if action.is_valid():
		button.pressed.connect(action)
	else:
		button.disabled = true
		button.set_meta(&"hover_text", "Not available yet")
	parent.add_child(button)
	return button


func _button_style(state: StringName) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(6)
	style.set_border_width_all(2)
	match state:
		&"hover":
			style.bg_color = Color(0.12, 0.14, 0.19)
			style.border_color = BORDER_COLOR
		&"pressed":
			style.bg_color = Color(0.2, 0.17, 0.1)
			style.border_color = BORDER_COLOR
		&"disabled":
			style.bg_color = Color(0.07, 0.08, 0.1)
			style.border_color = Color(0.2, 0.22, 0.26)
		_:
			style.bg_color = Color(0.09, 0.105, 0.14)
			style.border_color = Color(0.36, 0.4, 0.48)
	return style
