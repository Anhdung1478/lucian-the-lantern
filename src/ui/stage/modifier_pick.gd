class_name ModifierPick
extends CanvasLayer
## Endless mode, after each boss wave (design: Modifiers): three cards over
## the paused game, two modifiers and Nothing (EndlessModifiers.offer). A card
## shows its icon, its downside and its reward. A click picks; the director
## then closes it. ESC does nothing: the stage's screens are locked meanwhile.

## A card was clicked: its EndlessModifiers id.
signal picked(id: int)

## Over the HUD and the backpack, under the menus and the result.
const LAYER := 36
const TITLE := "Choose a modifier"
const CARD_SIZE := Vector2(280, 230)
const CARD_MARGIN := 16.0
const ICON_SIZE := 64.0
const LINE_FONT_SIZE := 20
## The downside's color, and the reward's (the result's reward lines).
const DOWNSIDE_COLOR := UiStyle.ERROR_COLOR
const REWARD_COLOR := StageResult.REWARD_COLOR

## The cards' ids, in order: Nothing last.
var ids: Array[int] = []
## The cards' buttons, in the same order.
var cards: Array[Button] = []


func _init(offered: Array[int] = []) -> void:
	ids = offered


func _ready() -> void:
	layer = LAYER
	process_mode = PROCESS_MODE_ALWAYS
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
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 22)
	panel.add_child(column)
	var title := UiStyle.label(TITLE, 32, UiStyle.TITLE_COLOR)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 20)
	column.add_child(row)
	for id in ids:
		var card := _card(id)
		row.add_child(card)
		cards.append(card)


## A button with the modifier's icon (none for Nothing) and its two lines.
func _card(id: int) -> Button:
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	UiStyle.style_button(card)
	card.pressed.connect(picked.emit.bind(id))
	var lines := VBoxContainer.new()
	lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, int(CARD_MARGIN))
	lines.alignment = BoxContainer.ALIGNMENT_CENTER
	lines.add_theme_constant_override(&"separation", 12)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(lines)
	var icon := TextureRect.new()
	icon.texture = EndlessModifiers.icon(id)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.add_child(icon)
	for line: Array in [[EndlessModifiers.downside(id), DOWNSIDE_COLOR], [EndlessModifiers.reward(id), REWARD_COLOR]]:
		var label := UiStyle.label(line[0], LINE_FONT_SIZE, line[1])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lines.add_child(label)
	return card
