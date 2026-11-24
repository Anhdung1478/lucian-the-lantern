class_name PulsefireBeam
extends FxBeam
## Pulsefire's Q: a clean electric sapphire-white chrono-beam anchored at x = 0
## with a compact chrono muzzle flare, perspective-tilted energy accelerator
## rings spaced cleanly past x = 50, a sharp lance tip, and trailing chrono sparks.

const OUTER := Color(0.24, 0.36, 1.0, 0.45)
const CORE := Color(0.46, 0.84, 1.0, 0.9)
const CENTER := Color("f4f8ff")
const RING := Color(0.55, 0.9, 1.0, 0.9)
const SPARK := Color("8be6ff")
const RINGS := 4
## Accelerator rings start cleanly past Lucian's guns/head.
const RING_START_X := 54.0
## Rings travel this many px a second.
const RING_SPEED := 2400.0
const SPARKS := 14


func _start() -> void:
	for i in SPARKS:
		var side := 1.0 if randf() < 0.5 else -1.0
		sparks.emit(Vector2(randf_range(40.0, length), side * width * randf_range(0.18, 0.42)),
			Vector2(randf_range(-40.0, 60.0), side * randf_range(24.0, 72.0)),
			randf_range(0.26, 0.44), randf_range(1.6, 3.0), SPARK if i % 2 == 0 else CENTER)


func details() -> int:
	return sparks.size() + (RINGS if not low and age < lifetime else 0)


func _draw() -> void:
	var a := fade()
	if a > 0.0 and length > 1.0:
		# Clean electric sapphire-white sculpted chrono-beam.
		LaserBeam.draw_tapered_beam(self, 0.0, length, width * 0.55, Color(OUTER, OUTER.a * a), minf(length * 0.14, 70.0), 0.58, true)
		LaserBeam.draw_tapered_beam(self, 0.0, length, width * 0.26, Color(CORE, CORE.a * a), minf(length * 0.12, 58.0), 0.66, true)
		LaserBeam.draw_tapered_beam(self, 0.0, length, width * 0.10, Color(CENTER, a), minf(length * 0.09, 44.0), 0.72, false)
		# Compact sharp chrono-muzzle flare right at x = 0 (never covers Lucian's head).
		LaserBeam.draw_muzzle_flare(self, Vector2.ZERO, width * 0.44, Color(CORE, 0.65 * a), Color(CENTER, a))
		if not low and length > RING_START_X + 40.0:
			var span := maxf(length - RING_START_X - 42.0, 1.0)
			for i in RINGS:
				var x := RING_START_X + fmod(age * RING_SPEED + i * span / RINGS, span)
				var share := clampf((x - RING_START_X) / span, 0.0, 1.0)
				var scale_r := lerpf(1.0, 0.78, share)
				var radii := Vector2(width * 0.15 * scale_r, width * 0.56 * scale_r)
				draw_polyline(PulsefireRing.ellipse(Vector2(x, 0), radii * 1.12, 0.0), Color(OUTER, 0.5 * a), 4.0, true)
				draw_polyline(PulsefireRing.ellipse(Vector2(x, 0), radii, 0.0), Color(RING, RING.a * a), 2.4, true)
				draw_polyline(PulsefireRing.ellipse(Vector2(x, 0), radii * 0.92, 0.0), Color(CENTER, 0.65 * a), 1.2, true)
	sparks.draw_on(self)
