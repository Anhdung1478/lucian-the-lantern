class_name ProjectFlash
extends FxPiece
## PROJECT's muzzle flash: a sharp holographic cyan/magenta diamond flare
## throwing hex sparks forward.

const GLOW := Color(0.18, 0.9, 1.0, 0.48)
const EDGE := Color("7ff4ff")
const MAGENTA := Color(1.0, 0.24, 0.88, 0.72)
const CORE := Color("f0ffff")
const SPARK := Color("7ff4ff")
const SPARKS := 5
## Half the spread of the sparks: 40°.
const SPREAD := 0.7


func _init() -> void:
	lifetime = MuzzleFlash.LIFETIME


func _start() -> void:
	for i in SPARKS:
		var direction := Vector2.RIGHT.rotated(randf_range(-SPREAD, SPREAD))
		sparks.emit(Vector2(4, 0), direction * randf_range(160.0, 320.0), 0.16, 2.6, SPARK if i % 3 != 0 else MAGENTA)


func _draw() -> void:
	var a := fade()
	if a > 0.0:
		SoftShape.ellipse(self, Vector2.ZERO, Vector2(18.0, 14.0), Color(GLOW, GLOW.a * a), 0.28)
		var dia := PackedVector2Array([Vector2(20, 0), Vector2(0, -11), Vector2(-9, 0), Vector2(0, 11)])
		draw_colored_polygon(dia, Color(GLOW, 0.72 * a))
		dia.append(dia[0])
		draw_polyline(dia, Color(EDGE, 0.92 * a), 1.8, true)
		draw_colored_polygon(PackedVector2Array([Vector2(11, 0), Vector2(0, -5), Vector2(-5, 0), Vector2(0, 5)]), Color(CORE, a))
	sparks.draw_on(self, FxSparks.Shape.HEX)
