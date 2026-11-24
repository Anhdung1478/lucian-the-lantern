class_name HitSpark
extends Node2D
## A sharp burst of tapered diamond/wedge sparks and an impact flash dot where
## a hit landed, in the color of the damage, gone within LIFETIME. A crit adds
## a bold 4-pointed golden-white starburst flare. Only a look, and only made
## while Juice is on.

const LIFETIME := 0.2
const STREAKS := 6
## A spark starts, and ends, this far from the middle, growing out.
const START := 5.0
const REACH := 28.0
const LENGTH := 14.0
const WIDTH := 3.4
const CRIT_SCALE := 1.6

var color := Color.WHITE

var _age := 0.0
var _crit := false
## Each spark: [angle, reach_mult, len_mult, width_mult].
var _sparks: Array[Array] = []


## Makes a spark of `color` at `at` (world), under `parent`; a crit's bigger.
static func spawn(parent: Node, at: Vector2, spark_color: Color, crit: bool) -> void:
	if not Juice.on():
		return
	var spark := HitSpark.new()
	spark.color = spark_color
	spark.position = at
	spark._crit = crit
	var turn := randf() * TAU
	var count := STREAKS + (2 if crit else 0)
	for i in count:
		var ang := turn + TAU * i / count + randf_range(-0.22, 0.22)
		spark._sparks.append([ang, randf_range(0.8, 1.2), randf_range(0.75, 1.28), randf_range(0.75, 1.2)])
	if crit:
		spark.scale = Vector2.ONE * CRIT_SCALE
	parent.add_child(spark)


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := clampf(_age / LIFETIME, 0.0, 1.0)
	var out := 1.0 - (1.0 - t) * (1.0 - t)
	var fade := 1.0 - t
	var hot := color.lerp(Color.WHITE, 0.72)
	# Crisp central impact flash dot (punches bright right on hit).
	if t < 0.5:
		var ft := 1.0 - t / 0.5
		SoftShape.ellipse(self, Vector2.ZERO, Vector2.ONE * lerpf(11.0, 17.0, 1.0 - ft), Color(color, 0.52 * ft), 0.25)
		draw_circle(Vector2.ZERO, 4.5 * ft + 1.5, Color(hot, 0.95 * ft))
	# Crit: bold 4-pointed golden-white starburst flare + crisp micro-ring.
	if _crit:
		var flare_a := pow(fade, 1.35)
		var gold := Color(1.0, 0.86, 0.42, 0.78 * flare_a)
		var star_r := lerpf(24.0, 10.0, t)
		var outer_star := PackedVector2Array()
		var inner_star := PackedVector2Array()
		for i in 8:
			var ang := i * PI / 4.0
			var r_out := star_r * (1.0 if i % 2 == 0 else 0.19)
			var r_in := star_r * (0.68 if i % 2 == 0 else 0.12)
			outer_star.append(Vector2.RIGHT.rotated(ang) * r_out)
			inner_star.append(Vector2.RIGHT.rotated(ang) * r_in)
		draw_colored_polygon(outer_star, gold)
		draw_colored_polygon(inner_star, Color(1.0, 0.99, 0.92, 0.96 * flare_a))
		draw_arc(Vector2.ZERO, lerpf(6.0, 22.0, out), 0.0, TAU, 28, Color(gold, 0.65 * fade * fade), lerpf(2.5, 0.6, t), true)
	# Sharp tapered diamond/wedge sparks radiating outward.
	var outer_col := Color(color, 0.95 * fade)
	var inner_col := Color(hot, 0.9 * fade)
	for s in _sparks:
		var way := Vector2.from_angle(s[0])
		var side := way.orthogonal()
		var reach := lerpf(START, REACH * (s[1] as float), out)
		var seg_len := LENGTH * (s[2] as float) * (0.35 + 0.65 * fade)
		var half_w := WIDTH * 0.5 * (s[3] as float) * (0.35 + 0.65 * fade)
		var tail := way * reach
		var mid := way * (reach + seg_len * 0.35)
		var tip := way * (reach + seg_len)
		draw_colored_polygon(PackedVector2Array([tail, mid + side * half_w, tip, mid - side * half_w]), outer_col)
		draw_colored_polygon(PackedVector2Array([tail.lerp(mid, 0.4), mid + side * (half_w * 0.45), tip.lerp(mid, 0.2), mid - side * (half_w * 0.45)]), inner_col)
