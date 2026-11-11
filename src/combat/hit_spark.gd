class_name HitSpark
extends Node2D
## A small burst of short streaks where a hit landed, in the color of the
## damage, gone within LIFETIME. A crit's is bigger. Only a look, and only
## made while Juice is on.

const LIFETIME := 0.2
const STREAKS := 6
## A streak starts, and ends, this far from the middle, growing out.
const START := 6.0
const REACH := 26.0
const LENGTH := 10.0
const WIDTH := 2.5
const CRIT_SCALE := 1.6

var color := Color.WHITE

var _age := 0.0
## A turn added to every streak, so no two hits look alike.
var _turn := 0.0


## Makes a spark of `color` at `at` (world), under `parent`; a crit's bigger.
static func spawn(parent: Node, at: Vector2, spark_color: Color, crit: bool) -> void:
	if not Juice.on():
		return
	var spark := HitSpark.new()
	spark.color = spark_color
	spark.position = at
	spark._turn = randf() * TAU
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
	var t := _age / LIFETIME
	var reach := lerpf(START, REACH, 1.0 - (1.0 - t) * (1.0 - t))
	var color_now := Color(color, 1.0 - t)
	for i in STREAKS:
		var way := Vector2.from_angle(_turn + TAU * i / STREAKS)
		draw_line(way * reach, way * (reach + LENGTH * (1.0 - t)), color_now, WIDTH * (1.0 - t * 0.5))
