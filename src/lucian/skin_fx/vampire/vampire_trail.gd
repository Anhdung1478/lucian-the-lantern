class_name VampireTrail
extends FxTrail
## Vampire's E: Lucian as a swarm. A red mist trail with bats flapping up
## out of it.

const MIST := Color(0.82, 0.09, 0.19, 0.18)
const CLOUD := Color(0.29, 0.03, 0.07, 0.3)
## One bat and one mist cloud every this many px of trail.
const STEP := 50.0
const BAT_SPAN := 28.0
## Seconds each bat flies.
const BAT_LIFE := 0.5

## Each bat: [where, drift (px/s), born at (age)].
var _bats: Array[Array] = []
## Each cloud: [where, radius].
var _clouds: Array[Array] = []


func _grown(from_x: float, to_x: float) -> void:
	var x := ceilf(from_x / STEP) * STEP
	while x <= to_x:
		_clouds.append([Vector2(x, randf_range(-8.0, 8.0)), randf_range(18.0, 26.0)])
		_bats.append([Vector2(x, randf_range(-10.0, 10.0)), Vector2(randf_range(-20.0, 20.0), randf_range(-40.0, 40.0)), age])
		x += STEP


func _draw() -> void:
	draw_rect(Rect2(0, -22, length, 44), MIST)
	for cloud in _clouds:
		draw_circle(cloud[0], cloud[1], CLOUD)
	for bat in _bats:
		var alive: float = age - bat[2]
		if alive < BAT_LIFE:
			var drift: Vector2 = bat[1]
			var at: Vector2 = bat[0] + drift * alive
			VampireBat.draw(self, at, drift.angle(), BAT_SPAN, sin(alive * 40.0), 1.0 - alive / BAT_LIFE)
