class_name VampireBat
extends RefCounted
## A small bat for Vampire's W cross and E trail, seen from above: its body
## along its heading, its wings out to the sides.

const BODY := Color(0.07, 0.02, 0.04, 0.95)
const RIM := Color("ff3a50")


## Draws a bat on `canvas` at `at`, heading `heading` radians, `span` wide.
## `flap` (-1..1) opens and closes the wings; `alpha` fades it.
static func draw(canvas: CanvasItem, at: Vector2, heading: float, span: float, flap: float, alpha := 1.0) -> void:
	var tip := span * 0.5 * (0.65 + 0.35 * flap)
	var shape: Array[Vector2] = [
		Vector2(0.22 * span, 0.0), Vector2(0.05 * span, -0.07 * span), Vector2(0.0, -tip),
		Vector2(-0.08 * span, -tip * 0.6), Vector2(-0.14 * span, -tip * 0.85), Vector2(-0.18 * span, -0.06 * span),
		Vector2(-0.26 * span, 0.0), Vector2(-0.18 * span, 0.06 * span), Vector2(-0.14 * span, tip * 0.85),
		Vector2(-0.08 * span, tip * 0.6), Vector2(0.0, tip), Vector2(0.05 * span, 0.07 * span),
	]
	var points := PackedVector2Array()
	for point in shape:
		points.append(at + point.rotated(heading))
	canvas.draw_colored_polygon(points, Color(BODY, BODY.a * alpha))
	points.append(points[0])
	canvas.draw_polyline(points, Color(RIM, alpha), 1.5)
