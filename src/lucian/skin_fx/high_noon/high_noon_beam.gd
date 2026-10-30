class_name HighNoonBeam
extends FxBeam
## High Noon's Q: a hellfire beam, red edges around an orange core and a
## white-hot centre. Embers drift off its sides and a smoke puff hangs at the
## muzzle.

const EDGE := Color(0.78, 0.19, 0.04, 0.5)
const CORE := Color(1.0, 0.42, 0.16, 0.85)
const CENTER := Color("fff6e0")
const EMBER_HOT := Color("ffc870")
const EMBER_COOL := Color("ff5a1a")
const SMOKE := Color(0.35, 0.3, 0.28, 0.35)
const EMBERS := 24
const PUFFS := 3


func _start() -> void:
	for i in EMBERS:
		var side := 1.0 if randf() < 0.5 else -1.0
		var at := Vector2(randf_range(0.0, length), side * width * randf_range(0.25, 0.45))
		var velocity := Vector2(randf_range(-40.0, 40.0), side * randf_range(40.0, 120.0))
		sparks.emit(at, velocity, randf_range(0.35, 0.55), randf_range(2.0, 3.5), EMBER_HOT.lerp(EMBER_COOL, randf()))
	for i in PUFFS:
		var at := Vector2(randf_range(0.0, 16.0), randf_range(-8.0, 8.0))
		sparks.emit(at, Vector2(randf_range(-10.0, 30.0), randf_range(-20.0, 20.0)), 0.5, randf_range(10.0, 14.0), SMOKE)


func _draw() -> void:
	var a := fade()
	if a > 0.0:
		draw_rect(Rect2(0, -width * 0.5, length, width), Color(EDGE, EDGE.a * a))
		draw_rect(Rect2(0, -width * 0.25, length, width * 0.5), Color(CORE, CORE.a * a))
		draw_rect(Rect2(0, -width * 0.08, length, width * 0.16), Color(CENTER, a))
	sparks.draw_on(self)
