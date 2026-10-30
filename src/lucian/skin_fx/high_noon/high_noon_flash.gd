class_name HighNoonFlash
extends FxPiece
## High Noon's muzzle flash: a four-point star of fire, throwing sparks
## forward.

const STAR := Color(1.0, 0.6, 0.23, 0.7)
const CORE := Color("fff6e0")
const SPARK := Color("ffc870")
const SPARKS := 5
## Half the spread of the sparks: 35 degrees.
const SPREAD := 0.61


func _init() -> void:
	lifetime = MuzzleFlash.LIFETIME


func _start() -> void:
	for i in SPARKS:
		var direction := Vector2.RIGHT.rotated(randf_range(-SPREAD, SPREAD))
		sparks.emit(Vector2(4, 0), direction * randf_range(200.0, 380.0), randf_range(0.12, 0.2), 1.5, SPARK)


func _draw() -> void:
	var a := fade()
	if a > 0.0:
		var points := PackedVector2Array()
		for i in 8:
			points.append(Vector2.RIGHT.rotated(i * PI / 4.0) * (18.0 if i % 2 == 0 else 5.0))
		draw_colored_polygon(points, Color(STAR, STAR.a * a))
		draw_circle(Vector2.ZERO, 7.0, Color(CORE, a))
	sparks.draw_on(self, FxSparks.Shape.STREAK)
