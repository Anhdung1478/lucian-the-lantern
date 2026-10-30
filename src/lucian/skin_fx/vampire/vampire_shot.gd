class_name VampireShot
extends ShotLook
## Vampire's shots: a blood orb with a dripping tail (W), crimson bullets
## with a dark drip streak (R), and crimson bolts (basic attacks).

const DARK := Color(0.29, 0.03, 0.07, 0.6)
const BLOOD := Color("d01830")
const BRIGHT := Color("ff3a50")
const GLOW := Color(0.82, 0.09, 0.19, 0.5)
## Drops falling off the orb's tail: [x, y, radius, alpha].
const DRIPS := [[-22.0, 4.0, 4.0, 0.8], [-36.0, 7.0, 3.0, 0.6], [-50.0, 10.0, 2.0, 0.4]]


func _draw() -> void:
	match kind:
		Kind.MISSILE:
			draw_line(Vector2(-48, 0), Vector2.ZERO, DARK, 10.0)
			for drip: Array in DRIPS:
				draw_circle(Vector2(drip[0], drip[1]), drip[2], Color(BLOOD, drip[3]))
			draw_circle(Vector2.ZERO, 18.0, GLOW)
			draw_circle(Vector2.ZERO, 11.0, BLOOD)
			draw_circle(Vector2(2, -3), 4.0, BRIGHT)
		Kind.BULLET:
			draw_line(Vector2(-46, 0), Vector2.ZERO, DARK, 10.0)
			draw_line(Vector2(-34, 0), Vector2(3, 0), BLOOD, 5.0)
			draw_circle(Vector2(-26, 4), 2.0, BLOOD)
			draw_circle(Vector2.ZERO, 2.5, BRIGHT)
		_:
			draw_line(Vector2(-30, 0), Vector2.ZERO, DARK, 8.0)
			draw_line(Vector2(-20, 0), Vector2(2, 0), BRIGHT, 3.0)
