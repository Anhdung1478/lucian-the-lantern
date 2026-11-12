class_name ModifierCard
extends Button
## One card of the modifier pick (ModifierPick): an ornate plate with the
## modifier's icon in a medallion on its top edge (Nothing has a diamond),
## its downside in red over its reward in green. A gift's card (LanternGifts)
## has its name in gold over its effect in green. Hovered, the card lifts and
## its rim turns gold (with low effects only the rim changes). The button
## keeps its place, so the mouse never falls off a lifted card.

const SIZE := Vector2(320, 250)
const MARGIN := 24.0
const RADIUS := 10.0
const MEDALLION := 36.0
const ICON_SIZE := 44.0
const LIGHT := Color(1.0, 0.85, 0.54, 0.22)
## The room the lines keep under the medallion.
const MEDALLION_ROOM := 16.0
const LINE_FONT := 22
const LINE_GAP := 12
## The rule between the two lines.
const RULE_WIDTH := 140.0
## A hovered card: how far it lifts, how fast, and the light around it.
const LIFT := 10.0
const LIFT_TIME := 0.12
const LIT_GLOW := Color(1.0, 0.81, 0.35, 0.3)
const LIT_GLOW_SIZE := 14
## Nothing's medallion holds a diamond this big.
const EMPTY_MARK := 7.0

## What it picks: an EndlessModifiers id, or a LanternGifts id when `gift`.
var id := EndlessModifiers.NOTHING
var gift := false
## The mouse is on it: the rim is gold.
var lit := false

## What the card shows; it moves up when the card lifts.
var _face := Control.new()
var _tween: Tween


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
	lines.offset_top = MEDALLION + MEDALLION_ROOM
	lines.alignment = BoxContainer.ALIGNMENT_CENTER
	lines.add_theme_constant_override(&"separation", LINE_GAP)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.add_child(lines)
	lines.add_child(_line(LanternGifts.display_name(id) if gift else EndlessModifiers.downside(id),
			UiStyle.GOLD_COLOR if gift else ModifierPick.DOWNSIDE_COLOR))
	var rule := Ornament.divider()
	rule.custom_minimum_size.x = RULE_WIDTH
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lines.add_child(rule)
	lines.add_child(_line(LanternGifts.text(id) if gift else EndlessModifiers.reward(id), ModifierPick.REWARD_COLOR))
	mouse_entered.connect(set_lit.bind(true))
	mouse_exited.connect(set_lit.bind(false))


## The mouse came on or went off: the rim's color, and the lift.
func set_lit(on: bool) -> void:
	lit = on
	_face.queue_redraw()
	if GameSettings.instance().low_effects():
		return
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_face, ^"position:y", -LIFT if lit else 0.0, LIFT_TIME).set_ease(Tween.EASE_OUT)


func rim_color() -> Color:
	return UiStyle.GOLD_COLOR if lit else UiStyle.BORDER_COLOR


func _line(text: String, color: Color) -> Label:
	var label := UiStyle.label(text, LINE_FONT, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## The plate, its rim gold in a soft light when lit, and the medallion on
## the middle of its top edge.
func _draw_face() -> void:
	var rect := Rect2(Vector2.ZERO, _face.size)
	Plate.draw_on(_face, rect, RADIUS)
	if lit:
		var rim := StyleBoxFlat.new()
		rim.draw_center = false
		rim.border_color = rim_color()
		rim.set_border_width_all(2)
		rim.set_corner_radius_all(int(RADIUS))
		rim.shadow_color = LIT_GLOW
		rim.shadow_size = LIT_GLOW_SIZE
		_face.draw_style_box(rim, rect)
	var at := Vector2(rect.size.x * 0.5, 0.0)
	var icon := LanternGifts.icon(id) if gift else EndlessModifiers.icon(id)
	Ornament.draw_medallion(_face, at, MEDALLION, icon, ICON_SIZE, LIGHT, rim_color())
	if icon == null:
		_face.draw_colored_polygon(Plate.diamond(at, EMPTY_MARK), UiStyle.BORDER_COLOR)
