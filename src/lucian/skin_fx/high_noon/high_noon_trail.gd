class_name HighNoonTrail
extends FxTrail
## High Noon's E: a swirling fiery ember-and-smoke velocity ribbon tapering
## smoothly from origin to Lucian, with hot orange sparks and scorched-ash wisps.

const SMOKE_HEAD := Color(0.24, 0.14, 0.1, 0.38)
const FIRE_HEAD := Color(0.95, 0.34, 0.08, 0.44)
const FLAME := Color(1.0, 0.78, 0.4, 0.88)
const EDGE := Color(1.0, 0.38, 0.1, 0.72)
const ASH := Color(0.35, 0.26, 0.22, 0.42)
const EMBER := Color("ffd478")
const EMBER_HOT := Color("ff5518")
const DUST_PUFFS := 7
## One ember every this many px of trail.
const EMBER_STEP := 20.0


func _grown(from_x: float, to_x: float) -> void:
	if from_x == 0.0:
		for i in DUST_PUFFS:
			sparks.emit(Vector2.ZERO, Vector2(randf_range(-70.0, -15.0), randf_range(-55.0, 55.0)),
				randf_range(0.35, 0.5), randf_range(7.0, 12.0), ASH)
	var x := ceilf(from_x / EMBER_STEP) * EMBER_STEP
	while x <= to_x:
		sparks.emit(Vector2(x, randf_range(-14.0, 14.0)), Vector2(randf_range(-28.0, 18.0), randf_range(-48.0, 48.0)),
			randf_range(0.28, 0.48), randf_range(1.8, 3.2), EMBER if randf() < 0.6 else EMBER_HOT)
		if int(x / EMBER_STEP) % 2 == 0:
			sparks.emit(Vector2(x, randf_range(-10.0, 10.0)), Vector2(randf_range(-20.0, 0.0), randf_range(-24.0, 24.0)),
				randf_range(0.32, 0.48), randf_range(6.0, 10.0), ASH)
		x += EMBER_STEP


func _draw() -> void:
	if length <= 1.0:
		sparks.draw_on(self)
		return
	# Swirling scorched-smoke outer wake & molten hellfire tapered ribbon.
	DashTrail.draw_tapered_ribbon(self, length, 30.0, Color(SMOKE_HEAD, 0.0), SMOKE_HEAD, true)
	DashTrail.draw_tapered_ribbon(self, length, 21.0, Color(FIRE_HEAD, 0.0), FIRE_HEAD, true)
	DashTrail.draw_tapered_ribbon(self, length, 9.0, Color(FLAME, 0.0), Color(FLAME, 0.55), true)
	# Tapered fiery speed streaks licking along the wake.
	DashTrail.draw_speed_needle(self, length * 0.06, length, 0.0, 0.0, 3.4, FLAME)
	DashTrail.draw_speed_needle(self, length * 0.12, length * 0.96, -3.0, -13.0, 2.2, EDGE)
	DashTrail.draw_speed_needle(self, length * 0.12, length * 0.96, 3.0, 13.0, 2.2, EDGE)
	# Small flickering flame tongues peeling off the dash ribbon.
	var wisps := mini(int(length / 42.0), 7)
	for i in wisps:
		var share := (float(i) + 1.0) / (wisps + 1)
		var x := share * length
		var sgn := 1.0 if i % 2 == 0 else -1.0
		var h := (12.0 + 14.0 * share) * (0.8 + 0.25 * sin(age * 42.0 + i * 2.0))
		var poly := PackedVector2Array([
			Vector2(x - 14.0, sgn * 4.0),
			Vector2(x - 24.0, sgn * h),
			Vector2(x + 8.0, sgn * 6.0),
		])
		draw_colored_polygon(poly, Color(EDGE, 0.55 * share))
	SoftShape.ellipse(self, Vector2(length, 0), Vector2(20.0, 24.0), Color(FIRE_HEAD, 0.45), 0.25)
	sparks.draw_on(self)
