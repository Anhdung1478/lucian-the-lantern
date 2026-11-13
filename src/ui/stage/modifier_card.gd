class_name ModifierCard
extends Button
## One card of the modifier pick (ModifierPick): an ornate plate with the
## modifier's icon in a medallion on its top edge (Nothing has a diamond),
## its downside in red over its reward in green; Nothing is one dim line,
## "No modifier". A gift's card (LanternGifts) has its name in gold over its
## effect in green. The lines are top-aligned: the first one starts the same
## distance under the medallion on every card, whatever the others hold.
## Hovered, the card lifts, its plate steps to the lighter surface and its rim
## turns gold, all from one eased value (UiMotion.lit); with low effects only
## the rim and the surface change. The button keeps its place, so the mouse
## never falls off a lifted card.

const SIZE := Vector2(320, 216)
const MARGIN := 24.0
const RADIUS := 10.0
const MEDALLION := 36.0
const ICON_SIZE := 44.0
const LIGHT := Color(1.0, 0.85, 0.54, 0.22)
## The first line starts this far under the medallion's ring (20 px on screen).
const LINES_GAP := 24.0
const LINE_FONT := 22
const LINE_GAP := UiStyle.GAP
## The rule between the two lines.
const RULE_WIDTH := 140.0
## A hovered card: how far it lifts and how fast it all eases.
const LIFT := 10.0
const LIFT_TIME := UiMotion.FAST
## How far a card rises into place as the pick opens.
const ARRIVE_RISE := UiMotion.RISE
## Nothing's medallion holds a diamond this big.
const EMPTY_MARK := 7.0

## What it picks: an EndlessModifiers id, or a LanternGifts id when `gift`.
var id := EndlessModifiers.NOTHING
var gift := false
## The mouse is on it: the rim is gold.
var lit := false
## How lit it is, 0 to 1 (UiMotion.lit eases it): the rim, surface and lift.
var lit_t := 0.0

## What the card shows; it moves up when the card lifts.
var _face := Control.new()
## 0 as the card arrives (below its place, unseen), 1 at rest.
var _arrival := 1.0
var _arrive_tween: Tween
## The text box, refitted when the card enters the tree (its theme's font).
var _lines: VBoxContainer


func _init(modifier := EndlessModifiers.NOTHING, is_gift := false) -> void:
	id = modifier
	gift = is_gift
	custom_minimum_size = SIZE
	focus_mode = Control.FOCUS_NONE
	for state: StringName in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	UiStyle.add_click(self)
	_face.set_anchors_preset(Control.PRESET_FULL_RECT)
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.draw.connect(_draw_face)
	add_child(_face)
	var lines := VBoxContainer.new()
	lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, int(MARGIN))
	lines.offset_top = MEDALLION + Ornament.RING + LINES_GAP
	lines.alignment = BoxContainer.ALIGNMENT_BEGIN
	lines.add_theme_constant_override(&"separation", LINE_GAP)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.add_child(lines)
	if is_nothing():
		# One line only: centred in the card under the medallion.
		lines.alignment = BoxContainer.ALIGNMENT_CENTER
		lines.add_child(_line(Lang.t("No modifier"), UiStyle.DIM_COLOR))
	else:
		lines.add_child(_line(LanternGifts.display_name(id) if gift else EndlessModifiers.downside(id),
				UiStyle.GOLD_COLOR if gift else ModifierPick.DOWNSIDE_COLOR))
		var rule := Ornament.divider()
		rule.custom_minimum_size.x = RULE_WIDTH
		rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		lines.add_child(rule)
		lines.add_child(_line(LanternGifts.text(id) if gift else EndlessModifiers.reward(id), ModifierPick.REWARD_COLOR))
	_lines = lines
	mouse_entered.connect(set_lit.bind(true))
	mouse_exited.connect(set_lit.bind(false))


func _ready() -> void:
	fit_lines()


## The room the text has: the card's height under the medallion, less its margin.
func lines_room() -> Vector2:
	return Vector2(SIZE.x - 2.0 * MARGIN, SIZE.y - MARGIN - (MEDALLION + Ornament.RING + LINES_GAP))


