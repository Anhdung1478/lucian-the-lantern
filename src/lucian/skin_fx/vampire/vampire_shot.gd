class_name VampireShot
extends ShotLook
## Vampire's shots: a glowing crimson blood-orb with a tapered obsidian-red
## dripping tail (W), ferocious tapered crimson blood-lances (R), and sharp
## ruby bolts (basic attacks).

const DARK := Color(0.24, 0.02, 0.06, 0.74)
const BLOOD := Color("d01830")
const BRIGHT := Color("ff4860")
const HOT := Color("ffd6dc")
const GLOW := Color(0.84, 0.09, 0.2, 0.58)
## Drops falling off the orb's tail: [x, y, radius, alpha].
const DRIPS := [[-24.0, 4.5, 4.2, 0.85], [-40.0, 7.5, 3.2, 0.65], [-56.0, 10.5, 2.2, 0.4]]


func _draw() -> void:
	match kind:
		Kind.MISSILE:
			DashTrail.draw_speed_needle(self, -60.0, 4.0, 0.0, 0.0, 11.0, DARK)
			DashTrail.draw_speed_needle(self, -44.0, 6.0, 0.0, 0.0, 4.8, BLOOD)
			for drip: Array in DRIPS:
				draw_circle(Vector2(drip[0], drip[1]), drip[2], Color(BLOOD, drip[3]))
			SoftShape.ellipse(self, Vector2.ZERO, Vector2.ONE * 20.0, GLOW, 0.25)
			draw_circle(Vector2.ZERO, 11.5, BLOOD)
			draw_circle(Vector2(2, -2.5), 4.5, BRIGHT)
			draw_circle(Vector2(3, -3.5), 2.0, HOT)
		Kind.BULLET:
			# Ferocious tapered crimson blood-lance for The Culling.
			DashTrail.draw_speed_needle(self, -62.0, 10.0, 0.0, 0.0, 9.5, DARK)
			DashTrail.draw_speed_needle(self, -48.0, 11.0, 0.0, 0.0, 4.8, BLOOD)
			draw_circle(Vector2(-28, 4.5), 2.2, BLOOD)
			draw_colored_polygon(PackedVector2Array([Vector2(14, 0), Vector2(1, -5.2), Vector2(-7, 0), Vector2(1, 5.2)]), BRIGHT)
			draw_colored_polygon(PackedVector2Array([Vector2(10, 0), Vector2(1, -2.4), Vector2(-3, 0), Vector2(1, 2.4)]), HOT)
		_:
			# Sharp tapered crimson bolt for basic attacks.
			DashTrail.draw_speed_needle(self, -38.0, 6.0, 0.0, 0.0, 6.5, DARK)
			DashTrail.draw_speed_needle(self, -26.0, 7.0, 0.0, 0.0, 3.0, BLOOD)
			draw_colored_polygon(PackedVector2Array([Vector2(9, 0), Vector2(0, -3.6), Vector2(-4, 0), Vector2(0, 3.6)]), BRIGHT)
			draw_circle(Vector2(2, 0), 2.0, HOT)
