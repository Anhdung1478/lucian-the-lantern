class_name MenuCard
extends PanelContainer
## The menus' ornate card: a navy-to-teal gradient, a double gold frame with
## a diamond at each corner, a lantern medallion over its top edge, a spaced
## title and a subtitle between two short gold rules. Its rows go in
## `content`. The ESC menus, the Yes / No pop-up, the skin purchase
## question and the tree's buy question use it. It holds no buttons of its own.

const TOP_COLOR := Color("0b1220")
const BOTTOM_COLOR := Color("0d2328")
const FRAME_COLOR := UiStyle.BORDER_COLOR
const RADIUS := 12.0
## The inner gold line, this far inside the outer one.
const INNER_INSET := 6.0
const SHADOW := Color(0, 0, 0, 0.6)
## Content margins: the sides, the top (under the medallion) and the bottom.
const PAD := Vector3(34.0, 54.0, 30.0)
## The top and bottom margins of a card with no title or subtitle (a question
## and its buttons): 40 px and 28 px on screen.
const BARE_PAD := Vector2(48.0, 34.0)
## The medallion straddling the top edge: its radius and the lantern's size.
const MEDALLION := 30.0
const LANTERN_SIZE := 44.0
const LANTERN := preload("res://assets/art/ui/title_lantern.svg")
const LIGHT := MainBackdrop.GROVE_LIGHT
const TITLE_FONT := 30
const TITLE_SPACING := 6
const SUBTITLE_FONT := 17
## The rules beside the subtitle: their least width.
const RULE_WIDTH := 36.0

var content := VBoxContainer.new()
var title_label: Label
var subtitle_label: Label

var _subtitle_row := HBoxContainer.new()
var _gap := Control.new()
var _style := StyleBoxEmpty.new()


func _init(title := "", subtitle := "") -> void:
	_style.content_margin_left = PAD.x
	_style.content_margin_right = PAD.x
	add_theme_stylebox_override(&"panel", _style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 8)
	add_child(column)
	title_label = UiStyle.label("", TITLE_FONT, UiStyle.TITLE_COLOR)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title_label)
	_subtitle_row.add_theme_constant_override(&"separation", 12)
	column.add_child(_subtitle_row)
	_subtitle_row.add_child(_rule(true))
	subtitle_label = UiStyle.label("", SUBTITLE_FONT, JourneyPanel.CAPTION_COLOR)
	_subtitle_row.add_child(subtitle_label)
	_subtitle_row.add_child(_rule(false))
	_gap.custom_minimum_size.y = 8.0
	column.add_child(_gap)
	content.add_theme_constant_override(&"separation", 12)
	column.add_child(content)
	set_title(title)
	set_subtitle(subtitle)


func _ready() -> void:
	# The title's letters spread out; its font is only known in the tree.
	var spaced := FontVariation.new()
	spaced.base_font = title_label.get_theme_font(&"font")
	spaced.spacing_glyph = TITLE_SPACING
	title_label.add_theme_font_override(&"font", spaced)


## The big line at the top; hidden when "".
func set_title(text: String) -> void:
	title_label.text = text
	title_label.visible = text != ""
	_pad()


## The line under the title, between gold rules; hidden when "".
func set_subtitle(text: String) -> void:
	subtitle_label.text = text
	_subtitle_row.visible = text != ""
	_pad()


## A card with a title keeps room under the medallion; one with none is tighter
## above and below.
func _pad() -> void:
	var bare := not title_label.visible and not _subtitle_row.visible
	_gap.visible = not bare
	_style.content_margin_top = BARE_PAD.x if bare else PAD.y
	_style.content_margin_bottom = BARE_PAD.y if bare else PAD.z


