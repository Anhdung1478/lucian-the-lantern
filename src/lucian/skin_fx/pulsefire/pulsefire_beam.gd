class_name PulsefireBeam
extends FxBeam
## Pulsefire's Q: a white core with blue edges, rings rippling down the beam
## and a clock face at the muzzle.

const OUTER := Color(0.29, 0.36, 1.0, 0.35)
const CORE := Color(0.5, 0.85, 1.0, 0.85)
const CENTER := Color("f4f8ff")
const RING := Color(0.5, 0.85, 1.0, 0.8)
const CLOCK := Color(0.96, 0.97, 1.0, 0.7)
const RINGS := 3
## Rings travel this many px a second.
const RING_SPEED := 3000.0


func details() -> int:
	return sparks.size() + (RINGS + 1 if not low and age < lifetime else 0)


func _draw() -> void:
	var a := fade()
	if a <= 0.0:
		return
	draw_rect(Rect2(0, -width * 0.5, length, width), Color(OUTER, OUTER.a * a))
	draw_rect(Rect2(0, -width * 0.22, length, width * 0.44), Color(CORE, CORE.a * a))
	draw_rect(Rect2(0, -width * 0.08, length, width * 0.16), Color(CENTER, a))
	if low:
		return
	for i in RINGS:
		var x := fmod(age * RING_SPEED + i * length / RINGS, length)
		draw_polyline(PulsefireRing.ellipse(Vector2(x, 0), Vector2(width * 0.18, width * 0.6), 0.0), Color(RING, RING.a * a), 2.5)
	PulsefireRing.draw_clock(self, Vector2.ZERO, width * 0.7, age * 12.0, Color(CLOCK, CLOCK.a * a))
