class_name ChainLightning
extends Node2D
## A jagged bolt through a list of points (Statikk Shiv's chain, Hextech
## Gunblade's bolt) that flickers and fades out.

const LIFETIME := 0.3
const JAG := 14.0
const STEP := 36.0

var color := Color("9fd8ff")

var _points := PackedVector2Array()
var _left := LIFETIME


func setup(points: PackedVector2Array, bolt_color: Color) -> void:
	_points = points
	color = bolt_color


func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var alpha := _left / LIFETIME
	for i in _points.size() - 1:
		var line := _jagged(_points[i], _points[i + 1])
		draw_polyline(line, Color(color, 0.35 * alpha), 9.0, true)
		draw_polyline(line, Color(Color.WHITE, alpha), 2.5, true)
		draw_circle(_points[i + 1], 10.0, Color(color, 0.5 * alpha))


## A zigzag from `a` to `b`, new every frame so the bolt flickers.
func _jagged(a: Vector2, b: Vector2) -> PackedVector2Array:
	var line := PackedVector2Array([a])
	var count := maxi(int(a.distance_to(b) / STEP), 1)
	var side := (b - a).normalized().orthogonal()
	for i in range(1, count):
		line.append(a.lerp(b, float(i) / count) + side * randf_range(-JAG, JAG))
	line.append(b)
	return line
