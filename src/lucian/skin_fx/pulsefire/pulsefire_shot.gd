class_name PulsefireShot
extends ShotLook
## Pulsefire's shots: a chrono-orb with dual orbiting rings (W), and punchy
## tapered electric sapphire-white chrono-lances with accelerator halos (R and
## basic attacks).

const GLOW := Color(0.46, 0.84, 1.0, 0.55)
const DEEP := Color(0.24, 0.36, 1.0, 0.52)
const WHITE := Color("f4f8ff")
const RING := Color("7fd8ff")


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
			DashTrail.draw_speed_needle(self, -58.0, 4.0, 0.0, 0.0, 12.0, DEEP)
			DashTrail.draw_speed_needle(self, -40.0, 6.0, 0.0, 0.0, 4.8, WHITE)
			SoftShape.ellipse(self, Vector2.ZERO, Vector2.ONE * 20.0, Color(GLOW, 0.6), 0.25)
			draw_circle(Vector2.ZERO, 11.0, WHITE)
			draw_polyline(PulsefireRing.ellipse(Vector2.ZERO, Vector2(18, 6.5), age * 9.0), RING, 2.2, true)
			draw_polyline(PulsefireRing.ellipse(Vector2.ZERO, Vector2(18, 6.5), 1.0 - age * 7.0), RING, 2.2, true)
		Kind.BULLET:
			# Ferocious tapered sapphire chrono-lance for The Culling.
			DashTrail.draw_speed_needle(self, -60.0, 10.0, 0.0, 0.0, 8.8, DEEP)
			DashTrail.draw_speed_needle(self, -46.0, 11.0, 0.0, 0.0, 4.2, WHITE)
			draw_colored_polygon(PackedVector2Array([Vector2(14, 0), Vector2(1, -5.0), Vector2(-6, 0), Vector2(1, 5.0)]), RING)
			draw_colored_polygon(PackedVector2Array([Vector2(11, 0), Vector2(1, -2.4), Vector2(-3, 0), Vector2(1, 2.4)]), WHITE)
			draw_polyline(PulsefireRing.ellipse(Vector2(-8, 0), Vector2(2.6, 7.5), 0.0, 16), RING, 1.6, true)
		_:
			# Sleek tapered sapphire chrono-bolt for basic attacks.
			DashTrail.draw_speed_needle(self, -38.0, 6.0, 0.0, 0.0, 6.0, GLOW)
			DashTrail.draw_speed_needle(self, -26.0, 7.0, 0.0, 0.0, 2.8, WHITE)
			draw_colored_polygon(PackedVector2Array([Vector2(9, 0), Vector2(0, -3.5), Vector2(-4, 0), Vector2(0, 3.5)]), RING)
			draw_circle(Vector2(2, 0), 2.2, WHITE)
