class_name HighNoonFlash
extends FxPiece
## High Noon's muzzle flash: a searing four-point hellfire flare throwing
## streaking molten sparks forward.

const GLOW := Color(1.0, 0.34, 0.05, 0.5)
const STAR := Color(1.0, 0.62, 0.22, 0.85)
const CORE := Color("fff6e0")
const SPARK := Color("ffd478")
const SPARKS := 6
## Half the spread of the sparks: 35 degrees.
const SPREAD := 0.61


func _init() -> void:
	lifetime = MuzzleFlash.LIFETIME


func _start() -> void:
	for i in SPARKS:
		var direction := Vector2.RIGHT.rotated(randf_range(-SPREAD, SPREAD))
		sparks.emit(Vector2(4, 0), direction * randf_range(200.0, 390.0), randf_range(0.12, 0.2), 1.8, SPARK)


func _draw() -> void:
	var a := fade()
	if a > 0.0:
		SoftShape.ellipse(self, Vector2.ZERO, Vector2(20.0, 15.0), Color(GLOW, GLOW.a * a), 0.28)
		var points := PackedVector2Array()
		for i in 8:
			var r := 21.0 if i % 2 == 0 else 5.5
			if i == 0:
				r = 26.0
			points.append(Vector2.RIGHT.rotated(i * PI / 4.0) * r)
		draw_colored_polygon(points, Color(STAR, STAR.a * a))
		draw_circle(Vector2.ZERO, 7.0, Color(CORE, a))
	sparks.draw_on(self, FxSparks.Shape.STREAK)
