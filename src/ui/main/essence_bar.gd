class_name EssenceBar
extends HBoxContainer
## The top bar's left side: the gear button, then blue, orange and purple
## essence (icon and amount). Each essence has a hover card saying where it
## drops and what it buys.

signal gear_pressed

const GEAR_ICON := preload("res://assets/art/ui/gear.svg")
const GEAR_SIZE := 48.0
const ICON_SIZE := 36.0
const AMOUNT_SIZE := 24
const GAP := 28

const KINDS := {
	Essences.BLUE: {
		"icon": "res://assets/art/ui/essence_blue.svg",
		"color": Color("6fb8ff"),
		"text": "Blue essence\nDrops from every enemy.\nBuys Evolution Tree upgrades.",
	},
	Essences.ORANGE: {
		"icon": "res://assets/art/ui/essence_orange.svg",
		"color": Color("ffa14a"),
		"text": "Orange essence\nDrops rarely from enemies, more from elites.\nBuys the better Evolution Tree upgrades, together with blue.",
	},
	Essences.PURPLE: {
		"icon": "res://assets/art/ui/essence_purple.svg",
		"color": Color("c58bff"),
		"text": "Purple essence\nDrops from mini bosses and bosses.\nBuys skins and resets the Evolution Tree.",
	},
}

var essences: Essences
var _amounts := {}


func _init() -> void:
	add_theme_constant_override(&"separation", GAP)


## Builds the bar for `source` and keeps the amounts current.
func setup(source: Essences) -> void:
	essences = source
	var gear := Button.new()
	gear.icon = GEAR_ICON
	gear.expand_icon = true
	gear.flat = true
	gear.focus_mode = Control.FOCUS_NONE
	gear.custom_minimum_size = Vector2(GEAR_SIZE, GEAR_SIZE)
	gear.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gear.pressed.connect(gear_pressed.emit)
	add_child(gear)
	for kind: StringName in Essences.KINDS:
		add_child(_item(kind))
	essences.changed.connect(_refresh)
	_refresh()


## The amount label of one essence.
func amount_label(kind: StringName) -> Label:
	return _amounts[kind]


func _item(kind: StringName) -> Control:
	var info: Dictionary = KINDS[kind]
	var item := EssenceItem.new()
	item.card_text = info["text"]
	item.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	item.add_theme_constant_override(&"separation", 8)
	var icon := TextureRect.new()
	icon.texture = load(info["icon"])
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(icon)
	var amount := UiStyle.label("0", AMOUNT_SIZE, info["color"])
	amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(amount)
	_amounts[kind] = amount
	return item


func _refresh() -> void:
	for kind: StringName in Essences.KINDS:
		_amounts[kind].text = str(essences.amount(kind))


## One essence's icon and amount; the hover tip asks it for its card.
class EssenceItem extends HBoxContainer:
	var card_text := ""

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func tooltip_content() -> Control:
		return TooltipCard.note(card_text)
