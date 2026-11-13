class_name HudBar
extends Control
## A health or mana bar in the Lantern look: a dark well with a thin rim, a
## fill with a soft top-to-bottom gradient, a white shield segment after it,
## tick marks every TICK, and a pale "ghost" chunk that shows what was just
## lost and drains away in GHOST_TIME. Lucian's health and mana bars and the
## boss bar are each one. Their texts are labels added on top.

const WELL := Color(0.02, 0.025, 0.04, 0.88)
const RIM := Color(UiStyle.BORDER_COLOR, 0.55)
const RADIUS := 3
const SHIELD := Color(0.92, 0.94, 0.97, 0.85)
## A light line along the fill's top edge.
const SHINE := Color(1, 1, 1, 0.16)
## Health: the fill's top and bottom, and the ghost.
const HEALTH_TOP := Color("63d26b")
const HEALTH_BOTTOM := Color("2a8a3a")
const HEALTH_GHOST := Color("ffc4b0")
## Seconds a ghost chunk takes to drain away.
const GHOST_TIME := 0.4
## A tick mark every TICK of the amount, a stronger one every STRONG_EVERY
## marks. Marks closer than MIN_TICK_GAP are left out (see tick_step).
const TICK := 100.0
const STRONG_EVERY := 10
const MIN_TICK_GAP := 5.0
const TICK_COLOR := Color(0, 0, 0, 0.5)
const STRONG_TICK_COLOR := Color(0, 0, 0, 0.8)
## How far down the bar a tick mark reaches; a strong one crosses it.
const TICK_REACH := 0.45

var fill_top := HEALTH_TOP
var fill_bottom := HEALTH_BOTTOM
var ghost_color := HEALTH_GHOST
## The mana bar has no tick marks.
var ticks := true
var amount := 0.0
var max_amount := 1.0
var shield := 0.0
## How far the bar runs past its own right edge (the HUD lets the bars run
## under a lone item row). The labels inside follow.
var extend := 0.0:
	set(v):
		if is_equal_approx(v, extend):
			return
		for child in get_children():
			if child is Label:
				(child as Label).offset_right += v - extend
		extend = v
		queue_redraw()

## The amount the ghost chunk reaches up to, and how fast it drains per second.
var _ghost := 0.0
var _ghost_rate := 0.0


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


## Shows `new_amount` of `new_max`, with `shield_amount` after it. A loss
## leaves a ghost chunk behind.
func show_amount(new_amount: float, new_max: float, shield_amount := 0.0) -> void:
	if new_amount == amount and new_max == max_amount and shield_amount == shield:
		return
	if new_amount < amount:
		_ghost = maxf(_ghost, amount)
		_ghost_rate = (_ghost - new_amount) / GHOST_TIME
	amount = new_amount
	max_amount = new_max
	shield = shield_amount
	queue_redraw()


## Shows `new_amount` at once, with no ghost: a bar that changes its owner.
func reset(new_amount: float, new_max: float) -> void:
	amount = new_amount
	max_amount = new_max
	shield = 0.0
	_ghost = 0.0
	queue_redraw()


## The amount the ghost chunk still reaches up to (the amount itself when
## there is none).
func ghost_amount() -> float:
	return maxf(_ghost, amount)


func _process(delta: float) -> void:
	if _ghost <= amount:
		return
	_ghost = drained(_ghost, amount, _ghost_rate, delta)
	queue_redraw()


## A ghost at `ghost` after `delta` seconds of draining at `rate` per second
## toward `amount`.
static func drained(ghost: float, amount: float, rate: float, delta: float) -> float:
	return maxf(amount, ghost - rate * delta)


## The amount between two tick marks on a bar `width` wide: TICK, or ten
## times that (again and again) while the marks would sit closer than
## MIN_TICK_GAP.
static func tick_step(max_amount: float, width: float) -> float:
	var step := TICK
	while max_amount > 0.0 and width * step / max_amount < MIN_TICK_GAP:
		step *= 10.0
	return step


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size + Vector2(extend, 0.0))
	var well := StyleBoxFlat.new()
	well.bg_color = WELL
	well.set_corner_radius_all(RADIUS)
	draw_style_box(well, rect)
	var inner := rect.grow(-1.0)
	var share := _share(amount)
	var ghost_share := _share(_ghost)
	if ghost_share > share:
		draw_rect(_part(inner, share, ghost_share), ghost_color)
	if share > 0.0:
		var fill := _part(inner, 0.0, share)
		var corners := PackedVector2Array([fill.position, Vector2(fill.end.x, fill.position.y), fill.end, Vector2(fill.position.x, fill.end.y)])
		draw_polygon(corners, PackedColorArray([fill_top, fill_top, fill_bottom, fill_bottom]))
		draw_rect(Rect2(fill.position, Vector2(fill.size.x, 1.0)), SHINE)
	if shield > 0.0:
		# Right after the amount, pushed back from the end when both are more
		# than the bar holds.
		var shield_share := minf(_share(shield), 1.0)
		var start := minf(share, 1.0 - shield_share)
		draw_rect(_part(inner, start, start + shield_share), SHIELD)
	if ticks:
		_draw_ticks(inner)
	var rim := StyleBoxFlat.new()
	rim.draw_center = false
	rim.border_color = RIM
	rim.set_border_width_all(1)
	rim.set_corner_radius_all(RADIUS)
	draw_style_box(rim, rect)


func _draw_ticks(inner: Rect2) -> void:
	var step := tick_step(max_amount, inner.size.x)
	var count := int(max_amount / step)
	for i in range(1, count + 1):
		var x := roundf(inner.position.x + inner.size.x * i * step / max_amount)
		if x >= inner.end.x - 1.0:
			break
		if i % STRONG_EVERY == 0:
			draw_rect(Rect2(x - 1.0, inner.position.y, 2.0, inner.size.y), STRONG_TICK_COLOR)
		else:
			draw_rect(Rect2(x, inner.position.y, 1.0, roundf(inner.size.y * TICK_REACH)), TICK_COLOR)


## `value` as a share of the bar, 0 to 1.
func _share(value: float) -> float:
	return clampf(value / max_amount, 0.0, 1.0) if max_amount > 0.0 else 0.0


## The part of `inner` between two shares of its width.
func _part(inner: Rect2, from: float, to: float) -> Rect2:
	return Rect2(inner.position.x + inner.size.x * from, inner.position.y, inner.size.x * (to - from), inner.size.y)
