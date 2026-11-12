class_name ClassicShot
extends ShotLook
## Classic's shots: W's missile as a small star of light with a short tail,
## and tracers of gold-white light with a teal glow at the tip (R's bullets
## and basic attacks).

const GLOW := Color(UiStyle.GOLD_COLOR, 0.45)
const WHITE := Color(1.0, 0.97, 0.85)
const TEAL := Color(UiStyle.LANTERN_COLOR, 0.55)


func _draw() -> void:
	match kind:
		Kind.MISSILE:
			draw_line(Vector2(-34, 0), Vector2.ZERO, GLOW, 12.0)
			draw_circle(Vector2.ZERO, 16.0, TEAL)
			ClassicStar.draw(self, Vector2.ZERO, 18.0, 0.0, GLOW, 0.3)
			ClassicStar.draw(self, Vector2.ZERO, 12.0, PI / 4.0, WHITE, 0.3)
			draw_circle(Vector2.ZERO, 6.0, Color.WHITE)
		Kind.BULLET:
			draw_line(Vector2(-44, 0), Vector2.ZERO, GLOW, 10.0)
			draw_line(Vector2(-36, 0), Vector2(2, 0), WHITE, 4.0)
			draw_circle(Vector2(3, 0), 6.0, TEAL)
		_:
			draw_line(Vector2(-30, 0), Vector2.ZERO, GLOW, 8.0)
			draw_line(Vector2(-20, 0), Vector2(2, 0), WHITE, 3.0)
			draw_circle(Vector2(2, 0), 4.0, TEAL)