## The height the text block takes at `font_size` with `gap` between lines,
## measured with the labels' font (a line wraps at the box's width).
func lines_height(font_size: int, gap: int) -> float:
	var total := 0.0
	var count := 0
	for child in _lines.get_children():
		count += 1
		var label := child as Label
		if label == null:
			total += child.custom_minimum_size.y
			continue
		var font := label.get_theme_font(&"font")
		var wrapped := font.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, lines_room().x, font_size, -1, TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE)
		var rows := maxi(1, roundi(wrapped.y / font.get_height(font_size)))
		total += wrapped.y + rows * float(label.get_theme_constant(&"line_spacing"))
	return total + gap * maxi(count - 1, 0)


## Makes the text fit its box: the gap between lines tightens first, then the
## lines' font steps down (never under FONT_NOTE) until the block fits.
func fit_lines() -> void:
	if _lines == null:
		return
	var room := lines_room().y
	var gap := LINE_GAP
	var size := LINE_FONT
	while lines_height(size, gap) > room:
		if gap > UiStyle.GAP_S:
			gap = UiStyle.GAP_S
		elif size > UiStyle.FONT_NOTE:
			size -= 1
		else:
			break
	_lines.add_theme_constant_override(&"separation", gap)
	for child in _lines.get_children():
		if child is Label:
			child.add_theme_font_size_override(&"font_size", size)


## The card that clears the modifier: one dim line, no rule.
func is_nothing() -> bool:
	return not gift and id == EndlessModifiers.NOTHING


## The mouse came on or went off: the rim's color (at once), and the surface and
## lift, eased from one value.
func set_lit(on: bool) -> void:
	lit = on
	UiMotion.lit(self, on, func(_t: float) -> void: _place_face())


func rim_color() -> Color:
	return UiStyle.GOLD_COLOR if lit else UiStyle.BORDER_COLOR


## The card arrives: it fades in and rises into place over `time`, after
## `delay`. At once when UiMotion.off(). The pick staggers its cards with it.
func arrive(delay := 0.0, time := UiMotion.BASE) -> void:
	if _arrive_tween and _arrive_tween.is_valid():
		_arrive_tween.kill()
	if UiMotion.off() or not is_inside_tree():
		_arrival = 1.0
		_place_face()
		return
	_arrival = 0.0
	_place_face()
	_arrive_tween = UiMotion.tween(self)
	_arrive_tween.tween_method(func(t: float) -> void:
		_arrival = t
		_place_face(), 0.0, 1.0, time).set_delay(delay)


## The face's place and strength: the lift (none with low effects) and the
## rise of its arrival.
func _place_face() -> void:
	var lift := 0.0 if GameSettings.instance().low_effects() else LIFT * lit_t
	_face.position.y = -lift + ARRIVE_RISE * (1.0 - _arrival)
	_face.modulate.a = _arrival
	_face.queue_redraw()


func _line(text: String, color: Color) -> Label:
	var label := UiStyle.label(text, LINE_FONT, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## The plate, its surface stepping to the lighter navy and its rim to gold as
## it lights, and the medallion on the middle of its top edge.
func _draw_face() -> void:
	var rect := Rect2(Vector2.ZERO, _face.size)
	Plate.draw_on(_face, rect, RADIUS)
	if lit_t > 0.0:
		var surface := StyleBoxFlat.new()
		surface.bg_color = Color(UiStyle.SURFACE_RAISED, 0.9 * lit_t)
		surface.set_corner_radius_all(int(RADIUS) - 2)
		_face.draw_style_box(surface, rect.grow(-2.0))
		var inner := rect.grow(-Plate.INNER_INSET)
		for corner: Vector2 in [inner.position, Vector2(inner.end.x, inner.position.y), inner.end, Vector2(inner.position.x, inner.end.y)]:
			_face.draw_colored_polygon(Plate.diamond(corner, Plate.DIAMOND), UiStyle.GOLD_COLOR)
	var rim := StyleBoxFlat.new()
	rim.draw_center = false
	rim.border_color = UiStyle.BORDER_COLOR.lerp(UiStyle.GOLD_COLOR, lit_t)
	rim.set_border_width_all(2)
	rim.set_corner_radius_all(int(RADIUS))
	_face.draw_style_box(rim, rect)
	var at := Vector2(rect.size.x * 0.5, 0.0)
	var icon := LanternGifts.icon(id) if gift else EndlessModifiers.icon(id)
	var ring := UiStyle.BORDER_COLOR.lerp(UiStyle.GOLD_COLOR, lit_t)
	Ornament.draw_medallion(_face, at, MEDALLION, icon, ICON_SIZE, LIGHT, ring)
	if icon == null:
		_face.draw_colored_polygon(Plate.diamond(at, EMPTY_MARK), UiStyle.BORDER_COLOR)
