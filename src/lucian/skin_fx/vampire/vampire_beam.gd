class_name VampireBeam
extends FxBeam
## Vampire's Q: a rich dark-crimson and ruby blood-light lance anchored cleanly
## at x = 0 with a crimson muzzle bloom, swirling dark-red tendrils, darting
## mini-bats, a sharp lance tip, and falling blood droplets.

const EDGE := Color(0.24, 0.02, 0.06, 0.78)
const CORE := Color(0.84, 0.09, 0.2, 0.92)
const CENTER := Color("ff5c72")
const HOT := Color("ffd6dc")
const TENDRIL := Color(0.45, 0.03, 0.1, 0.85)
const DROP := Color("d01830")
const DROPS := 18
const BATS := 3
## Drops fall down the screen this fast, px/s².
const FALL := 600.0
const BAT_LIFE := 0.42

## Each mini-bat: [start_x, side_y, speed_x, drift_y, phase].
var _bats: Array[Array] = []


func _start() -> void:
	# Down the screen, in the beam's turned frame.
	sparks.gravity = Vector2(0, FALL).rotated(-rotation)
	for i in DROPS:
		var side := 1.0 if randf() < 0.5 else -1.0
		var at := Vector2(randf_range(12.0, length), side * width * randf_range(0.22, 0.44))
		var velocity := Vector2(randf_range(-30.0, 45.0), side * randf_range(55.0, 140.0))
		sparks.emit(at, velocity, randf_range(0.32, 0.52), randf_range(2.0, 3.6), DROP if randf() < 0.6 else CENTER)
	for i in BATS:
		var share := 0.22 + 0.26 * i + randf_range(-0.05, 0.05)
		var side := 1.0 if i % 2 == 0 else -1.0
		_bats.append([share * length, side * width * 0.25, randf_range(90.0, 180.0), side * randf_range(40.0, 95.0), randf() * TAU])


func _lingers() -> bool:
	return not low and not _bats.is_empty() and age < BAT_LIFE


func details() -> int:
	if low:
		return 0
	return sparks.size() + (_bats.size() if age < BAT_LIFE else 0)


func _draw() -> void:
	var a := fade()
	if a > 0.0 and length > 1.0:
		# Anchored cleanly from x = 0 all the way to a tapered blood-lance tip.
		LaserBeam.draw_tapered_beam(self, 0.0, length, width * 0.60, Color(EDGE, EDGE.a * a), minf(length * 0.14, 72.0), 0.65, true)
		LaserBeam.draw_tapered_beam(self, 0.0, length, width * 0.30, Color(CORE, CORE.a * a), minf(length * 0.12, 60.0), 0.7, true)
		LaserBeam.draw_tapered_beam(self, 0.0, length, width * 0.11, Color(CENTER, a), minf(length * 0.09, 44.0), 0.72, false)
		LaserBeam.draw_tapered_beam(self, 0.0, length * 0.92, width * 0.045, Color(HOT, 0.85 * a), minf(length * 0.08, 36.0), 0.75, false)
		# Swirling dark-red blood tendrils coiling along the beam on High.
		if not low:
			for strand in 2:
				var pts := PackedVector2Array()
				var phase := age * 22.0 + strand * PI
				var steps := 18
				for i in steps + 1:
					var share := float(i) / steps
					var x := share * length * 0.96
					var amp := width * 0.42 * sin(clampf(share * 1.15, 0.0, 1.0) * PI)
					var y := sin(share * 12.0 - phase) * amp
					pts.append(Vector2(x, y))
				draw_polyline(pts, Color(TENDRIL, TENDRIL.a * a), 3.6, true)
				draw_polyline(pts, Color(CENTER, 0.55 * a), 1.4, true)
		# Blazing crimson muzzle bloom right at x = 0 so guns & beam connect seamlessly.
		SoftShape.ellipse(self, Vector2.ZERO, Vector2(width * 0.55, width * 0.48), Color(EDGE, 0.72 * a), 0.25)
		LaserBeam.draw_muzzle_flare(self, Vector2.ZERO, width * 0.52, Color(CORE, 0.82 * a), Color(HOT, 0.95 * a))
	sparks.draw_on(self)
	if not low and age < BAT_LIFE:
		var ba := 1.0 - age / BAT_LIFE
		for bat in _bats:
			var vel := Vector2(bat[2], bat[3])
			var at := Vector2(bat[0], bat[1]) + vel * age
			VampireBat.draw(self, at, vel.angle(), 22.0, sin(age * 42.0 + (bat[4] as float)), ba)
