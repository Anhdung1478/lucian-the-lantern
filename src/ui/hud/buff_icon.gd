class_name BuffIcon
extends Control
## One small buff icon above the HUD panel, like LoL: the icon, a sweep for
## the time that has run out, a number (stacks, charge, shield) in a dark tab
## bottom right and a gold pulsing frame when the buff is ready (e.g. the next
## attack is Energized). Hovering shows what it does. It arrives fading in
## and growing from ARRIVE_SCALE over UiMotion.FAST and leaves fading out over
## UiMotion.EXIT, on its own drawing, so the bar's order never changes.

const SIZE := 36.0
const FRAME := UiStyle.CELL_BORDER
const WELL := UiStyle.CELL_COLOR
const RADIUS := 5
const READY := UiStyle.GOLD_COLOR
const SWEEP := Color(0, 0, 0, 0.55)
const ARRIVE_SCALE := 0.8

## {id, name, icon, text, count, left, duration, ready}; see Lucian.buffs().
var buff := {}:
	set(value):
		buff = value
		queue_redraw()
## It is leaving: it fades out, then hides.
var leaving := false

## How far it has arrived (0 to 1): its alpha and its growth.
var _shown_t := 1.0
var _motion: Tween


func _init() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	mouse_filter = MOUSE_FILTER_PASS


## Shows the icon: fading in and growing (again from where it is, when it
## was leaving).
func arrive() -> void:
	var was_leaving := leaving
	leaving = false
	mouse_filter = MOUSE_FILTER_PASS
	if visible and not was_leaving:
		return
	var from := _shown_t if was_leaving else 0.0
	visible = true
	_ease_to(1.0, from, UiMotion.FAST)


## Hides the icon once it has faded out (at once while UiMotion.off()).
func leave() -> void:
	if leaving or not visible:
		return
	leaving = true
	mouse_filter = MOUSE_FILTER_IGNORE
	_ease_to(0.0, _shown_t, UiMotion.EXIT)


func _ease_to(target: float, from: float, time: float) -> void:
	if _motion and _motion.is_valid():
		_motion.kill()
	_motion = null
	if UiMotion.off() or not is_inside_tree():
		_set_shown(target)
		return
	_set_shown(from)
	_motion = UiMotion.tween(self)
	_motion.tween_method(_set_shown, from, target, time)


func _set_shown(t: float) -> void:
	_shown_t = t
	modulate.a = t
	queue_redraw()
	if t <= 0.0 and leaving:
		visible = false
		leaving = false


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
	var grow := lerpf(ARRIVE_SCALE, 1.0, _shown_t)
	draw_set_transform(rect.get_center() * (1.0 - grow), 0.0, Vector2.ONE * grow)
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
	HudCell.draw_tab(self, rect, buff.count, CORNER_BOTTOM_RIGHT, Color.WHITE)
	draw_set_transform(Vector2.ZERO)


## A rounded cell: a `fill`, or a rim of `width` px in `rim`.
func _box(fill: Color, rim: Color, width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.draw_center = fill.a > 0.0
	box.border_color = rim
	box.set_border_width_all(width)
	box.set_corner_radius_all(RADIUS)
	return box
