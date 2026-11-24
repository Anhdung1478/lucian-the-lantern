class_name VampireTrail
extends FxTrail
## Vampire's E: Lucian as a crimson swarm. A swirling crimson-black blood-mist
## tapered ribbon with soft cloak wisps and 3–4 dynamic fluttering bats.

const DARK_HEAD := Color(0.18, 0.02, 0.05, 0.52)
const MIST_HEAD := Color(0.78, 0.08, 0.18, 0.4)
const RUBY := Color("ff3a50")
const WISP := Color(0.32, 0.03, 0.08, 0.38)
const MAX_BATS := 4
## One bat spawned every this many px of trail, capped at MAX_BATS.
const BAT_STEP := 68.0
const BAT_SPAN := 28.0
## Seconds each bat flies.
const BAT_LIFE := 0.5

## Each bat: [where, drift (px/s), born at (age), phase].
var _bats: Array[Array] = []
## Each soft cloak mist wisp: [where, rx, ry].
var _wisps: Array[Array] = []


func _grown(from_x: float, to_x: float) -> void:
	var x := ceilf(from_x / BAT_STEP) * BAT_STEP
	while x <= to_x:
		if _bats.size() < MAX_BATS:
			var side := 1.0 if _bats.size() % 2 == 0 else -1.0
			_bats.append([
				Vector2(x, randf_range(-10.0, 10.0)),
				Vector2(randf_range(-24.0, 22.0), side * randf_range(34.0, 68.0)),
				age,
				randf() * TAU,
			])
			_wisps.append([Vector2(x, randf_range(-8.0, 8.0)), randf_range(24.0, 36.0), randf_range(12.0, 20.0)])
		x += BAT_STEP


func _draw() -> void:
	if length <= 1.0:
		return
	# Swirling crimson-black blood-mist tapered velocity ribbon (0 width/alpha at origin).
	DashTrail.draw_tapered_ribbon(self, length, 30.0, Color(DARK_HEAD, 0.0), DARK_HEAD, true)
	DashTrail.draw_tapered_ribbon(self, length, 18.0, Color(MIST_HEAD, 0.0), MIST_HEAD, true)
	# Soft feathered dark-crimson cloak mist wisps (no flat hard circles).
	for wisp in _wisps:
		var pos: Vector2 = wisp[0]
		var share := clampf(pos.x / maxf(length, 1.0), 0.1, 1.0)
		SoftShape.ellipse(self, pos, Vector2(wisp[1], wisp[2]), Color(WISP, WISP.a * share), 0.2)
	# Swirling crimson cloak ribbons trailing behind Lucian.
	DashTrail.draw_speed_needle(self, length * 0.08, length, 0.0, 0.0, 3.0, Color(RUBY, 0.8))
	for strand in 2:
		var sgn := 1.0 if strand == 0 else -1.0
		var pts := PackedVector2Array()
		var steps := 12
		for i in steps + 1:
			var share := float(i) / steps
			var x := share * length
			var y := sgn * (4.0 + 11.0 * share) + sin(share * 9.0 - age * 20.0 + strand * PI) * 4.5 * share
			pts.append(Vector2(x, y))
		draw_polyline(pts, Color(DARK_HEAD, 0.72), 4.5, true)
		draw_polyline(pts, Color(RUBY, 0.55), 1.6, true)
	SoftShape.ellipse(self, Vector2(length, 0), Vector2(22.0, 26.0), Color(MIST_HEAD, 0.45), 0.25)
	# 3–4 dynamic fluttering bats peeling off the blood-mist wake.
	for bat in _bats:
		var alive: float = age - (bat[2] as float)
		if alive < BAT_LIFE:
			var drift: Vector2 = bat[1]
			var at: Vector2 = (bat[0] as Vector2) + drift * alive
			var ba := 1.0 - alive / BAT_LIFE
			VampireBat.draw(self, at, drift.angle(), BAT_SPAN, sin(alive * 42.0 + (bat[3] as float)), ba)
