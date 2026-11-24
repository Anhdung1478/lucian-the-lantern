class_name ProjectShot
extends ShotLook
## PROJECT's shots: a spinning holographic diamond data-packet trailing cyber
## pixels (W), and razor-sharp tapered neon cyan plasma rail-bolts with subtle
## magenta glitch accents (R and basic attacks).

const GLOW := Color(0.18, 0.9, 1.0, 0.55)
const CYAN := Color("38e8ff")
const PALE := Color("7ff4ff")
const MAGENTA := Color(1.0, 0.24, 0.88, 0.72)
const WHITE := Color("f0ffff")
## Pixels trailing the packet: [x, side, alpha].
const TRAIL := [[-24.0, 6.5, 0.65], [-38.0, 5.2, 0.45], [-52.0, 4.0, 0.25]]
## The packet turns this many radians a second.
const SPIN := 14.0


func _ready() -> void:
	super()
	# Only W's missile animates; the rest never need a frame.
	set_process(kind == Kind.MISSILE and not low)


func _process(delta: float) -> void:
	age += delta
	queue_redraw()


func _draw() -> void:
	match kind:
		Kind.MISSILE:
			DashTrail.draw_speed_needle(self, -58.0, 4.0, 0.0, 0.0, 9.0, GLOW)
			for pixel: Array in TRAIL:
				var side: float = pixel[1]
				draw_rect(Rect2(Vector2(pixel[0] - side * 0.5, -side * 0.5), Vector2(side, side)), Color(CYAN, pixel[2]))
			SoftShape.ellipse(self, Vector2.ZERO, Vector2.ONE * 19.0, Color(GLOW, 0.45), 0.25)
			var points := PackedVector2Array()
			for corner: Vector2 in [Vector2(15, 0), Vector2(0, 11), Vector2(-15, 0), Vector2(0, -11)]:
				points.append(corner.rotated(age * SPIN))
			draw_colored_polygon(points, CYAN)
			points.append(points[0])
			draw_polyline(points, WHITE, 2.2, true)
			draw_circle(Vector2.ZERO, 4.0, WHITE)
		Kind.BULLET:
			# Razor-sharp tapered cyan plasma rail-bolt for The Culling.
			DashTrail.draw_speed_needle(self, -62.0, 10.0, 0.0, 0.0, 8.0, GLOW)
			DashTrail.draw_speed_needle(self, -44.0, 9.0, 2.4, 2.4, 2.0, MAGENTA)
			DashTrail.draw_speed_needle(self, -50.0, 12.0, 0.0, 0.0, 3.6, WHITE)
			draw_colored_polygon(PackedVector2Array([Vector2(15, 0), Vector2(2, -4.8), Vector2(-6, 0), Vector2(2, 4.8)]), CYAN)
			draw_colored_polygon(PackedVector2Array([Vector2(11, 0), Vector2(2, -2.2), Vector2(-3, 0), Vector2(2, 2.2)]), WHITE)
		_:
			# Sleek tapered cyan laser-lance for basic attacks.
			DashTrail.draw_speed_needle(self, -38.0, 6.0, 0.0, 0.0, 5.8, GLOW)
			DashTrail.draw_speed_needle(self, -28.0, 7.0, 0.0, 0.0, 2.6, PALE)
			draw_colored_polygon(PackedVector2Array([Vector2(10, 0), Vector2(1, -3.4), Vector2(-4, 0), Vector2(1, 3.4)]), WHITE)
