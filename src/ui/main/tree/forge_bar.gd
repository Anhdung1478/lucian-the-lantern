class_name ForgeBar
extends HBoxContainer
## The essence forge, in the top bar beside the essences it changes (on the
## Evolution Tree only): the word "Forge" and two quiet buttons that turn
## blue essence into orange ("120 blue -> 1 orange" and "1200 blue -> 10
## orange"). A button keeps its quiet surface in every state; while the blue
## is short its contents dim and a hover card says why. A forge cannot be
## undone, and it changes the essences in memory only, as a purchase does
## (the next save keeps it).

const HEIGHT := 40.0
const COUNTS: Array[int] = [1, 10]
const FONT_SIZE := 18
const ICON_SIZE := 22.0
const GAP := 8
## Inside a button: between its parts, and its side padding.
const PART_GAP := 6
const PAD := 12.0
## An off button's icons.
const ICON_OFF := Color(1, 1, 1, 0.4)
const BLUE_ICON := preload("res://assets/art/ui/essence_blue.svg")
const ORANGE_ICON := preload("res://assets/art/ui/essence_orange.svg")

## Forge count -> its button.
var buttons := {}
## The word "Forge" before the buttons.
var word: Label
var essences: Essences


func _init(owned: Essences) -> void:
	essences = owned
	add_theme_constant_override(&"separation", GAP)
	word = UiStyle.label(Lang.t("Forge"), FONT_SIZE, UiStyle.DIM_COLOR)
	word.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(word)
	for count in COUNTS:
		var button := _button(count)
		buttons[count] = button
		add_child(button)
	essences.changed.connect(refresh)
	refresh()


## A quiet button's boxes: a faint surface with a hairline at rest, a step
## lighter on hover; the same surface, fainter, when off.
static func quiet_style(button: Button, font_size := FONT_SIZE) -> void:
	UiStyle.style_button(button, font_size)
	for state: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
		var box := StyleBoxFlat.new()
		box.set_corner_radius_all(8)
		box.set_border_width_all(1)
		box.content_margin_left = PAD
		box.content_margin_right = PAD
		match state:
			&"normal":
				box.bg_color = Color(1, 1, 1, 0.035)
				box.border_color = Color(UiStyle.BORDER_COLOR, 0.35)
			&"hover":
				box.bg_color = Color(1, 1, 1, 0.08)
				box.border_color = Color(UiStyle.BORDER_COLOR, 0.65)
			&"pressed":
				box.bg_color = Color(1, 1, 1, 0.12)
				box.border_color = Color(UiStyle.BORDER_COLOR, 0.65)
			_:
				box.bg_color = Color(1, 1, 1, 0.025)
				box.border_color = Color(UiStyle.BORDER_COLOR, 0.18)
		button.add_theme_stylebox_override(state, box)
	button.add_theme_color_override(&"font_hover_color", UiStyle.TEXT_COLOR)
	UiStyle.ButtonLook.of(button).adopt()


## Dims what the blue can't pay and says why on hover.
func refresh() -> void:
	for count: int in buttons:
		var button: Button = buttons[count]
		var short := not essences.can_afford(count * Essences.FORGE_BLUE)
		button.disabled = short
		_dim(button, short)
		if short:
			button.set_meta(&"hover_text", Lang.t("Needs %d blue essence") % (count * Essences.FORGE_BLUE))
		else:
			button.set_meta(&"hover_text", Lang.t("Forge %d orange essence from %d blue. This cannot be undone.") % [count, count * Essences.FORGE_BLUE])


## The row inside `button` takes its off look (the button's own disabled
## colour does not reach its children).
func _dim(button: Button, off: bool) -> void:
	for part in button.get_node(^"Row").get_children():
		if part is Label:
			part.add_theme_color_override(&"font_color", UiStyle.DISABLED_FONT if off else UiStyle.TEXT_COLOR)
		elif part is TextureRect:
			part.modulate = ICON_OFF if off else Color.WHITE


func _button(count: int) -> Button:
	var button := Button.new()
	quiet_style(button)
	button.pressed.connect(func() -> void: _forge(count))
	# Its note hangs 8 px under it, not on it at the cursor.
	button.set_meta(&"hover_place", HoverTip.Place.BELOW)
	var row := HBoxContainer.new()
	row.name = &"Row"
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", PART_GAP)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)
	_add_part(row, str(count * Essences.FORGE_BLUE), BLUE_ICON)
	row.add_child(_label("→"))
	_add_part(row, str(count), ORANGE_ICON)
	button.custom_minimum_size = Vector2(row.get_combined_minimum_size().x + PAD * 2.0, HEIGHT)
	row.minimum_size_changed.connect(func() -> void:
		button.custom_minimum_size.x = row.get_combined_minimum_size().x + PAD * 2.0)
	return button


func _add_part(row: HBoxContainer, amount: String, icon: Texture2D) -> void:
	row.add_child(_label(amount))
	var picture := TextureRect.new()
	picture.texture = icon
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(picture)


func _label(text: String) -> Label:
	var label := UiStyle.label(text, FONT_SIZE)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _forge(count: int) -> void:
	if essences.forge(count):
		Sfx.play(&"coin")
