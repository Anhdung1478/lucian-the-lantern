class_name ProjectBeam
extends FxBeam
## PROJECT's Q: a razor-sharp neon cyan plasma rail-beam anchored at x = 0 with
## angled forward cyber-chevrons (>>>) streaking along the core, subtle magenta
## glitch accents, a sharp lance tip, and digital square sparks.

const OUTER := Color(0.14, 0.85, 1.0, 0.45)
const CORE := Color(0.36, 0.95, 1.0, 0.9)
const CENTER := Color("f0ffff")
const EDGE := Color("7ff4ff")
const MAGENTA := Color(1.0, 0.24, 0.86, 0.72)
const CHEVRONS := 6
## Chevrons streak forward this many px a second.
const CHEVRON_SPEED := 2200.0
const SPARKS := 16


func _start() -> void:
	for i in SPARKS:
		var side := 1.0 if randf() < 0.5 else -1.0
		sparks.emit(Vector2(randf_range(16.0, length), side * width * 0.42), Vector2(randf_range(20.0, 90.0), side * randf_range(25.0, 85.0)),
			randf_range(0.28, 0.44), randf_range(2.8, 4.8), EDGE if i % 4 != 0 else MAGENTA)


func details() -> int:
	return sparks.size() + (CHEVRONS if not low and age < lifetime else 0)


func _draw() -> void:
	var a := fade()
	if a > 0.0 and length > 1.0:
		# Sculpted razor-sharp neon cyan plasma rail-beam.
		LaserBeam.draw_tapered_beam(self, 0.0, length, width * 0.54, Color(OUTER, OUTER.a * a), minf(length * 0.14, 68.0), 0.55, true)
		LaserBeam.draw_tapered_beam(self, 0.0, length, width * 0.24, Color(CORE, CORE.a * a), minf(length * 0.12, 58.0), 0.65, true)
		LaserBeam.draw_tapered_beam(self, 0.0, length, width * 0.09, Color(CENTER, a), minf(length * 0.09, 44.0), 0.72, false)
		# Crisp beveled neon cyan plasma guide rails tapering cleanly to the spear tip.
		var tip_start := maxf(length - 64.0, length * 0.78)
		var rail_y := width * 0.36
		var rail_col := Color(EDGE, 0.82 * a)
		draw_polyline(PackedVector2Array([Vector2(0.0, -rail_y * 0.6), Vector2(18.0, -rail_y), Vector2(tip_start, -rail_y * 0.85), Vector2(length, 0.0)]), rail_col, 2.0, true)
		draw_polyline(PackedVector2Array([Vector2(0.0, rail_y * 0.6), Vector2(18.0, rail_y), Vector2(tip_start, rail_y * 0.85), Vector2(length, 0.0)]), rail_col, 2.0, true)
		if not low:
			# Subtle magenta cyber-glitch accent offsets along the plasma rail.
			for k in 3:
				var gx := fmod(age * 1600.0 + k * length * 0.33, maxf(length - 80.0, 1.0)) + 20.0
				var gy := (1.0 if k % 2 == 0 else -1.0) * width * 0.3
				draw_line(Vector2(gx, gy), Vector2(minf(gx + 54.0, length - 12.0), gy), Color(MAGENTA, 0.68 * a), 2.0, true)
			# Angled forward cyber-chevrons (>>>) streaking along the core.
			var span := maxf(length - 70.0, 1.0)
			var ch_h := width * 0.34
			var ch_dx := 18.0
			for i in CHEVRONS:
				var cx := 26.0 + fmod(age * CHEVRON_SPEED + i * span / CHEVRONS, span)
				var ca := clampf(1.0 - cx / length, 0.25, 1.0) * a
				var pts := PackedVector2Array([
					Vector2(cx - ch_dx, -ch_h),
					Vector2(cx, 0.0),
					Vector2(cx - ch_dx, ch_h),
				])
				draw_polyline(pts, Color(CENTER, 0.88 * ca), 2.4, true)
				draw_polyline(PackedVector2Array([pts[0] - Vector2(7, 0), pts[1] - Vector2(7, 0), pts[2] - Vector2(7, 0)]), Color(MAGENTA, 0.52 * ca), 1.6, true)
		# Angular cyber-muzzle flare anchored right at x = 0.
		var mr := width * 0.45
		draw_colored_polygon(PackedVector2Array([Vector2(mr * 1.15, 0), Vector2(0, -mr * 0.65), Vector2(-mr * 0.45, 0), Vector2(0, mr * 0.65)]), Color(EDGE, 0.72 * a))
		draw_colored_polygon(PackedVector2Array([Vector2(mr * 0.75, 0), Vector2(0, -mr * 0.34), Vector2(-mr * 0.25, 0), Vector2(0, mr * 0.34)]), Color(CENTER, a))
	sparks.draw_on(self, FxSparks.Shape.SQUARE)
