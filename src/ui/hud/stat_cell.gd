class_name StatCell
extends HBoxContainer
## One stat in the stats panel: its icon and value. Hover it for a second to
## read what it does.

const ICON_SIZE := 20.0

var key: StringName

var _value: Label


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
	_value.add_theme_color_override(&"font_color", UiStyle.TEXT_COLOR)
	_value.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_value)


func set_value(text: String) -> void:
	_value.text = text


func tooltip_content() -> Control:
	return TooltipCard.stat(key, _value.text)


func tooltip_place() -> HoverTip.Place:
	return HoverTip.Place.ABOVE
