class_name ClassicBlast
extends FxBlast
## Classic's W: four sculpted tapered Sentinel light lance-blades with teal
## edge accents, a radiant 8-point Sentinel light star centerpiece, and an
## expanding teal-rimmed golden sanctum ring (ending 1.5 widths out).

const EDGE := Color(UiStyle.LANTERN_COLOR, 0.88)
const BODY := Color(UiStyle.GOLD_COLOR, 0.52)
const CORE := Color(1.0, 0.96, 0.78, 0.92)
const CENTER := Color.WHITE
const SPARK_COLOR := Color(1.0, 0.92, 0.62, 0.85)
## Seconds the ring and the centre star show.
const RING_TIME := 0.45
const STAR_TIME := 0.34
## The ring ends this many arm widths from the centre.
const RING_REACH := 1.5


func _start() -> void:
	sparks.drag = 2.8
	for i in 12:
		var ang := TAU * i / 12.0 + randf_range(-0.18, 0.18)
		sparks.emit(Vector2.ZERO, Vector2.from_angle(ang) * randf_range(160.0, 340.0),
			randf_range(0.3, 0.48), randf_range(1.8, 3.2), SPARK_COLOR if i % 2 == 0 else EDGE)


func _lingers() -> bool:
	return not low and age < RING_TIME


func details() -> int:
	if low:
		return 0
	return sparks.size() + (1 if age < RING_TIME else 0) + (1 if age < STAR_TIME else 0)


## The ring's radius `t` (0-1) of the way through RING_TIME.
func ring_radius(t: float) -> float:
	return lerpf(bar.y * 0.5, bar.y * RING_REACH, 1.0 - pow(1.0 - t, 3.0))


func _draw() -> void:
	var a := fade()
	if a > 0.0:
		CrossBlast.draw_sculpted_cross(
			self,
			bar,
			Color(BODY, BODY.a * a),
			Color(CORE, CORE.a * a),
			Color(CENTER, a),
		)
		# Crisp teal Sentinel energy rims tracing the 4 tapered lance tips.
		var half_l := bar.x * 0.5
		var half_w := bar.y * 0.26
		var teal_rim := Color(EDGE, EDGE.a * a)
		for dir: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
			var side := dir.orthogonal()
			var tip := dir * half_l
			var shoulder := dir * (half_l * 0.34)
			var base := dir * (bar.y * 0.22)
			draw_polyline(PackedVector2Array([base + side * half_w, shoulder + side * (half_w * 0.72), tip]), teal_rim, 2.0, true)
			draw_polyline(PackedVector2Array([base - side * half_w, shoulder - side * (half_w * 0.72), tip]), teal_rim, 2.0, true)
	if low:
		return
	if age < RING_TIME:
		var t := age / RING_TIME
		var ra := 1.0 - t
		var r := ring_radius(t)
		# Expanding teal-rimmed golden sanctum ring with cardinal sanctum ticks.
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 56, Color(EDGE, 0.85 * ra), lerpf(3.6, 1.1, t), true)
		draw_arc(Vector2.ZERO, r * 0.84, 0.0, TAU, 48, Color(BODY.lightened(0.25), 0.7 * ra), lerpf(2.4, 0.8, t), true)
		for i in 8:
			var ang := i * PI / 4.0 + t * 0.25
			var d := Vector2.from_angle(ang)
			var tick := 9.0 if i % 2 == 0 else 5.0
			draw_line(d * (r - tick), d * r, Color(CENTER, 0.7 * ra), 1.6, true)
	if age < STAR_TIME:
		var t := age / STAR_TIME
		var sa := 1.0 - t
		var outer_r := bar.y * lerpf(1.15, 1.75, 1.0 - (1.0 - t) * (1.0 - t))
		# Radiant 8-point Sentinel light star centerpiece.
		ClassicStar.draw(self, Vector2.ZERO, outer_r, 0.0, Color(EDGE, 0.65 * sa), 0.16)
		ClassicStar.draw(self, Vector2.ZERO, outer_r * 0.82, PI / 4.0, Color(BODY.lightened(0.3), 0.82 * sa), 0.18)
		ClassicStar.draw(self, Vector2.ZERO, outer_r * 0.58, 0.0, Color(CENTER, 0.96 * sa), 0.16)
	sparks.draw_on(self)
