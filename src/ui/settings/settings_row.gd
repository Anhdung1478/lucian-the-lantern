class_name SettingsRow
extends PanelContainer
## One row of the Settings screen, drawn as a card: a label with an optional
## dim description under it, and the row's controls on the right. A faint
## fill, no border; while the mouse is over the card or any of its controls
## the fill eases up to UiStyle.SURFACE_RAISED. The description is a note
## (UiStyle.FONT_NOTE) that wraps 24 px left of the controls.

const FONT := UiStyle.FONT_ROW
const NOTE_FONT := UiStyle.FONT_NOTE
## Padding above and below the controls.
const PAD := 7.0
## The space between the texts and the controls (24 px less the row's own 16): a
## note wraps this far from them.
const CONTROLS_GAP := 24
const ROW_SEPARATION := 16
const REST_FILL := Color(UiStyle.SURFACE_RAISED, 0.4)

## The texts, then the controls added with add().
var row := HBoxContainer.new()

var _box := _style()


func _init(text: String, description := "") -> void:
	# Lets the mouse wheel through to a scrolling list.
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override(&"panel", _box)
	mouse_entered.connect(UiMotion.lit.bind(self, true, _ease))
	mouse_exited.connect(UiMotion.lit.bind(self, false, _ease))
	row.add_theme_constant_override(&"separation", ROW_SEPARATION)
	add_child(row)
	var room := MarginContainer.new()
	room.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	room.add_theme_constant_override(&"margin_right", CONTROLS_GAP - ROW_SEPARATION)
	row.add_child(room)
	var texts := VBoxContainer.new()
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.add_theme_constant_override(&"separation", 0)
	room.add_child(texts)
	texts.add_child(UiStyle.label(text, FONT))
	if description:
		var note := UiStyle.note(description)
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


## The fill `t` of the way from rest (0) to raised (1).
func _ease(t: float) -> void:
	_box.bg_color = REST_FILL.lerp(UiStyle.SURFACE_RAISED, t)


static func _style() -> StyleBoxFlat:
	var style := UiStyle.panel(REST_FILL, Color(0, 0, 0, 0), 0, PAD, 6)
	style.content_margin_left = 18.0
	style.content_margin_right = 14.0
	return style
