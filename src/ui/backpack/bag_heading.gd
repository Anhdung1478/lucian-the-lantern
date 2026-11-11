class_name BagHeading
extends HBoxContainer
## A plate's heading on the backpack screen (the backpack, the recipes, the
## merchant): spaced capitals in pale gold between two gold rules, each
## fading away from the text and ending in a diamond beside it, as the menu
## card's subtitle has.

const FONT := 22
## Extra room after every letter.
const SPACING := 5
## The rules: their least width, and the diamond at the end by the text.
const RULE_WIDTH := 28.0
const RULE_DIAMOND := 4.0
const GAP := 12

var label: Label


func _init(text: String, font_size := FONT) -> void:
	add_theme_constant_override(&"separation", GAP)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rule(true))
	label = UiStyle.label(text, font_size, UiStyle.TITLE_COLOR)
	add_child(label)
	add_child(_rule(false))


func _ready() -> void:
	# The letters spread out; the label's font is only known in the tree.
	var spaced := FontVariation.new()
	spaced.base_font = label.get_theme_font(&"font")
	spaced.spacing_glyph = SPACING
	label.add_theme_font_override(&"font", spaced)


## A rule on one side of the text (`left` of it or not).
func _rule(left: bool) -> Control:
	var rule := Control.new()
	rule.custom_minimum_size = Vector2(RULE_WIDTH, FONT)
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule.draw.connect(func() -> void:
		var y := rule.size.y * 0.5 + 1.0
		var near := rule.size.x if left else 0.0
		var far := 0.0 if left else rule.size.x
		rule.draw_polyline_colors(PackedVector2Array([Vector2(far, y), Vector2(near, y)]),
			PackedColorArray([Color(UiStyle.BORDER_COLOR, 0.0), UiStyle.BORDER_COLOR]), 1.5, true)
		rule.draw_colored_polygon(Plate.diamond(Vector2(near + (-RULE_DIAMOND if left else RULE_DIAMOND), y), RULE_DIAMOND), UiStyle.BORDER_COLOR))
	return rule
