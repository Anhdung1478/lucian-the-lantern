class_name PulsefireBlast
extends FxBlast
## Pulsefire's W: four sculpted sapphire energy lance arms with a precision
## expanding chrono-dial (clockwork tick-notches, sweeping hands, ending 1.5
## widths out) and orbiting time-sparks.

const OUTER := Color(0.24, 0.36, 1.0, 0.52)
const INNER := Color(0.48, 0.86, 1.0, 0.9)
const CENTER := Color("f4f8ff")
const WAVE := Color("7fd8ff")
const CLOCK := Color(0.96, 0.97, 1.0, 0.88)
## Seconds the shockwave and the clock show.
const WAVE_TIME := 0.45
const CLOCK_TIME := 0.35
## The shockwave ends this many arm widths from the centre.
const WAVE_REACH := 1.5
const TIME_SPARKS := 8


func _start() -> void:
	sparks.drag = 2.6
	for i in TIME_SPARKS:
		var ang := TAU * i / TIME_SPARKS
		sparks.emit(Vector2.from_angle(ang) * (bar.y * 0.4), Vector2.from_angle(ang + 0.55) * randf_range(160.0, 300.0),
			randf_range(0.32, 0.46), randf_range(2.0, 3.2), WAVE if i % 2 == 0 else CENTER)


func _lingers() -> bool:
	return not low and age < WAVE_TIME


func details() -> int:
	if low:
		return 0
	return sparks.size() + (1 if age < WAVE_TIME else 0) + (1 if age < CLOCK_TIME else 0)


## The shockwave's radius `t` (0-1) of the way through WAVE_TIME.
func wave_radius(t: float) -> float:
	return lerpf(bar.y * 0.5, bar.y * WAVE_REACH, 1.0 - pow(1.0 - t, 3.0))


func _draw() -> void:
	var a := fade()
	if a > 0.0:
		CrossBlast.draw_sculpted_cross(
			self,
			bar,
			Color(OUTER, OUTER.a * a),
			Color(INNER, INNER.a * a),
			Color(CENTER, a),
		)
	if low:
		return
	if age < WAVE_TIME:
		var t := age / WAVE_TIME
		var wa := 1.0 - t
		var r := wave_radius(t)
		# Precision expanding chrono-dial with clockwork tick-notches.
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 56, Color(OUTER, 0.55 * wa), lerpf(7.0, 1.8, t), true)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 56, Color(WAVE, 0.92 * wa), lerpf(3.2, 1.0, t), true)
		draw_arc(Vector2.ZERO, r * 0.82, 0.0, TAU, 48, Color(CENTER, 0.45 * wa), 1.4, true)
		for i in 12:
			var ang := TAU * i / 12.0 + t * 0.4
			var dir := Vector2.from_angle(ang)
			var tick := 11.0 if i % 3 == 0 else 6.0
			draw_line(dir * (r - tick), dir * r, Color(CENTER, 0.82 * wa), 2.0 if i % 3 == 0 else 1.4, true)
		# Orbiting time-sparks tracing the chrono-dial perimeter.
		for k in 4:
			var orb_ang := age * 8.5 + k * TAU * 0.25
			var pt := Vector2.from_angle(orb_ang) * (r * 0.91)
			draw_circle(pt, 4.2 * wa + 1.2, Color(WAVE, 0.65 * wa))
			draw_circle(pt, 2.2 * wa + 0.8, Color(CENTER, wa))
	if age < CLOCK_TIME:
		var ct := age / CLOCK_TIME
		var ca := 1.0 - ct
		PulsefireRing.draw_clock(self, Vector2.ZERO, bar.y * 0.68, age * 14.0, Color(CLOCK, CLOCK.a * ca))
		# Second counter-rotating chrono hand.
		draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(-age * 6.0) * (bar.y * 0.44), Color(WAVE, 0.85 * ca), 2.2, true)
	sparks.draw_on(self)
