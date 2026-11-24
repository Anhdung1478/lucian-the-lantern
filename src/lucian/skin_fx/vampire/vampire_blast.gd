class_name VampireBlast
extends FxBlast
## Vampire's W: four sculpted ruby-edged tapered cross-blades, a swirling
## dark-crimson blood-sigil ring, crimson mist, and soaring vampire bat
## silhouettes bursting outward.

const OUTER := Color(0.24, 0.02, 0.06, 0.68)
const INNER := Color(0.84, 0.09, 0.2, 0.9)
const CENTER := Color("ff4860")
const HOT := Color("ffd6dc")
const SIGIL := Color(0.55, 0.04, 0.12, 0.78)
const DROP := Color("d01830")
const DROPS := 14
const BATS := 4
const BAT_SPEED := 520.0
const BAT_SPAN := 36.0
## Seconds the bats and blood-sigil linger.
const BAT_TIME := 0.5

var _bats_out := false


func _start() -> void:
	_bats_out = true
	sparks.drag = 3.0
	for i in DROPS:
		var direction := Vector2.RIGHT.rotated(randf() * TAU)
		sparks.emit(Vector2.ZERO, direction * randf_range(190.0, 410.0), randf_range(0.32, 0.48), randf_range(2.6, 4.6), DROP if i % 2 == 0 else CENTER)


func _lingers() -> bool:
	return _bats_out and age < BAT_TIME


func details() -> int:
	return sparks.size() + (BATS if _lingers() else 0)


func _draw() -> void:
	# Swirling dark-crimson blood-sigil ring & crimson mist underneath.
	if _lingers():
		var bt := age / BAT_TIME
		var ba := 1.0 - bt
		var sigil_r := bar.y * lerpf(0.75, 1.32, 1.0 - pow(1.0 - bt, 2.4))
		SoftShape.ellipse(self, Vector2.ZERO, Vector2.ONE * (sigil_r * 1.15), Color(OUTER, 0.42 * ba), 0.25)
		draw_arc(Vector2.ZERO, sigil_r, 0.0, TAU, 52, Color(SIGIL, 0.85 * ba), lerpf(6.0, 1.8, bt), true)
		draw_arc(Vector2.ZERO, sigil_r, 0.0, TAU, 52, Color(CENTER, 0.82 * ba), lerpf(2.4, 0.8, bt), true)
		# Swirling dark-crimson gothic rune arcs rotating around the blood-sigil.
		for i in 4:
			var seg := age * 2.8 + i * TAU * 0.25
			draw_arc(Vector2.ZERO, sigil_r * 0.74, seg, seg + 0.95, 16, Color(INNER, 0.72 * ba), 2.4, true)
			var spike_dir := Vector2.from_angle(seg + 0.48)
			var side := spike_dir.orthogonal()
			draw_colored_polygon(PackedVector2Array([
				spike_dir * (sigil_r * 1.16),
				spike_dir * (sigil_r * 0.88) + side * 5.0,
				spike_dir * (sigil_r * 0.88) - side * 5.0,
			]), Color(CENTER, 0.75 * ba))
	var a := fade()
	if a > 0.0:
		# Sculpted tapered ruby-edged cross-blades.
		CrossBlast.draw_sculpted_cross(
			self,
			bar,
			Color(OUTER, OUTER.a * a),
			Color(INNER, INNER.a * a),
			Color(HOT, 0.92 * a),
		)
		# Sharp ruby highlight bevels along the 4 lance arms.
		var half_l := bar.x * 0.5
		var half_w := bar.y * 0.26
		for dir: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
			var side := dir.orthogonal()
			var tip := dir * half_l
			var shoulder := dir * (half_l * 0.34)
			var base := dir * (bar.y * 0.2)
			draw_polyline(PackedVector2Array([base + side * half_w, shoulder + side * (half_w * 0.7), tip]), Color(CENTER, 0.85 * a), 2.0, true)
			draw_polyline(PackedVector2Array([base - side * half_w, shoulder - side * (half_w * 0.7), tip]), Color(CENTER, 0.85 * a), 2.0, true)
	sparks.draw_on(self)
	if _lingers():
		var bt := age / BAT_TIME
		var ba := 1.0 - bt
		var reach := minf(age * BAT_SPEED, bar.x * 0.5)
		for i in BATS:
			var heading := i * TAU / BATS
			var dir := Vector2.RIGHT.rotated(heading)
			var bat_pos := dir * reach
			# Trailing crimson mist puff behind each soaring bat.
			SoftShape.ellipse(self, bat_pos - dir * 14.0, Vector2.ONE * 14.0, Color(INNER, 0.34 * ba), 0.2)
			VampireBat.draw(self, bat_pos, heading, BAT_SPAN, sin(age * 40.0 + i), ba)
