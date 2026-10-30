class_name ProjectShot
extends ShotLook
## PROJECT's shots: a spinning diamond "data packet" trailing pixels (W),
## and thin cyan laser bolts (R and basic attacks).

const GLOW := Color(0.22, 0.91, 1.0, 0.45)
const CYAN := Color("38e8ff")
const PALE := Color("7ff4ff")
const WHITE := Color("f0ffff")
## Pixels trailing the packet: [x, side, alpha].
const TRAIL := [[-22.0, 6.0, 0.6], [-34.0, 5.0, 0.4], [-46.0, 4.0, 0.25]]
## The packet turns this many radians a second.
const SPIN := 14.0


func _process(delta: float) -> void:
	if kind == Kind.MISSILE and not low:
		age += delta
		queue_redraw()


func _draw() -> void:
	match kind:
		Kind.MISSILE:
			for pixel: Array in TRAIL:
				var side: float = pixel[1]
				draw_rect(Rect2(Vector2(pixel[0] - side * 0.5, -side * 0.5), Vector2(side, side)), Color(CYAN, pixel[2]))
			draw_circle(Vector2.ZERO, 16.0, Color(GLOW, 0.3))
			var points := PackedVector2Array()
			for corner: Vector2 in [Vector2(14, 0), Vector2(0, 10), Vector2(-14, 0), Vector2(0, -10)]:
				points.append(corner.rotated(age * SPIN))
			draw_colored_polygon(points, CYAN)
			points.append(points[0])
			draw_polyline(points, WHITE, 2.0)
		Kind.BULLET:
			draw_line(Vector2(-44, 0), Vector2.ZERO, GLOW, 8.0)
			draw_line(Vector2(-36, 0), Vector2(2, 0), WHITE, 2.5)
		_:
			draw_line(Vector2(-28, 0), Vector2.ZERO, GLOW, 7.0)
			draw_line(Vector2(-20, 0), Vector2(2, 0), PALE, 2.5)
