class_name SkinCard
extends PanelContainer
## One Skin Shop card: portrait, name, bonuses (green), weaknesses (red),
## playstyle, a Preview button and the Purchase / Equip / Equipped button at
## the bottom. Purchase only emits buy_pressed: the shop asks before buying.
## Purchase reads as one centred group, "Purchase 25 [purple]" (price_row);
## a skin with no bonus and no weakness (Classic) goes straight from its
## name to its playstyle. A hovered card steps up to a lighter surface; once
## bought, "Purchase 25" crossfades to "Equip" in place.

signal buy_pressed(id: StringName)
signal equip_pressed(id: StringName)
signal preview_pressed(id: StringName)

const SIZE := Vector2(320, 640)
const PORTRAIT := 288.0
const BONUS_COLOR := Color("6fd36f")
const WEAKNESS_COLOR := Color("ff6a5a")
const PURPLE_ICON := preload("res://assets/art/ui/essence_purple.svg")
const BUTTON_FONT := 22
## The bonus and weakness lines, and the playstyle note under them.
const LINE_FONT := 18
const NOTE_FONT := UiStyle.FONT_BODY
## The frame: its corner, and its rim at rest, equipped and hovered.
const RADIUS := 16.0
const RIM := 2
const EQUIPPED_RIM := 5
const HOVER_RIM := Color(UiStyle.TITLE_COLOR, 0.8)

var skin: SkinData
var button := Button.new()
var preview_button := Button.new()
## Inside `button` while the skin is for sale: "Purchase", the price, the icon.
var price_row: HBoxContainer
## 0 at rest, 1 hovered (UiMotion.lit).
var lit_t := 0.0

var _frame := StyleBoxFlat.new()
var _equipped := false
## What the button offered last: &"purchase", &"equip" or &"equipped".
var _offer: StringName
var _swap: Tween


func _init(skin_data: SkinData = null) -> void:
	skin = skin_data
	custom_minimum_size = SIZE
	size = SIZE
	_frame.set_corner_radius_all(int(RADIUS))
	_frame.set_content_margin_all(RADIUS)
	add_theme_stylebox_override(&"panel", _frame)
	_build()
	_paint()
	mouse_entered.connect(func() -> void: UiMotion.lit(self, true, _paint_lit))
	mouse_exited.connect(func() -> void: UiMotion.lit(self, false, _paint_lit))


## Sets the button and the border from the save.
func refresh(save: SaveGame) -> void:
	var equipped := save.skin == skin.id
	var owned := skin.id in save.owned_skins
	_equipped = equipped
	_paint()
	button.icon = null
	button.add_theme_color_override(&"font_disabled_color", UiStyle.DISABLED_FONT)
	var offer: StringName = &"equipped" if equipped else (&"equip" if owned else &"purchase")
	var bought := _offer == &"purchase" and offer == &"equip"
	_offer = offer
	price_row.visible = offer == &"purchase"
	if equipped:
		button.text = Lang.t("Equipped")
		button.disabled = true
	elif owned:
		button.text = Lang.t("Equip")
		button.disabled = false
	else:
		button.text = ""
		UiStyle.price_amount(price_row).set_value(skin.cost, true)
		button.disabled = not save.essences.can_afford(0, 0, skin.cost)
		if button.disabled:
			button.add_theme_color_override(&"font_disabled_color", UiStyle.ERROR_COLOR)
	if bought:
		_crossfade_to_equip()


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
	var name_label := UiStyle.label(Lang.t(skin.display_name), 26, UiStyle.TITLE_COLOR)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(name_label)
	_lines(column, skin.bonuses, BONUS_COLOR)
	_lines(column, skin.weaknesses, WEAKNESS_COLOR)
	var play := UiStyle.label(Lang.t(skin.playstyle), NOTE_FONT, UiStyle.DIM_COLOR)
	play.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	play.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(play)
	preview_button.text = Lang.t("Preview")
	UiStyle.style_button(preview_button, 18)
	preview_button.custom_minimum_size = Vector2(0, 40)
	preview_button.pressed.connect(func() -> void: preview_pressed.emit(skin.id))
	column.add_child(preview_button)
	UiStyle.style_button(button, BUTTON_FONT)
	button.custom_minimum_size = Vector2(0, 48)
	button.pressed.connect(_on_pressed)
	price_row = UiStyle.price_row(Lang.t("Purchase"), skin.cost, PURPLE_ICON, BUTTON_FONT)
	button.add_child(price_row)
	column.add_child(button)


## One label per line; none at all when there are none (Classic: no bonus,
## no weakness, so no meaningless mark in the gain or loss colour).
func _lines(parent: Control, lines: PackedStringArray, color: Color) -> void:
	for line in lines:
		var label := UiStyle.label(Lang.t(line), LINE_FONT, color)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(label)


func _on_pressed() -> void:
	if skin.id in SaveGame.instance().owned_skins:
		equip_pressed.emit(skin.id)
	else:
		buy_pressed.emit(skin.id)


func _paint_lit(_t: float) -> void:
	_paint()


## The frame for the equipped state and the hover: the equipped card keeps
## its gold ring; a hovered card's surface steps up and its rim warms.
func _paint() -> void:
	var t := lit_t
	_frame.bg_color = UiStyle.PANEL_COLOR.lerp(UiStyle.SURFACE_RAISED, t)
	if _equipped:
		_frame.border_color = UiStyle.GOLD_COLOR
		_frame.set_border_width_all(EQUIPPED_RIM)
	else:
		_frame.border_color = UiStyle.BORDER_COLOR.lerp(HOVER_RIM, t)
		_frame.set_border_width_all(RIM)


## The price fades out and "Equip" fades in, in the same button.
func _crossfade_to_equip() -> void:
	if _swap and _swap.is_valid():
		_swap.kill()
	price_row.modulate.a = 1.0
	if UiMotion.off() or not is_inside_tree():
		price_row.visible = false
		return
	price_row.visible = true
	var text_color := button.get_theme_color(&"font_color")
	_set_text_alpha(0.0, text_color)
	_swap = UiMotion.tween(self)
	_swap.tween_property(price_row, ^"modulate:a", 0.0, UiMotion.EXIT)
	_swap.tween_callback(func() -> void:
		price_row.visible = false
		price_row.modulate.a = 1.0)
	_swap.tween_method(_set_text_alpha.bind(text_color), 0.0, 1.0, UiMotion.FAST)
	_swap.tween_callback(button.add_theme_color_override.bind(&"font_color", text_color))


func _set_text_alpha(alpha: float, color: Color) -> void:
	button.add_theme_color_override(&"font_color", Color(color, color.a * alpha))
