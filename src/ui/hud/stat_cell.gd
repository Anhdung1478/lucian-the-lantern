class_name StatCell
extends HBoxContainer
## One stat in the stats panel: its icon and value, yellow when items or
## effects add to it. Hover it for a second to read what it does and how much
## is base and how much is bonus.

const ICON_SIZE := 20.0
const BASE_COLOR := UiStyle.TEXT_COLOR
const BONUS_COLOR := Color("ffd84a")

var key: StringName

var _value: Label
## TooltipText BBCode, e.g. "60 base + 22 bonus".
var _breakdown := ""


func _init(stat_key: StringName) -> void:
	key = stat_key
	add_theme_constant_override(&"separation", 6)
	mouse_filter = MOUSE_FILTER_PASS
	var icon := TextureRect.new()
	icon.texture = StatStyle.icon(key)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.size_flags_vertical = SIZE_SHRINK_CENTER
	icon.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(icon)
	_value = Label.new()
	_value.custom_minimum_size.x = 44
	_value.add_theme_font_size_override(&"font_size", 16)
	_value.add_theme_color_override(&"font_color", BASE_COLOR)
	_value.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_value)


func show_value(text: String, bonus: bool, breakdown: String) -> void:
	_value.text = text
	_breakdown = breakdown
	var color := BONUS_COLOR if bonus else BASE_COLOR
	if value_color() != color:
		_value.add_theme_color_override(&"font_color", color)


func value_color() -> Color:
	return _value.get_theme_color(&"font_color")


func tooltip_content() -> Control:
	return TooltipCard.stat(key, _value.text, _breakdown)


func tooltip_place() -> HoverTip.Place:
	return HoverTip.Place.ABOVE
