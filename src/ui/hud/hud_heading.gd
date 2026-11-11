class_name HudHeading
extends HBoxContainer
## A heading in the Lantern look: small spaced capitals in pale gold between
## two short gold rules that fade out away from it, each with a diamond by
## the text (as the menu card's subtitle has). The stage info's name and the
## boss bar's name are each one. Set the text on `label`: it shows in capitals.

const FONT_SIZE := 14
## Extra room between the letters.
const SPACING := 3
## A rule's least width, and the room between it and the text.
const RULE_WIDTH := 26.0
const GAP := 10
const RULE_COLOR := UiStyle.BORDER_COLOR
const DIAMOND := 3.0

var label := UiStyle.label("", FONT_SIZE, UiStyle.TITLE_COLOR)


func _init() -> void:
	add_theme_constant_override(&"separation", GAP)
	mouse_filter = MOUSE_FILTER_IGNORE
	label.uppercase = true
	label.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_rule(true))
	add_child(label)
	add_child(_rule(false))


func _ready() -> void:
	# The letters spread out; the label's font is only known in the tree.
	var spaced := FontVariation.new()
	spaced.base_font = label.get_theme_font(&"font")
	spaced.spacing_glyph = SPACING
	label.add_theme_font_override(&"font", spaced)


## A rule beside the text, fading out away from it, with a diamond at its
## end by the text.
func _rule(left: bool) -> Control:
	var rule := Control.new()
	rule.custom_minimum_size.x = RULE_WIDTH
	rule.size_flags_horizontal = SIZE_EXPAND_FILL
	rule.mouse_filter = MOUSE_FILTER_IGNORE
	rule.draw.connect(func() -> void:
		var y := roundf(rule.size.y * 0.5) + 0.5
		var near := rule.size.x - DIAMOND if left else DIAMOND
		var far := 0.0 if left else rule.size.x
		rule.draw_polyline_colors(PackedVector2Array([Vector2(far, y), Vector2(near, y)]), PackedColorArray([Color(RULE_COLOR, 0.0), RULE_COLOR]), 1.0, true)
		rule.draw_colored_polygon(Plate.diamond(Vector2(near, y), DIAMOND), RULE_COLOR))
	return rule
