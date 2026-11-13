class_name StatCell
extends HBoxContainer
## One stat in the stats panel: its icon and value, yellow when items or
## effects add to it. A value that changes (an item, a buff) glows gold and
## eases back to its own colour over CHANGE_TIME; it does not count, since
## many cells change at once. Hover it for a second to read what it does and
## how much is base and how much is bonus.

const ICON_SIZE := 20.0
const BASE_COLOR := UiStyle.TEXT_COLOR
const BONUS_COLOR := Color("ffd84a")
## How long a changed value takes to ease from gold back to its colour.
const CHANGE_TIME := 0.4

var key: StringName

var _value: Label
## TooltipText BBCode, e.g. "60 base + 22 bonus".
var _breakdown := ""
## The value's own colour (BASE_COLOR or BONUS_COLOR), whatever a glow shows.
var _color := BASE_COLOR
var _glow: Tween


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
	var changed := _value.text != "" and _value.text != text
	_value.text = text
	_breakdown = breakdown
	_color = BONUS_COLOR if bonus else BASE_COLOR
	if changed and not UiMotion.off() and is_inside_tree():
		_glow_from(UiStyle.GOLD_COLOR)
	elif _glow == null and _value.get_theme_color(&"font_color") != _color:
		_value.add_theme_color_override(&"font_color", _color)


## The value's colour: BONUS_COLOR with a bonus, else BASE_COLOR (a glow
## running over it does not count).
func value_color() -> Color:
	return _color


func tooltip_content() -> Control:
	return TooltipCard.stat(key, _value.text, _breakdown)


## What the card shows that can change while it is hovered: the shown value
## and its breakdown. HoverTip rebuilds the card when it changes.
func tooltip_version() -> Variant:
	return [_value.text, _breakdown]


func tooltip_place() -> HoverTip.Place:
	return HoverTip.Place.ABOVE


## The card hangs above the stats panel, over this cell.
func tooltip_anchor() -> Rect2:
	return HudCell.tip_anchor(self)


## The text shows `tint`, easing back to the value's own colour.
func _glow_from(tint: Color) -> void:
	if _glow and _glow.is_valid():
		_glow.kill()
	_glow = UiMotion.tween(self)
	_glow.tween_method(func(t: float) -> void:
		_value.add_theme_color_override(&"font_color", tint.lerp(_color, t)), 0.0, 1.0, CHANGE_TIME)
	_glow.tween_callback(func() -> void:
		_glow = null
		_value.add_theme_color_override(&"font_color", _color))
