class_name SkinPurchasePopup
extends Control
## The Skin Shop's question before buying a skin: an ornate card (MenuCard)
## over the blurred shop. The skin's portrait stands in its accent's light
## beside a table of its bonuses, its weaknesses, its price, the purple
## essence owned and what is left after buying. A note says buying does not
## equip it. Purchase emits `confirmed` and closes, and is off while the
## price can't be paid; Cancel or ESC (SkinShop.close_popup) closes it. It
## buys nothing itself and saves nothing.

signal confirmed(id: StringName)
signal closed

const PORTRAIT := 220.0
const PORTRAIT_INSET := 8.0
## The table: the keys' column and the values' width.
const KEY_WIDTH := 150.0
const VALUE_WIDTH := 240.0
const ROW_FONT := 19
const KEY_FONT := 16
const ICON_SIZE := 22.0
const BUTTON_WIDTH := 300.0
const NOTE := "Buying does not equip it."
const PURPLE_ICON := preload("res://assets/art/ui/essence_purple.svg")

var skin: SkinData
var essences: Essences
var card: MenuCard
var purchase_button: MenuEntry
var cancel_button: MenuEntry
## The table's amounts: the price, the purple owned and what is left after.
var price_label: Label
var owned_label: Label
var after_label: Label

var _portrait := Control.new()


func _init(skin_data: SkinData = null, owned: Essences = null) -> void:
	skin = skin_data
	essences = owned


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Clicks outside the card stop here.
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	essences.changed.connect(refresh)
	refresh()


## Rereads the purple owned: the table and Purchase follow it.
func refresh() -> void:
	var owned := essences.amount(Essences.PURPLE)
	owned_label.text = str(owned)
	after_label.text = str(owned - skin.cost)
	var short := not essences.can_afford(0, 0, skin.cost)
	after_label.add_theme_color_override(&"font_color", UiStyle.ERROR_COLOR if short else UiStyle.TITLE_COLOR)
	purchase_button.disabled = short


## Closes and frees it.
func close() -> void:
	if is_queued_for_deletion():
		return
	closed.emit()
	queue_free()


func _purchase() -> void:
	if purchase_button.disabled:
		return
	confirmed.emit(skin.id)
	close()


func _build() -> void:
	var backdrop := MenuBackdrop.new()
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(center)
	card = MenuCard.new(Lang.t("PURCHASE SKIN"), Lang.t(skin.display_name))
	center.add_child(card)
	var body := HBoxContainer.new()
	body.add_theme_constant_override(&"separation", 28)
	card.content.add_child(body)
	_portrait.custom_minimum_size = Vector2.ONE * PORTRAIT
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.draw.connect(_draw_portrait)
	body.add_child(_portrait)
	var table := GridContainer.new()
	table.columns = 2
	table.add_theme_constant_override(&"h_separation", 16)
	table.add_theme_constant_override(&"v_separation", 10)
	table.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	body.add_child(table)
	_row(table, Lang.t("Bonuses"), _lines(skin.bonuses, SkinCard.BONUS_COLOR))
	_row(table, Lang.t("Weaknesses"), _lines(skin.weaknesses, SkinCard.WEAKNESS_COLOR))
	price_label = _amount(table, Lang.t("Price"), str(skin.cost))
	owned_label = _amount(table, Lang.t("You have"), "")
	after_label = _amount(table, Lang.t("After purchase"), "")
	var note := UiStyle.label(Lang.t(NOTE), 16, UiStyle.DIM_COLOR)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.content.add_child(note)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override(&"separation", 16)
	card.content.add_child(buttons)
	purchase_button = MenuEntry.new(Lang.t("Purchase  %d") % skin.cost, PURPLE_ICON, MenuEntry.Kind.PRIMARY)
	purchase_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	purchase_button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	purchase_button.set_icon_color(Color.WHITE)
	purchase_button.custom_minimum_size.x = BUTTON_WIDTH
	purchase_button.pressed.connect(_purchase)
	buttons.add_child(purchase_button)
	cancel_button = MenuEntry.new(Lang.t("Cancel"))
	cancel_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	cancel_button.custom_minimum_size.x = BUTTON_WIDTH * 0.6
	cancel_button.pressed.connect(close)
	buttons.add_child(cancel_button)


## A row of the table: its key (dim) and its value.
func _row(table: GridContainer, key: String, value: Control) -> void:
	var label := UiStyle.label(key, KEY_FONT, UiStyle.DIM_COLOR)
	label.custom_minimum_size.x = KEY_WIDTH
	label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	table.add_child(label)
	table.add_child(value)


## One label per line, in `color`; "—" when there are none (Classic).
func _lines(lines: PackedStringArray, color: Color) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 2)
	for line in lines if not lines.is_empty() else PackedStringArray(["—"]):
		var label := UiStyle.label(Lang.t(line), ROW_FONT, color)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = VALUE_WIDTH
		box.add_child(label)
	return box


## A row with an amount and the purple icon; returns the amount's label.
func _amount(table: GridContainer, key: String, text: String) -> Label:
	var line := HBoxContainer.new()
	line.add_theme_constant_override(&"separation", 8)
	var label := UiStyle.label(text, ROW_FONT, UiStyle.TITLE_COLOR)
	line.add_child(label)
	var icon := TextureRect.new()
	icon.texture = PURPLE_ICON
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2.ONE * ICON_SIZE
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(icon)
	_row(table, key, line)
	return label


## The portrait in a frame of the skin's accent, with its glow behind.
func _draw_portrait() -> void:
	var accent := MainBackdrop.accent(skin.id)
	var rect := Rect2(Vector2.ZERO, _portrait.size)
	_portrait.draw_texture_rect(JourneyMap.glow(), rect.grow(40.0), false, Color(accent, 0.3))
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.03, 0.04, 0.06)
	frame.border_color = accent
	frame.set_border_width_all(3)
	frame.set_corner_radius_all(12)
	_portrait.draw_style_box(frame, rect)
	if skin.portrait:
		_portrait.draw_texture_rect(skin.portrait, rect.grow(-PORTRAIT_INSET), false)
