class_name BuffIcon
extends Control
## One small buff icon above the HUD panel, like LoL: the icon, a sweep for
## the time that has run out, a number (stacks, charge, shield) and a gold
## pulsing frame when the buff is ready (e.g. the next attack is Energized).
## Hovering shows what it does.

const SIZE := 36.0
const FRAME := UiStyle.CELL_BORDER
const WELL := UiStyle.CELL_COLOR
const RADIUS := 5
const READY := UiStyle.GOLD_COLOR
const SWEEP := Color(0, 0, 0, 0.55)

## {id, name, icon, text, count, left, duration, ready}; see Lucian.buffs().
var buff := {}:
	set(value):
		buff = value
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	mouse_filter = MOUSE_FILTER_PASS


func tooltip_content() -> Control:
	return TooltipCard.buff(buff) if not buff.is_empty() else null


## What the card shows that can change while it is hovered: which buff it
## is (the bar reuses its icons), the count, the seconds left to 0.1 s and
## the text (a shield's amount, a stack count). HoverTip rebuilds the card
## when it changes.
func tooltip_version() -> Variant:
	if buff.is_empty():
		return null
	return [buff.id, buff.count, snappedf(buff.left, 0.1), buff.text]


func tooltip_place() -> HoverTip.Place:
	return HoverTip.Place.ABOVE


func _process(_delta: float) -> void:
	if buff.get("ready", false):
		queue_redraw()


func _draw() -> void:
	if buff.is_empty():
		return
	var rect := Rect2(Vector2.ZERO, Vector2(SIZE, SIZE))
	draw_style_box(_box(WELL, Color.TRANSPARENT, 0), rect)
	if buff.icon:
		draw_texture_rect(buff.icon, rect.grow(-3.0), false)
	var duration: float = buff.duration
	if duration > 0.0:
		var spent := 1.0 - clampf(buff.left / duration, 0.0, 1.0)
		if spent > 0.005:
			draw_colored_polygon(SkillSlot.sweep_polygon(spent, SIZE), SWEEP)
	if buff.ready:
		var pulse := 0.6 + 0.4 * sin(Time.get_ticks_msec() / 150.0)
		draw_style_box(_box(Color.TRANSPARENT, Color(READY, pulse), 3), rect)
	else:
		draw_style_box(_box(Color.TRANSPARENT, FRAME, 1), rect)
	var count: String = buff.count
	if count != "":
		var font := ThemeDB.fallback_font
		var at := Vector2(0, SIZE - 2.0)
		draw_string_outline(font, at, count, HORIZONTAL_ALIGNMENT_RIGHT, SIZE - 2.0, 13, 4, Color.BLACK)
		draw_string(font, at, count, HORIZONTAL_ALIGNMENT_RIGHT, SIZE - 2.0, 13, Color.WHITE)


## A rounded cell: a `fill`, or a rim of `width` px in `rim`.
func _box(fill: Color, rim: Color, width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.draw_center = fill.a > 0.0
	box.border_color = rim
	box.set_border_width_all(width)
	box.set_corner_radius_all(RADIUS)
	return box
