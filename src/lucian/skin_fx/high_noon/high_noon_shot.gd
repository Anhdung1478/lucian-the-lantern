class_name HighNoonShot
extends ShotLook
## High Noon's shots: a blazing molten hellfire slug with a billowing smoke
## wake (W), heavy tapered hellfire lance tracers (R), and fiery ember bolts
## (basic attacks).

const GLOW := Color(1.0, 0.34, 0.05, 0.62)
const MOLTEN := Color(1.0, 0.58, 0.2)
const HOT := Color("ffd478")
const WHITE_HOT := Color("fff6e0")
const SMOKE := Color(0.28, 0.22, 0.2)
## The smoke tail behind the slug: [x, radius, alpha].
const TAIL := [[-44.0, 8.0, 0.38], [-60.0, 9.5, 0.28], [-76.0, 11.0, 0.18], [-92.0, 12.0, 0.09]]


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
			for puff: Array in TAIL:
				var flicker := 1.0 + (0.0 if low else 0.15 * sin(age * 40.0 + puff[0]))
				SoftShape.ellipse(self, Vector2(puff[0], 0), Vector2.ONE * ((puff[1] as float) * 1.4 * flicker), Color(SMOKE, puff[2]), 0.3)
			DashTrail.draw_speed_needle(self, -64.0, 6.0, 0.0, 0.0, 13.0, GLOW)
			DashTrail.draw_speed_needle(self, -44.0, 8.0, 0.0, 0.0, 5.5, MOLTEN)
			SoftShape.ellipse(self, Vector2.ZERO, Vector2.ONE * 20.0, Color(GLOW, 0.58), 0.25)
			draw_circle(Vector2.ZERO, 11.5, HOT)
			draw_circle(Vector2.ZERO, 6.0, WHITE_HOT)
		Kind.BULLET:
			# Ferocious tapered hellfire slug tracer for The Culling.
			DashTrail.draw_speed_needle(self, -62.0, 10.0, 0.0, 0.0, 9.5, GLOW)
			DashTrail.draw_speed_needle(self, -46.0, 11.0, 0.0, 0.0, 4.8, MOLTEN)
			draw_colored_polygon(PackedVector2Array([Vector2(14, 0), Vector2(1, -5.2), Vector2(-7, 0), Vector2(1, 5.2)]), HOT)
			draw_colored_polygon(PackedVector2Array([Vector2(10, 0), Vector2(1, -2.5), Vector2(-4, 0), Vector2(1, 2.5)]), WHITE_HOT)
		_:
			# Punchy fiery bolt for basic attacks.
			DashTrail.draw_speed_needle(self, -38.0, 6.0, 0.0, 0.0, 6.5, GLOW)
			DashTrail.draw_speed_needle(self, -26.0, 7.0, 0.0, 0.0, 3.0, MOLTEN)
			draw_colored_polygon(PackedVector2Array([Vector2(9, 0), Vector2(0, -3.5), Vector2(-4, 0), Vector2(0, 3.5)]), HOT)
			draw_circle(Vector2(2, 0), 2.2, WHITE_HOT)
