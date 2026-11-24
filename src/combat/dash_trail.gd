class_name DashTrail
extends Node2D
## A dash's trail: a smoothly tapered velocity wake from where the dash
## started, growing behind Lucian as he goes, that fades out once the dash is
## over. Also provides shared tapered-ribbon and speed-needle drawing helpers.

## Seconds the trail takes to fade after the dash.
const LIFETIME := 0.3
const STREAK_OFFSETS := [-14.0, 0.0, 14.0]
## E's light blue. Item dashes pass their own color.
const LIGHT := Color(0.62, 0.77, 1.0)

var color := LIGHT
## From the start of the dash to Lucian.
var length := 0.0


func setup(from: Vector2, trail_color := LIGHT) -> void:
	position = from
	color = trail_color


## Stretches the trail up to `to` (Lucian) while the dash goes on.
func reach(to: Vector2) -> void:
	length = position.distance_to(to)
	if length > 0.0:
		rotation = (to - position).angle()
	queue_redraw()


## The dash is over: fade out.
func finish() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, LIFETIME)
	tween.tween_callback(queue_free)


func _draw() -> void:
	if length <= 1.0:
		return
	draw_tapered_ribbon(self, length, 28.0, Color(color, 0.0), Color(color, 0.32), true)
	draw_tapered_ribbon(self, length, 12.0, Color(color, 0.0), Color(color.lerp(Color.WHITE, 0.45), 0.36), true)
	var streak := Color(color.lerp(Color.WHITE, 0.65), 0.82)
	for offset: float in STREAK_OFFSETS:
		var weight := 1.0 - absf(offset) / 26.0
		draw_speed_needle(self, length * 0.04, length, offset * 0.25, offset, 2.6 * weight, Color(streak, streak.a * weight))


## Draws a smoothly tapered velocity wake from x = 0 (width 0, alpha 0) up to
## full sleek wake at x = `trail_length` (softly rounded at Lucian's back).
static func draw_tapered_ribbon(canvas: CanvasItem, trail_length: float, max_half_w: float,
		tail_color: Color, head_color: Color, soft_edge := true) -> void:
	if trail_length <= 1.0 or max_half_w <= 0.1:
		return
	const SHARES := [0.0, 0.14, 0.32, 0.56, 0.78, 0.92, 1.0]
	const WIDTHS := [0.0, 0.24, 0.50, 0.78, 0.96, 1.0, 0.28]
	const ALPHAS := [0.0, 0.18, 0.44, 0.74, 0.95, 1.0, 0.55]
	var count := SHARES.size()
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	if soft_edge:
		for i in count:
			var t: float = SHARES[i]
			var x := t * trail_length
			var w: float = WIDTHS[i] * max_half_w
			var c := tail_color.lerp(head_color, ALPHAS[i])
			c.a = head_color.a * ALPHAS[i]
			var edge := Color(c.r, c.g, c.b, 0.0)
			points.append(Vector2(x, -w))
			colors.append(edge)
			points.append(Vector2(x, 0.0))
			colors.append(c)
			points.append(Vector2(x, w))
			colors.append(edge)
		for i in count - 1:
			var a := i * 3
			var b := (i + 1) * 3
			indices.append_array([
				a, b, b + 1, a, b + 1, a + 1,
				a + 1, b + 1, b + 2, a + 1, b + 2, a + 2,
			])
	else:
		for i in count:
			var t: float = SHARES[i]
			var x := t * trail_length
			var w: float = WIDTHS[i] * max_half_w
			var c := tail_color.lerp(head_color, ALPHAS[i])
			c.a = head_color.a * ALPHAS[i]
			points.append(Vector2(x, -w))
			colors.append(c)
			points.append(Vector2(x, w))
			colors.append(c)
		for i in count - 1:
			var a := i * 2
			var b := (i + 1) * 2
			indices.append_array([a, b, b + 1, a, b + 1, a + 1])
	RenderingServer.canvas_item_add_triangle_array(canvas.get_canvas_item(), indices, points, colors)


## Draws a crisp tapered speed needle from (`x0`, `y0`) (width 0, alpha 0)
## widening smoothly to `max_half_w` near `x1` and pinching to a sharp point.
static func draw_speed_needle(canvas: CanvasItem, x0: float, x1: float, y0: float, y1: float,
		max_half_w: float, streak_color: Color) -> void:
	var p0 := Vector2(x0, y0)
	var p1 := Vector2(x1, y1)
	if p0.distance_squared_to(p1) <= 4.0 or max_half_w <= 0.1 or streak_color.a <= 0.001:
		return
	var side := (p1 - p0).normalized().orthogonal()
	var mid1 := p0.lerp(p1, 0.45)
	var mid2 := p0.lerp(p1, 0.84)
	var c0 := Color(streak_color.r, streak_color.g, streak_color.b, 0.0)
	var c1 := Color(streak_color.r, streak_color.g, streak_color.b, streak_color.a * 0.55)
	var c2 := streak_color
	var c3 := Color(streak_color.r, streak_color.g, streak_color.b, streak_color.a * 0.35)
	var points := PackedVector2Array([
		p0,
		mid1 - side * (max_half_w * 0.55),
		mid1 + side * (max_half_w * 0.55),
		mid2 - side * max_half_w,
		mid2 + side * max_half_w,
		p1,
	])
	var colors := PackedColorArray([c0, c1, c1, c2, c2, c3])
	var indices := PackedInt32Array([
		0, 1, 2,
		1, 3, 4, 1, 4, 2,
		3, 5, 4,
	])
	RenderingServer.canvas_item_add_triangle_array(canvas.get_canvas_item(), indices, points, colors)
