class_name UnitBar
## How the health bars over the units are drawn: a dark frame round a dark
## well, a fill that is lighter along its top, and a pale ghost of the
## health just lost (see BarGhost). Enemies' bars are red, Lucian's is
## green. Each helper draws on the bar's own canvas, from inside its _draw.

const FRAME := Color(0.02, 0.03, 0.05, 0.92)
const FRAME_WIDTH := 2.0
## The empty part of the bar.
const WELL := Color(0.11, 0.12, 0.16)
## A rim round the frame (an elite's gold) is this wide.
const RIM_WIDTH := 1.5
## A fill's top is this much lighter, and its bottom this much darker.
const LIGHTER := 0.24
const DARKER := 0.2
## The shine along a fill's top: its alpha, and its share of the height.
const SHINE := 0.22
const SHINE_HEIGHT := 0.3


## The frame and the empty well of a bar over `rect`, with a `rim` round the
## frame when it has a color.
static func frame(canvas: CanvasItem, rect: Rect2, rim := Color.TRANSPARENT) -> void:
	if rim.a > 0.0:
		canvas.draw_rect(rect.grow(FRAME_WIDTH + RIM_WIDTH), rim)
	canvas.draw_rect(rect.grow(FRAME_WIDTH), FRAME)
	canvas.draw_rect(rect, WELL)


## `rect` from share `from` to share `to` of its width, in `color`: lighter
## at its top, darker at its bottom, with a faint shine along the top.
static func fill(canvas: CanvasItem, rect: Rect2, from: float, to: float, color: Color) -> void:
	if to <= from:
		return
	var left := rect.position.x + rect.size.x * from
	var right := rect.position.x + rect.size.x * to
	var top := rect.position.y
	var bottom := rect.end.y
	var light := color.lightened(LIGHTER)
	var dark := color.darkened(DARKER)
	canvas.draw_polygon(
		PackedVector2Array([Vector2(left, top), Vector2(right, top), Vector2(right, bottom), Vector2(left, bottom)]),
		PackedColorArray([light, light, dark, dark]))
	canvas.draw_rect(Rect2(left, top, right - left, rect.size.y * SHINE_HEIGHT), Color(1.0, 1.0, 1.0, SHINE * color.a))
