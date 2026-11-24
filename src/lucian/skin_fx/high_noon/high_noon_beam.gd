class_name HighNoonBeam
extends FxBeam
## High Noon's Q: a searing molten orange-gold hellfire lance with a dark smoke
## outer edge, blazing demonic muzzle flare at x = 0, flickering flame tongues
## along its length, and glowing embers.

const SMOKE_EDGE := Color(0.22, 0.07, 0.04, 0.55)
const EDGE := Color(0.86, 0.22, 0.04, 0.65)
const CORE := Color(1.0, 0.52, 0.16, 0.92)
const CENTER := Color("fff6e0")
const EMBER_HOT := Color("ffd478")
const EMBER_COOL := Color("ff5a1a")
const SMOKE := Color(0.28, 0.22, 0.2, 0.36)
const EMBERS := 26
const PUFFS := 4
const TONGUES := 12


func _start() -> void:
	sparks.drag = 3.0
	for i in EMBERS:
		var side := 1.0 if randf() < 0.5 else -1.0
		var at := Vector2(randf_range(12.0, length), side * width * randf_range(0.22, 0.45))
		var velocity := Vector2(randf_range(-40.0, 50.0), side * randf_range(45.0, 130.0))
		sparks.emit(at, velocity, randf_range(0.32, 0.52), randf_range(2.0, 3.6), EMBER_HOT.lerp(EMBER_COOL, randf()))
	for i in PUFFS:
		var at := Vector2(randf_range(0.0, 22.0), randf_range(-10.0, 10.0))
		sparks.emit(at, Vector2(randf_range(-12.0, 32.0), randf_range(-24.0, 24.0)), 0.48, randf_range(9.0, 14.0), SMOKE)


func _draw() -> void:
	var a := fade()
	if a > 0.0 and length > 1.0:
		# Dark smoke outer edge wrapping the searing molten hellfire lance.
		LaserBeam.draw_tapered_beam(self, 0.0, length, width * 0.64, Color(SMOKE_EDGE, SMOKE_EDGE.a * a), minf(length * 0.14, 72.0), 0.65, true)
		LaserBeam.draw_tapered_beam(self, 0.0, length, width * 0.50, Color(EDGE, EDGE.a * a), minf(length * 0.13, 66.0), 0.6, true)
		LaserBeam.draw_tapered_beam(self, 0.0, length, width * 0.27, Color(CORE, CORE.a * a), minf(length * 0.11, 56.0), 0.65, true)
		LaserBeam.draw_tapered_beam(self, 0.0, length, width * 0.11, Color(CENTER, a), minf(length * 0.09, 44.0), 0.7, false)
		# Flickering jagged flame tongues licking along both sides of the lance.
		if not low:
			for i in TONGUES:
				var share := (float(i) + 0.5) / TONGUES
				var x := share * length * 0.9
				var side := 1.0 if i % 2 == 0 else -1.0
				var flick := 0.72 + 0.35 * sin(age * 48.0 + i * 2.1)
				var base_y := side * width * 0.22
				var tip_y := side * width * (0.58 + 0.24 * flick)
				var flame := PackedVector2Array([
					Vector2(x - 16.0, base_y),
					Vector2(x + 12.0 * flick, tip_y),
					Vector2(x + 22.0, base_y),
				])
				draw_colored_polygon(flame, Color(EDGE, 0.72 * a))
				var inner_flame := PackedVector2Array([
					Vector2(x - 8.0, base_y),
					Vector2(x + 7.0 * flick, tip_y * 0.76),
					Vector2(x + 12.0, base_y),
				])
				draw_colored_polygon(inner_flame, Color(EMBER_HOT, 0.82 * a))
		LaserBeam.draw_muzzle_flare(self, Vector2.ZERO, width * 0.58, Color(EDGE, 0.75 * a), Color(CENTER, a))
	sparks.draw_on(self)
