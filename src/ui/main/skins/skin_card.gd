class_name SkinCard
extends PanelContainer
## One Skin Shop card: portrait, name, bonuses (green), weaknesses (red),
## playstyle and the Purchase / Equip / Equipped button at the bottom.

signal buy_pressed(id: StringName)
signal equip_pressed(id: StringName)

const SIZE := Vector2(320, 640)
const PORTRAIT := 288.0
const BONUS_COLOR := Color("6fd36f")
const WEAKNESS_COLOR := Color("ff6a5a")
const PURPLE_ICON := preload("res://assets/art/ui/essence_purple.svg")

var skin: SkinData
var button := Button.new()


func _init(skin_data: SkinData = null) -> void:
	skin = skin_data
	custom_minimum_size = SIZE
	size = SIZE
	_build()


## Sets the button and the border from the save.
func refresh(save: SaveGame) -> void:
	var equipped := save.skin == skin.id
	var owned := skin.id in save.owned_skins
	var border := UiStyle.GOLD_COLOR if equipped else UiStyle.BORDER_COLOR
	add_theme_stylebox_override(&"panel", UiStyle.panel(UiStyle.PANEL_COLOR, border, 5 if equipped else 2, 16.0))
	button.icon = null
	button.remove_theme_color_override(&"font_disabled_color")
	if equipped:
		button.text = "Equipped"
		button.disabled = true
	elif owned:
		button.text = "Equip"
		button.disabled = false
	else:
		button.text = "Purchase  %d" % skin.cost
		button.icon = PURPLE_ICON
		button.disabled = not save.essences.can_afford(0, 0, skin.cost)
		if button.disabled:
			button.add_theme_color_override(&"font_disabled_color", UiStyle.ERROR_COLOR)


func _build() -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 8)
	add_child(column)
	var frame := TextureRect.new()
	frame.texture = skin.portrait
	frame.custom_minimum_size = Vector2(PORTRAIT, PORTRAIT)
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(frame)
	var name_label := UiStyle.label(skin.display_name, 26, UiStyle.TITLE_COLOR)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(name_label)
	_lines(column, skin.bonuses, BONUS_COLOR)
	_lines(column, skin.weaknesses, WEAKNESS_COLOR)
	var play := UiStyle.label(skin.playstyle, 16, UiStyle.DIM_COLOR)
	play.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	play.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(play)
	UiStyle.style_button(button, 22)
	button.custom_minimum_size = Vector2(0, 48)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	button.expand_icon = true
	button.add_theme_constant_override(&"icon_max_width", 24)
	button.pressed.connect(_on_pressed)
	column.add_child(button)


## One label per line; "—" when there are none (Classic).
func _lines(parent: Control, lines: PackedStringArray, color: Color) -> void:
	for line in lines if not lines.is_empty() else PackedStringArray(["—"]):
		var label := UiStyle.label(line, 18, color)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(label)


func _on_pressed() -> void:
	if skin.id in SaveGame.instance().owned_skins:
		equip_pressed.emit(skin.id)
	else:
		buy_pressed.emit(skin.id)
