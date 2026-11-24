class_name ClassicShot
extends ShotLook
## Classic's shots: W's missile as a radiant Sentinel light star with a tapered
## tail, and punchy tapered gold-white light lances with glowing teal tips (R's
## bullets and basic attacks).

const GLOW := Color(UiStyle.GOLD_COLOR, 0.52)
const WHITE := Color(1.0, 0.98, 0.88)
const TEAL := Color(UiStyle.LANTERN_COLOR, 0.72)


func _draw() -> void:
	match kind:
		Kind.MISSILE:
			DashTrail.draw_speed_needle(self, -52.0, 4.0, 0.0, 0.0, 10.0, GLOW)
			DashTrail.draw_speed_needle(self, -36.0, 6.0, 0.0, 0.0, 4.5, WHITE)
			SoftShape.ellipse(self, Vector2.ZERO, Vector2.ONE * 20.0, Color(TEAL, 0.55), 0.25)
			ClassicStar.draw(self, Vector2.ZERO, 20.0, 0.0, GLOW, 0.24)
			ClassicStar.draw(self, Vector2.ZERO, 14.0, PI / 4.0, WHITE, 0.24)
			draw_circle(Vector2.ZERO, 6.5, Color.WHITE)
		Kind.BULLET:
			# Ferocious tapered Sentinel light lance for The Culling.
			DashTrail.draw_speed_needle(self, -62.0, 10.0, 0.0, 0.0, 8.5, GLOW)
			DashTrail.draw_speed_needle(self, -48.0, 11.0, 0.0, 0.0, 4.0, WHITE)
			draw_colored_polygon(PackedVector2Array([Vector2(14, 0), Vector2(1, -5.5), Vector2(-6, 0), Vector2(1, 5.5)]), TEAL)
			draw_colored_polygon(PackedVector2Array([Vector2(11, 0), Vector2(1, -2.6), Vector2(-4, 0), Vector2(1, 2.6)]), Color.WHITE)
		_:
			# Crisp tapered gold-white light bolt for basic attacks.
			DashTrail.draw_speed_needle(self, -38.0, 6.0, 0.0, 0.0, 6.0, GLOW)
			DashTrail.draw_speed_needle(self, -28.0, 7.0, 0.0, 0.0, 2.6, WHITE)
			draw_colored_polygon(PackedVector2Array([Vector2(9, 0), Vector2(0, -3.8), Vector2(-4, 0), Vector2(0, 3.8)]), TEAL)
			draw_circle(Vector2(2, 0), 2.2, Color.WHITE)
