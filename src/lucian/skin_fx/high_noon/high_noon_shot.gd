class_name HighNoonShot
extends ShotLook
## High Noon's shots: a molten slug with a smoke tail (W), heavy orange
## tracers (R) and an orange tracer (basic attacks).

const GLOW := Color(1.0, 0.35, 0.05, 0.55)
const MOLTEN := Color(1.0, 0.6, 0.23)
const HOT := Color("ffc870")
const WHITE_HOT := Color("fff6e0")
const SMOKE := Color(0.35, 0.3, 0.28)
## The smoke tail behind the slug: [x, radius, alpha].
const TAIL := [[-50.0, 7.0, 0.35], [-65.0, 8.5, 0.25], [-80.0, 10.0, 0.16], [-95.0, 11.0, 0.08]]


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
				draw_circle(Vector2(puff[0], 0), puff[1] * flicker, Color(SMOKE, puff[2]))
			draw_line(Vector2(-56, 0), Vector2.ZERO, GLOW, 22.0)
			draw_line(Vector2(-40, 0), Vector2(4, 0), MOLTEN, 8.0)
			draw_circle(Vector2.ZERO, 17.6, Color(GLOW, 0.5))
			draw_circle(Vector2.ZERO, 11.0, HOT)
			draw_circle(Vector2.ZERO, 5.5, WHITE_HOT)
		Kind.BULLET:
			draw_line(Vector2(-50, 0), Vector2.ZERO, Color(GLOW, 0.5), 14.0)
			draw_line(Vector2(-36, 0), Vector2(3, 0), HOT, 5.0)
			draw_circle(Vector2.ZERO, 3.0, WHITE_HOT)
		_:
			draw_line(Vector2(-30, 0), Vector2.ZERO, Color(GLOW, 0.5), 9.0)
			draw_line(Vector2(-20, 0), Vector2(2, 0), MOLTEN, 3.5)
