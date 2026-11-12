class_name ClassicBlast
extends FxBlast
## Classic's W: four arms of light, each a gold body with a white core and a
## thin teal edge, a bright flare at the centre and a thin ring that spreads
## out from it. The ring ends 1.5 widths out, well inside the arms.

const EDGE := Color(UiStyle.LANTERN_COLOR, 0.8)
const BODY := Color(UiStyle.GOLD_COLOR, 0.45)
const CORE := Color(1.0, 0.95, 0.75, 0.85)
const CENTER := Color.WHITE
## Thickness of the teal edge along each arm, in px.
const EDGE_WIDTH := 3.0
## Seconds the ring and the centre star show.
const RING_TIME := 0.45
const STAR_TIME := 0.3
## The ring ends this many arm widths from the centre.
const RING_REACH := 1.5


func _lingers() -> bool:
	return not low and age < RING_TIME


func details() -> int:
	if low:
		return 0
	return (1 if age < RING_TIME else 0) + (1 if age < STAR_TIME else 0)


## The ring's radius `t` (0-1) of the way through RING_TIME.
func ring_radius(t: float) -> float:
	return lerpf(bar.y * 0.5, bar.y * RING_REACH, 1.0 - pow(1.0 - t, 3.0))


func _draw() -> void:
	var a := fade()
	if a > 0.0:
		for arm in [bar, Vector2(bar.y, bar.x)]:
			draw_rect(Rect2(-arm * 0.5, arm), Color(BODY, BODY.a * a))
			draw_rect(Rect2(-arm * 0.25, arm * 0.5), Color(CORE, CORE.a * a))
		for edge in [Rect2(-bar.x * 0.5, -bar.y * 0.5, bar.x, EDGE_WIDTH), Rect2(-bar.x * 0.5, bar.y * 0.5 - EDGE_WIDTH, bar.x, EDGE_WIDTH),
				Rect2(-bar.y * 0.5, -bar.x * 0.5, EDGE_WIDTH, bar.x), Rect2(bar.y * 0.5 - EDGE_WIDTH, -bar.x * 0.5, EDGE_WIDTH, bar.x)]:
			draw_rect(edge, Color(EDGE, EDGE.a * a))
		draw_circle(Vector2.ZERO, bar.y * 0.45, Color(CENTER, a))
	if low:
		return
	if age < RING_TIME:
		var t := age / RING_TIME
		draw_arc(Vector2.ZERO, ring_radius(t), 0.0, TAU, 48, Color(EDGE, 0.8 * (1.0 - t)), lerpf(3.0, 1.0, t))
	if age < STAR_TIME:
		var t := age / STAR_TIME
		ClassicStar.draw(self, Vector2.ZERO, bar.y * lerpf(1.2, 1.8, t), PI / 4.0, Color(CENTER, 0.8 * (1.0 - t)))