## A convex rounded rectangle's outline, clockwise from its top-right corner,
## `steps` segments per corner.
static func rounded_rect(rect: Rect2, radius: float, steps := 6) -> PackedVector2Array:
	var points := PackedVector2Array()
	var corners := [
		[Vector2(rect.end.x - radius, rect.position.y + radius), -PI * 0.5],
		[Vector2(rect.end.x - radius, rect.end.y - radius), 0.0],
		[Vector2(rect.position.x + radius, rect.end.y - radius), PI * 0.5],
		[Vector2(rect.position.x + radius, rect.position.y + radius), PI],
	]
	for corner: Array in corners:
		for i in steps + 1:
			points.append(corner[0] + Vector2.from_angle(corner[1] + PI * 0.5 * i / steps) * radius)
	return points


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var back := StyleBoxFlat.new()
	back.bg_color = TOP_COLOR
	back.set_corner_radius_all(int(RADIUS))
	back.shadow_color = SHADOW
	back.shadow_size = 26
	back.shadow_offset = Vector2(0, 10)
	draw_style_box(back, rect)
	var inside := rect.grow(-2.0)
	var points := rounded_rect(inside, RADIUS - 2.0)
	var colors := PackedColorArray()
	for point in points:
		colors.append(TOP_COLOR.lerp(BOTTOM_COLOR, inverse_lerp(inside.position.y, inside.end.y, point.y)))
	draw_polygon(points, colors)
	var outer := StyleBoxFlat.new()
	outer.draw_center = false
	outer.border_color = FRAME_COLOR
	outer.set_border_width_all(2)
	outer.set_corner_radius_all(int(RADIUS))
	draw_style_box(outer, rect)
	var inner_rect := rect.grow(-INNER_INSET)
	var inner := StyleBoxFlat.new()
	inner.draw_center = false
	inner.border_color = Color(FRAME_COLOR, 0.45)
	inner.set_border_width_all(1)
	inner.set_corner_radius_all(int(RADIUS - INNER_INSET + 2.0))
	draw_style_box(inner, inner_rect)
	for corner: Vector2 in [inner_rect.position, Vector2(inner_rect.end.x, inner_rect.position.y), inner_rect.end, Vector2(inner_rect.position.x, inner_rect.end.y)]:
		draw_colored_polygon(_diamond(corner, 5.0), UiStyle.GOLD_COLOR)
	_draw_medallion(Vector2(size.x * 0.5, 0.0))


## A gold-ringed disc with the lantern, in a warm glow, over the top edge.
func _draw_medallion(at: Vector2) -> void:
	draw_texture_rect(JourneyMap.glow(), Rect2(at - Vector2.ONE * MEDALLION * 2.6, Vector2.ONE * MEDALLION * 5.2), false, Color(LIGHT, 0.22))
	draw_circle(at, MEDALLION + 3.0, FRAME_COLOR)
	draw_circle(at, MEDALLION, TOP_COLOR)
	draw_arc(at, MEDALLION - 5.0, 0.0, TAU, 40, Color(FRAME_COLOR, 0.5), 1.0, true)
	draw_texture_rect(LANTERN, Rect2(at - Vector2.ONE * LANTERN_SIZE * 0.5, Vector2.ONE * LANTERN_SIZE), false)


## A rule beside the subtitle, fading out away from it, with a diamond at
## its end by the text.
func _rule(left: bool) -> Control:
	var rule := Control.new()
	rule.custom_minimum_size = Vector2(RULE_WIDTH, SUBTITLE_FONT)
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule.draw.connect(func() -> void:
		var y := rule.size.y * 0.5 + 1.0
		var near := rule.size.x if left else 0.0
		var far := 0.0 if left else rule.size.x
		rule.draw_polyline_colors(PackedVector2Array([Vector2(far, y), Vector2(near, y)]), PackedColorArray([Color(FRAME_COLOR, 0.0), FRAME_COLOR]), 1.5, true)
		rule.draw_colored_polygon(_diamond(Vector2(near + (-4.0 if left else 4.0), y), 4.0), FRAME_COLOR))
	return rule


static func _diamond(at: Vector2, radius: float) -> PackedVector2Array:
	return PackedVector2Array([at + Vector2(0, -radius), at + Vector2(radius, 0), at + Vector2(0, radius), at + Vector2(-radius, 0)])
