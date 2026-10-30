class_name HighNoonTrail
extends FxTrail
## High Noon's E: a fire streak along the ground, dust kicked up where the
## dash started, and embers left where Lucian passes.

const FIRE := Color(1.0, 0.42, 0.16, 0.25)
const FLAME := Color(1.0, 0.78, 0.44, 0.7)
const EDGE := Color(1.0, 0.35, 0.1, 0.5)
const DUST := Color(0.55, 0.45, 0.35, 0.4)
const EMBER := Color("ffc870")
const DUST_PUFFS := 6
## One ember every this many px of trail.
const EMBER_STEP := 24.0


func _grown(from_x: float, to_x: float) -> void:
	if from_x == 0.0:
		for i in DUST_PUFFS:
			sparks.emit(Vector2.ZERO, Vector2(randf_range(-60.0, -20.0), randf_range(-50.0, 50.0)), 0.5, randf_range(6.0, 10.0), DUST)
	var x := ceilf(from_x / EMBER_STEP) * EMBER_STEP
	while x <= to_x:
		sparks.emit(Vector2(x, randf_range(-10.0, 10.0)), Vector2(randf_range(-20.0, 20.0), randf_range(-40.0, 40.0)),
			randf_range(0.3, 0.5), 2.0, EMBER)
		x += EMBER_STEP


func _draw() -> void:
	draw_rect(Rect2(0, -14, length, 28), FIRE)
	draw_line(Vector2(0, -10), Vector2(length, -10), EDGE, 2.0)
	draw_line(Vector2(0, 10), Vector2(length, 10), EDGE, 2.0)
	draw_line(Vector2.ZERO, Vector2(length, 0), FLAME, 4.0)
	sparks.draw_on(self)
