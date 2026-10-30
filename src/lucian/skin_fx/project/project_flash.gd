class_name ProjectFlash
extends FxPiece
## PROJECT's muzzle flash: a square of cyan light turned 45°, throwing hex
## sparks forward.

const GLOW := Color(0.22, 0.91, 1.0, 0.4)
const CORE := Color("f0ffff")
const SPARK := Color("7ff4ff")
const SPARKS := 4
## Half the spread of the sparks: 40°.
const SPREAD := 0.7


func _init() -> void:
	lifetime = MuzzleFlash.LIFETIME


func _start() -> void:
	for i in SPARKS:
		var direction := Vector2.RIGHT.rotated(randf_range(-SPREAD, SPREAD))
		sparks.emit(Vector2(4, 0), direction * randf_range(150.0, 300.0), 0.15, 2.5, SPARK)


func _draw() -> void:
	var a := fade()
	if a > 0.0:
		draw_set_transform(Vector2.ZERO, PI / 4.0)
		draw_rect(Rect2(-11, -11, 22, 22), Color(GLOW, GLOW.a * a))
		draw_rect(Rect2(-4, -4, 8, 8), Color(CORE, a))
		draw_set_transform(Vector2.ZERO, 0.0)
	sparks.draw_on(self, FxSparks.Shape.HEX)
