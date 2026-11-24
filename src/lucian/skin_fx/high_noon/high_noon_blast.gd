class_name HighNoonBlast
extends FxBlast
## High Noon's W: four sculpted hellfire lance-blades with flickering jagged
## flame tongues, a blazing demonic brass/hellfire brand circle at the center,
## and rising ember sparks.

const OUTER := Color(0.84, 0.2, 0.04, 0.58)
const INNER := Color(1.0, 0.62, 0.22, 0.9)
const CENTER := Color("fff6e0")
const CHAR := Color(0.14, 0.06, 0.04, 0.62)
const BRASS := Color(1.0, 0.74, 0.3, 0.85)
const EMBER := Color("ffd478")
const EMBER_RED := Color("ff4818")
const EMBERS_PER_ARM := 8
## Seconds the demonic brand ring stays.
const CHAR_TIME := 0.6


func _start() -> void:
	sparks.drag = 2.6
	for arm in 4:
		var direction := Vector2.RIGHT.rotated(arm * PI / 2.0)
		for i in EMBERS_PER_ARM:
			var velocity := direction * randf_range(260.0, 500.0) + direction.orthogonal() * randf_range(-46.0, 46.0)
			sparks.emit(Vector2.ZERO, velocity, randf_range(0.36, 0.55), randf_range(2.0, 3.4), EMBER if i % 2 == 0 else EMBER_RED)


func _lingers() -> bool:
	return not low and age < CHAR_TIME


func details() -> int:
	return sparks.size() + (1 if _lingers() else 0)


func _draw() -> void:
	# Blazing demonic brass/hellfire brand circle underneath the cross.
	if _lingers():
		var ct := age / CHAR_TIME
		var ca := 1.0 - ct
		var brand_r := bar.y * 0.95
		SoftShape.ellipse(self, Vector2.ZERO, Vector2.ONE * (brand_r * 1.15), Color(CHAR, 0.45 * ca), 0.35)
		draw_arc(Vector2.ZERO, brand_r, 0.0, TAU, 44, Color(CHAR, CHAR.a * ca), 8.0, true)
		draw_arc(Vector2.ZERO, brand_r, 0.0, TAU, 44, Color(BRASS, 0.82 * ca), 2.4, true)
		draw_arc(Vector2.ZERO, brand_r * 0.72, 0.0, TAU, 36, Color(OUTER, 0.75 * ca), 1.8, true)
		# Demonic rune spokes & diagonal brand star inside the brass circle.
		for i in 8:
			var ang := i * PI / 4.0 + PI / 8.0
			var d := Vector2.from_angle(ang)
			draw_line(d * (brand_r * 0.72), d * brand_r, Color(BRASS, 0.8 * ca), 2.0, true)
		var star_pts := PackedVector2Array()
		for i in 5:
			star_pts.append(Vector2.from_angle(i * TAU * 2.0 / 5.0 - PI * 0.5) * (brand_r * 0.68))
		star_pts.append(star_pts[0])
		draw_polyline(star_pts, Color(EMBER_RED, 0.52 * ca), 1.8, true)
	var a := fade()
	if a > 0.0:
		CrossBlast.draw_sculpted_cross(
			self,
			bar,
			Color(OUTER, OUTER.a * a),
			Color(INNER, INNER.a * a),
			Color(CENTER, a),
		)
		# Fiery flickering jagged flame tongues along the 4 tapered arms.
		if not low:
			var half_l := bar.x * 0.5
			for arm_i in 4:
				var dir := Vector2.RIGHT.rotated(arm_i * PI / 2.0)
				var side := dir.orthogonal()
				for k in 4:
					var dist := half_l * (0.24 + 0.17 * k)
					var sgn := 1.0 if (k + arm_i) % 2 == 0 else -1.0
					var flick := 0.75 + 0.3 * sin(age * 46.0 + arm_i * 1.7 + k * 2.3)
					var reach := bar.y * (0.48 - 0.06 * k) * flick
					var p_base := dir * dist
					var flame := PackedVector2Array([
						p_base - dir * 13.0 + side * (sgn * bar.y * 0.1),
						p_base + dir * (10.0 * flick) + side * (sgn * reach),
						p_base + dir * 15.0 + side * (sgn * bar.y * 0.08),
					])
					draw_colored_polygon(flame, Color(OUTER, 0.78 * a))
					var hot := PackedVector2Array([
						p_base - dir * 6.0 + side * (sgn * bar.y * 0.08),
						p_base + dir * (6.0 * flick) + side * (sgn * reach * 0.68),
						p_base + dir * 8.0 + side * (sgn * bar.y * 0.06),
					])
					draw_colored_polygon(hot, Color(EMBER, 0.85 * a))
	sparks.draw_on(self)
