class_name FreeBadge
extends Label
## A small "FREE" pill with a green-gold fill. It marks an Evolution Tree
## upgrade that costs nothing and is ready to take. It holds still (a mark
## that loops forever on a control is noise) and ignores the mouse.

const SIZE := Vector2(48, 20)
const FONT := 13
const FILL_COLOR := Color("5f8f2e")
const BORDER_COLOR := Color("ffe08a")
const TEXT_COLOR := Color("fff7d6")


func _init() -> void:
	text = Lang.t("FREE")
	size = SIZE
	custom_minimum_size = SIZE
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_font_size_override(&"font_size", FONT)
	add_theme_color_override(&"font_color", TEXT_COLOR)
	add_theme_stylebox_override(&"normal", UiStyle.panel(FILL_COLOR, BORDER_COLOR, 1, 0.0, 10))
