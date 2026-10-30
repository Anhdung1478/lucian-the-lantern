class_name VampireFlash
extends FxPiece
## Vampire's muzzle flash: a red burst throwing blood drops forward.

const GLOW := Color(0.82, 0.09, 0.19, 0.5)
const CORE := Color("ff3a50")
const DROP := Color("d01830")
const DROPS := 4
## Half the spread of the drops: 40°.
const SPREAD := 0.7


func _init() -> void:
	lifetime = MuzzleFlash.LIFETIME


func _start() -> void:
	for i in DROPS:
		var direction := Vector2.RIGHT.rotated(randf_range(-SPREAD, SPREAD))
		sparks.emit(Vector2(4, 0), direction * randf_range(120.0, 220.0), 0.18, 2.0, DROP)


func _draw() -> void:
	var a := fade()
	if a > 0.0:
		draw_circle(Vector2.ZERO, 14.0, Color(GLOW, GLOW.a * a))
		draw_circle(Vector2.ZERO, 7.0, Color(CORE, a))
	sparks.draw_on(self)
