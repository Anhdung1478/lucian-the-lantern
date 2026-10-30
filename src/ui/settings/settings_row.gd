class_name SettingsRow
extends PanelContainer
## One row of the Settings screen, drawn as a card: a label with an optional
## dim description under it, and the row's controls on the right. A subtle
## fill and a 1 px border that brightens while the mouse is over the card or
## any of its controls.

const FONT := 19
const NOTE_FONT := 15
## Padding above and below the controls.
const PAD := 7.0

## The texts, then the controls added with add().
var row := HBoxContainer.new()

var _normal := _style(false)
var _hover := _style(true)


func _init(text: String, description := "") -> void:
	# Lets the mouse wheel through to a scrolling list.
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override(&"panel", _normal)
	mouse_entered.connect(add_theme_stylebox_override.bind(&"panel", _hover))
	mouse_exited.connect(add_theme_stylebox_override.bind(&"panel", _normal))
	row.add_theme_constant_override(&"separation", 16)
	add_child(row)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.add_theme_constant_override(&"separation", 0)
	row.add_child(texts)
	texts.add_child(UiStyle.label(text, FONT))
	if description:
		var note := UiStyle.label(description, NOTE_FONT, UiStyle.DIM_COLOR)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		texts.add_child(note)


## Adds `control` on the right, after the ones before it. The mouse passes
## through it to the card: a control that stops the mouse would end Godot's
## hover chain there, and the card would go dark over its own control.
func add(control: Control) -> Control:
	if control.mouse_filter == Control.MOUSE_FILTER_STOP:
		control.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(control)
	return control


static func _style(hover: bool) -> StyleBoxFlat:
	var style := UiStyle.panel(Color(1, 1, 1, 0.055 if hover else 0.03), Color(UiStyle.BORDER_COLOR, 0.6 if hover else 0.18), 1, PAD, 6)
	style.content_margin_left = 18.0
	style.content_margin_right = 14.0
	return style
