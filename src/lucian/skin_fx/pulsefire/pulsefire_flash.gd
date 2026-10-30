class_name PulsefireFlash
extends FxPiece
## Pulsefire's muzzle flash: a white core and a pale blue ring that grows
## and fades.

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
		draw_circle(Vector2.ZERO, 12.0, Color(RING, 0.35 * a))
		draw_circle(Vector2.ZERO, 6.0, Color(CORE, a))
	if _lingers():
		var t := age / RING_TIME
		draw_arc(Vector2.ZERO, lerpf(6.0, 18.0, t), 0.0, TAU, 24, Color(RING, 1.0 - t), 2.0)
