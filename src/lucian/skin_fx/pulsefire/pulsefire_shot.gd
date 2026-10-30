class_name PulsefireShot
extends ShotLook
## Pulsefire's shots: an orb with two orbiting rings (W), and pale blue
## pulse bolts with a small ring at the tip (R and basic attacks).

const GLOW := Color(0.5, 0.85, 1.0, 0.45)
const DEEP := Color(0.29, 0.36, 1.0, 0.4)
const WHITE := Color("f4f8ff")
const RING := Color("7fd8ff")


func _process(delta: float) -> void:
	if kind == Kind.MISSILE and not low:
		age += delta
		queue_redraw()


func _draw() -> void:
	match kind:
		Kind.MISSILE:
			draw_line(Vector2(-40, 0), Vector2.ZERO, DEEP, 16.0)
			draw_circle(Vector2.ZERO, 18.0, GLOW)
			draw_circle(Vector2.ZERO, 11.0, WHITE)
			draw_polyline(PulsefireRing.ellipse(Vector2.ZERO, Vector2(17, 6), age * 9.0), RING, 2.0)
			draw_polyline(PulsefireRing.ellipse(Vector2.ZERO, Vector2(17, 6), 1.0 - age * 7.0), RING, 2.0)
		Kind.BULLET:
			draw_line(Vector2(-40, 0), Vector2.ZERO, GLOW, 10.0)
			draw_line(Vector2(-32, 0), Vector2(2, 0), WHITE, 4.0)
			draw_arc(Vector2(2, 0), 5.0, 0.0, TAU, 16, RING, 1.5)
		_:
			draw_line(Vector2(-28, 0), Vector2.ZERO, GLOW, 8.0)
			draw_line(Vector2(-20, 0), Vector2(2, 0), WHITE, 3.0)
			draw_arc(Vector2(2, 0), 3.5, 0.0, TAU, 12, RING, 1.5)
