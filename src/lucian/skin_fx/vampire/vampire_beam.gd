class_name VampireBeam
extends FxBeam
## Vampire's Q: a blood beam, black-red edges around a crimson core. It
## drains away from Lucian's end outward, and drops spray off it and fall.

const EDGE := Color(0.29, 0.03, 0.07, 0.7)
const CORE := Color(0.82, 0.09, 0.19, 0.9)
const CENTER := Color("ff3a50")
const DROP := Color("d01830")
const DROPS := 18
## Drops fall down the screen this fast, px/s².
const FALL := 600.0


func _start() -> void:
	# Down the screen, in the beam's turned frame.
	sparks.gravity = Vector2(0, FALL).rotated(-rotation)
	for i in DROPS:
		var side := 1.0 if randf() < 0.5 else -1.0
		var at := Vector2(randf_range(0.0, length), side * width * 0.4)
		var velocity := Vector2(randf_range(-30.0, 30.0), side * randf_range(60.0, 140.0))
		sparks.emit(at, velocity, randf_range(0.35, 0.55), randf_range(2.0, 3.5), DROP if randf() < 0.6 else CENTER)


func _draw() -> void:
	var p := progress()
	if p < 1.0:
		# The near end drains outward; the last 30% of the time also fades.
		var from := length * p * p
		var a := 1.0 if p < 0.7 else (1.0 - p) / 0.3
		var span := length - from
		draw_rect(Rect2(from, -width * 0.5, span, width), Color(EDGE, EDGE.a * a))
		draw_rect(Rect2(from, -width * 0.25, span, width * 0.5), Color(CORE, CORE.a * a))
		draw_rect(Rect2(from, -width * 0.07, span, width * 0.14), Color(CENTER, a))
	sparks.draw_on(self)
