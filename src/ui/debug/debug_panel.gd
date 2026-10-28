class_name DebugPanel
extends CanvasLayer
## Base of the F3 + Q testing panels: starts hidden, toggles on F3 + Q, keeps
## working while the game is paused, and gives the red-bordered frame and the
## small widget helpers.

const PANEL_WIDTH := 400.0

var _panel: PanelContainer


func _ready() -> void:
	layer = 50
	process_mode = PROCESS_MODE_ALWAYS
	visible = false


## _input runs before the controller's _unhandled_input, so Q never casts here.
func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode == KEY_Q 			and Input.is_physical_key_pressed(KEY_F3):
		visible = not visible
		get_viewport().set_input_as_handled()


## The red-bordered panel (400 px wide at (12, 12)) with the title in it.
## Returns the VBox the content goes into.
func _build_frame(title: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	_panel = panel
	panel.custom_minimum_size.x = PANEL_WIDTH
	panel.position = Vector2(12, 12)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.08, 0.94)
	style.border_color = Color(0.85, 0.35, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override(&"panel", style)
	add_child(panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override(&"separation", 6)
	panel.add_child(outer)
	var title_label := _label(outer, title)
	title_label.add_theme_color_override(&"font_color", Color(0.95, 0.45, 0.4))
	return outer


func _tab(tabs: TabContainer, tab_name: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = tab_name
	box.add_theme_constant_override(&"separation", 6)
	tabs.add_child(box)
	return box


func _section(parent: Control, text: String) -> void:
	parent.add_child(HSeparator.new())
	var label := _label(parent, text.to_upper())
	label.add_theme_color_override(&"font_color", Color("c9a45c"))
	label.add_theme_font_size_override(&"font_size", 13)


func _label(parent: Control, text: String) -> Label:
	var label := Label.new()
	label.text = text
	parent.add_child(label)
	return label


func _row(parent: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	parent.add_child(row)
	return row


func _button(parent: Control, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _check(parent: Control, text: String) -> CheckBox:
	var check := CheckBox.new()
	check.text = text
	check.focus_mode = Control.FOCUS_NONE
	parent.add_child(check)
	return check


func _spin(parent: Control, low: float, high: float, value: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = low
	spin.max_value = high
	spin.set_value_no_signal(value)
	spin.select_all_on_focus = true
	parent.add_child(spin)
	return spin
