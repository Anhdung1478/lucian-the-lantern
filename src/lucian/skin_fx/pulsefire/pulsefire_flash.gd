class_name PulsefireFlash
extends FxPiece
## Pulsefire's muzzle flash: a bright sapphire-white chrono core and a crisp
## chrono-ring with micro-ticks that grows and fades.

const DEEP := Color(0.24, 0.36, 1.0, 0.45)
const CORE := Color("f4f8ff")
const RING := Color("7fd8ff")
## Seconds the ring grows and fades.
const RING_TIME := 0.16


func _init() -> void:
	lifetime = MuzzleFlash.LIFETIME


func _lingers() -> bool:
	return not low and age < RING_TIME


func details() -> int:
	return 1 if _lingers() else 0


func _draw() -> void:
	var a := fade()
	if a > 0.0:
		SoftShape.ellipse(self, Vector2.ZERO, Vector2(17.0, 14.0), Color(DEEP, DEEP.a * a), 0.28)
		draw_circle(Vector2.ZERO, 6.5, Color(CORE, a))
	if _lingers():
		var t := age / RING_TIME
		var ra := 1.0 - t
		var r := lerpf(7.0, 20.0, t)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 28, Color(RING, ra), 2.2, true)
		for i in 4:
			var dir := Vector2.from_angle(i * PI * 0.5 + t * 1.4)
			draw_line(dir * (r - 4.0), dir * r, Color(CORE, 0.9 * ra), 1.6, true)
