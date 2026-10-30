class_name PulsefireBlast
extends FxBlast
## Pulsefire's W: a blue cross with a shockwave ring racing out and a clock
## flashing at its centre. The shockwave is a burst at the centre: it ends
## 1.5 widths out, well inside the cross's arms.

const OUTER := Color(0.29, 0.36, 1.0, 0.45)
const INNER := Color(0.5, 0.85, 1.0, 0.8)
const CENTER := Color("f4f8ff")
const WAVE := Color("7fd8ff")
const CLOCK := Color(0.96, 0.97, 1.0, 0.8)
## Seconds the shockwave and the clock show.
const WAVE_TIME := 0.45
const CLOCK_TIME := 0.3
## The shockwave ends this many arm widths from the centre.
const WAVE_REACH := 1.5


func _lingers() -> bool:
	return not low and age < WAVE_TIME


func details() -> int:
	if low:
		return 0
	return (1 if age < WAVE_TIME else 0) + (1 if age < CLOCK_TIME else 0)


## The shockwave's radius `t` (0-1) of the way through WAVE_TIME.
func wave_radius(t: float) -> float:
	return lerpf(bar.y * 0.5, bar.y * WAVE_REACH, 1.0 - pow(1.0 - t, 3.0))


func _draw() -> void:
	var a := fade()
	if a > 0.0:
		for arm in [bar, Vector2(bar.y, bar.x)]:
			draw_rect(Rect2(-arm * 0.5, arm), Color(OUTER, OUTER.a * a))
			draw_rect(Rect2(-arm * 0.25, arm * 0.5), Color(INNER, INNER.a * a))
		draw_circle(Vector2.ZERO, bar.y * 0.45, Color(CENTER, a))
	if low:
		return
	if age < WAVE_TIME:
		var t := age / WAVE_TIME
		draw_arc(Vector2.ZERO, wave_radius(t), 0.0, TAU, 48, Color(WAVE, 0.8 * (1.0 - t)), lerpf(4.0, 1.0, t))
	if age < CLOCK_TIME:
		PulsefireRing.draw_clock(self, Vector2.ZERO, bar.y * 0.7, age * 14.0, Color(CLOCK, CLOCK.a * (1.0 - age / CLOCK_TIME)))
