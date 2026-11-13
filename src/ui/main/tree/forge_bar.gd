class_name ForgeBar
extends HBoxContainer
## The essence forge, at the top of the Evolution Tree page beside Reset tree:
## two buttons that turn blue essence into orange ("120 blue -> 1 orange" and
## "1200 blue -> 10 orange"). A button is off, with a hover card saying why,
## while the blue is short. A forge cannot be undone, and it changes the
## essences in memory only, as a purchase does (the next save keeps it).

const SIZE := Vector2(412, 52)
const COUNTS: Array[int] = [1, 10]
const FONT_SIZE := 20
const ICON_SIZE := 26.0
const GAP := 8
const BLUE_ICON := preload("res://assets/art/ui/essence_blue.svg")
const ORANGE_ICON := preload("res://assets/art/ui/essence_orange.svg")

## Forge count -> its button.
var buttons := {}
var essences: Essences


func _init(owned: Essences) -> void:
	essences = owned
	custom_minimum_size = SIZE
	size = SIZE
	add_theme_constant_override(&"separation", GAP)
	for count in COUNTS:
		var button := _button(count)
		buttons[count] = button
		add_child(button)
	essences.changed.connect(refresh)
	refresh()


## Greys out what the blue can't pay and says why on hover.
func refresh() -> void:
	for count: int in buttons:
		var button: Button = buttons[count]
		var short := not essences.can_afford(count * Essences.FORGE_BLUE)
		button.disabled = short
		if short:
			button.set_meta(&"hover_text", Lang.t("Needs %d blue essence") % (count * Essences.FORGE_BLUE))
		else:
			button.set_meta(&"hover_text", Lang.t("Forge %d orange essence from %d blue. This cannot be undone.") % [count, count * Essences.FORGE_BLUE])


func _button(count: int) -> Button:
	var button := Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, SIZE.y)
	UiStyle.style_button(button, FONT_SIZE)
	button.pressed.connect(func() -> void: _forge(count))
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", GAP)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)
	_add_part(row, str(count * Essences.FORGE_BLUE), BLUE_ICON)
	row.add_child(_label("→"))
	_add_part(row, str(count), ORANGE_ICON)
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
