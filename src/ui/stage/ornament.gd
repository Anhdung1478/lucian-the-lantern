class_name Ornament
extends RefCounted
## The small parts the stage's flow screens share (the end screen, the
## modifier pick, the wave banner, the tips), in the menu card's look: spaced
## capitals, gold rules with a diamond, and a ringed medallion in a soft glow.

const RULE_COLOR := UiStyle.BORDER_COLOR
const RULE_THICKNESS := 1.5
const DIAMOND := 4.0
## A rule's least width, and the height it keeps for its diamond.
const RULE_WIDTH := 36.0
const RULE_HEIGHT := 12.0
## How far a medallion's glow reaches, in its radii.
const GLOW_REACH := 2.6
## A medallion's ring, and the faint line this far inside it.
const RING := 3.0
const RING_INSET := 5.0


## Spreads `label`'s letters `spacing` px apart. Its font is only known in
## the tree: a label outside it is spaced as it enters.
static func space_out(label: Label, spacing: int) -> void:
	if not label.is_inside_tree():
		label.tree_entered.connect(space_out.bind(label, spacing), CONNECT_ONE_SHOT)
		return
	var spaced := FontVariation.new()
	spaced.base_font = label.get_theme_font(&"font")
	spaced.spacing_glyph = spacing
	label.add_theme_font_override(&"font", spaced)


## A rule beside a text, `width` wide or more (`grow` fills the room there
## is): it fades out away from the text and ends by it in a diamond. `left`
## is the side of the text it is on.
static func rule(left: bool, width := RULE_WIDTH, grow := false, color := RULE_COLOR) -> Control:
	var line := _bar(Vector2(width, RULE_HEIGHT))
	if grow:
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.draw.connect(func() -> void:
		var y := line.size.y * 0.5
		var near := line.size.x if left else 0.0
		var far := 0.0 if left else line.size.x
		line.draw_polyline_colors(PackedVector2Array([Vector2(far, y), Vector2(near, y)]), PackedColorArray([Color(color, 0.0), color]), RULE_THICKNESS, true)
		line.draw_colored_polygon(Plate.diamond(Vector2(near + (-DIAMOND if left else DIAMOND), y), DIAMOND), color))
	return line


## `label` between two rules, each `width` wide, in a centered row.
static func between_rules(label: Label, width := RULE_WIDTH, color := RULE_COLOR) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(rule(true, width, false, color))
	row.add_child(label)
	row.add_child(rule(false, width, false, color))
	return row


## A line that fades out at both ends, with a diamond in its middle: across
## the room it gets, or down it when `vertical`.
static func divider(vertical := false, color := RULE_COLOR) -> Control:
	var line := _bar(Vector2(RULE_HEIGHT, RULE_HEIGHT))
	line.draw.connect(func() -> void:
		var from := Vector2(line.size.x * 0.5, 0.0) if vertical else Vector2(0.0, line.size.y * 0.5)
		var to := line.size - from
		var middle := line.size * 0.5
		var clear := Color(color, 0.0)
		line.draw_polyline_colors(PackedVector2Array([from, middle, to]), PackedColorArray([clear, color, clear]), RULE_THICKNESS, true)
		line.draw_colored_polygon(Plate.diamond(middle, DIAMOND), color))
	return line


## A gold-ringed disc at `at` over a soft glow of `light`, with `icon`
## (tinted `tint`; none when null) in its middle: the menu card's medallion
## at any size and in any light.
static func draw_medallion(canvas: CanvasItem, at: Vector2, radius: float, icon: Texture2D, icon_size: float, light: Color, ring := RULE_COLOR, tint := Color.WHITE) -> void:
	var reach := Vector2.ONE * radius * GLOW_REACH
	canvas.draw_texture_rect(JourneyMap.glow(), Rect2(at - reach, reach * 2.0), false, light)
	canvas.draw_circle(at, radius + RING, ring)
	canvas.draw_circle(at, radius, UiStyle.PLATE_TOP)
	canvas.draw_arc(at, radius - RING_INSET, 0.0, TAU, 48, Color(ring, 0.5), 1.0, true)
	if icon:
		canvas.draw_texture_rect(icon, Rect2(at - Vector2.ONE * icon_size * 0.5, Vector2.ONE * icon_size), false, tint)


## A control of at least `least` that takes no mouse input, for a line.
static func _bar(least: Vector2) -> Control:
	var line := Control.new()
	line.custom_minimum_size = least
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line
