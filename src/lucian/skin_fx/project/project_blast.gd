class_name ProjectBlast
extends FxBlast
## PROJECT's W: four sculpted cyan plasma lance-blades with an angular
## holographic targeting diamond, segmented cyan/magenta cyber-lock brackets,
## and crisp glitch-data sparks.

const OUTER := Color(0.14, 0.85, 1.0, 0.48)
const INNER := Color(0.42, 0.96, 1.0, 0.9)
const CORE := Color("f0ffff")
const EDGE := Color("7ff4ff")
const MAGENTA := Color(1.0, 0.24, 0.86, 0.82)
const SPARKS_PER_END := 4
const LOCK_TIME := 0.42


func _start() -> void:
	sparks.drag = 2.4
	var reach := bar.x * 0.46
	for direction: Vector2 in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]:
		for i in SPARKS_PER_END:
			sparks.emit(direction * reach * randf_range(0.75, 1.0), direction.rotated(randf_range(-0.55, 0.55)) * randf_range(120.0, 280.0),
				randf_range(0.24, 0.42), randf_range(2.8, 4.6), EDGE if i % 3 != 0 else MAGENTA)


func _lingers() -> bool:
	return not low and age < LOCK_TIME


func details() -> int:
	if low:
		return 0
	return sparks.size() + (4 if age < LOCK_TIME else 0)


func _draw() -> void:
	var a := fade()
	if a > 0.0:
		# Sculpted tapered 4-pointed cyan plasma lance blades.
		CrossBlast.draw_sculpted_cross(
			self,
			bar,
			Color(OUTER, OUTER.a * a),
			Color(INNER, INNER.a * a),
			Color(CORE, a),
		)
		# Crisp angular cyber-edge traces along the 4 lance tips.
		if not low:
			var half_l := bar.x * 0.5
			var half_w := bar.y * 0.25
			for dir: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
				var side := dir.orthogonal()
				var tip := dir * half_l
				var mid := dir * (half_l * 0.36)
				draw_polyline(PackedVector2Array([mid + side * half_w, tip, mid - side * half_w]), Color(EDGE, 0.78 * a), 1.8, true)
				# Subtle magenta glitch offset slice near tip.
				var glitch_p := dir * (half_l * 0.58)
				draw_line(glitch_p + side * 6.0, glitch_p + dir * 28.0 + side * 6.0, Color(MAGENTA, 0.65 * a), 2.0, true)
	if low:
		return
	# Sleek angular holographic targeting diamond & segmented cyber-lock brackets.
	if age < LOCK_TIME:
		var lt := age / LOCK_TIME
		var la := 1.0 - lt
		var snap := 1.0 - pow(1.0 - minf(lt * 2.5, 1.0), 3.0)
		var dia := bar.y * lerpf(0.68, 1.05, snap)
		var diamond := PackedVector2Array([Vector2(dia, 0), Vector2(0, dia), Vector2(-dia, 0), Vector2(0, -dia), Vector2(dia, 0)])
		draw_colored_polygon(diamond.slice(0, 4), Color(OUTER, 0.26 * la))
		draw_polyline(diamond, Color(EDGE, 0.92 * la), 2.4, true)
		var inner_d := dia * 0.55
		var inner_dia := PackedVector2Array([Vector2(inner_d, 0), Vector2(0, inner_d), Vector2(-inner_d, 0), Vector2(0, -inner_d), Vector2(inner_d, 0)])
		draw_polyline(inner_dia, Color(MAGENTA, 0.8 * la), 1.8, true)
		# 4 segmented cyan/magenta cyber-lock brackets framing the center diagonally.
		var br_dist := bar.y * lerpf(1.38, 0.92, snap)
		var br_arm := bar.y * 0.32
		for i in 4:
			var ang := PI * 0.25 + i * PI * 0.5
			var corner := Vector2.from_angle(ang) * br_dist
			var tang_a := Vector2.from_angle(ang + PI * 0.75) * br_arm
			var tang_b := Vector2.from_angle(ang - PI * 0.75) * br_arm
			var col := EDGE if i % 2 == 0 else MAGENTA
			draw_polyline(PackedVector2Array([corner + tang_a, corner, corner + tang_b]), Color(col, 0.92 * la), 2.6, true)
	sparks.draw_on(self, FxSparks.Shape.SQUARE)
