class_name PulsefireRing
extends RefCounted
## Drawing helpers for Pulsefire's time-rift look: tilted rings (ellipses)
## and a clock face with a turning hand.


## An ellipse of `radii` around `center`, turned by `angle`, closed.
static func ellipse(center: Vector2, radii: Vector2, angle: float, segments := 24) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in segments + 1:
		var t := TAU * i / segments
		points.append(center + Vector2(cos(t) * radii.x, sin(t) * radii.y).rotated(angle))
	return points


## A clock face on `canvas`: a ring, 12 ticks and one hand at `hand` radians.
static func draw_clock(canvas: CanvasItem, center: Vector2, radius: float, hand: float, color: Color) -> void:
	canvas.draw_arc(center, radius, 0.0, TAU, 32, color, 2.0)
	for i in 12:
		var direction := Vector2.RIGHT.rotated(TAU * i / 12.0)
		canvas.draw_line(center + direction * radius * 0.78, center + direction * radius, color, 1.5)
	canvas.draw_line(center, center + Vector2.RIGHT.rotated(hand) * radius * 0.7, color, 2.0)
