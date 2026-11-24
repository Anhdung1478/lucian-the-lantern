class_name LaserBeam
extends Node2D
## Q's beam: a sculpted tapered energy lance that fades out. Dark Lucian's Q
## sets its own colors. Also provides shared tapered-beam and muzzle-flare
## drawing helpers used by the skin beams.

const LIFETIME := 0.25

## The wide glow, the core, and the thin line in the middle.
var glow_color := Color(1.0, 0.8, 0.35, 0.38)
var core_color := Color(1.0, 0.95, 0.75, 0.88)
var center_color := Color.WHITE

## The beam's size: along its rotation, and across.
var length := 0.0
var width := 0.0


func setup(from: Vector2, direction: Vector2, beam_length: float, beam_width: float) -> void:
	position = from
	rotation = direction.angle()
	length = beam_length
	width = beam_width


func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, LIFETIME).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)


func _draw() -> void:
	if length <= 0.0 or width <= 0.0:
		return
	draw_tapered_beam(self, 0.0, length, width * 0.56, glow_color, minf(length * 0.14, 72.0), 0.55, true)
	draw_tapered_beam(self, 0.0, length, width * 0.26, core_color, minf(length * 0.11, 56.0), 0.65, true)
	draw_tapered_beam(self, 0.0, length, width * 0.10, center_color, minf(length * 0.08, 42.0), 0.7, false)
	draw_muzzle_flare(self, Vector2.ZERO, width * 0.58, glow_color, center_color)


## Draws a sculpted tapered beam from `x0` to `x1` along +x, anchored cleanly
## at `x0` (width scaled by `start_taper`) and tapering to a sharp lance tip
## at `x1`. When `soft_edge` is true, outer edges feather smoothly to alpha 0.
static func draw_tapered_beam(canvas: CanvasItem, x0: float, x1: float, half_w: float, color: Color,
		tip_len := 48.0, start_taper := 0.6, soft_edge := true) -> void:
	var span := x1 - x0
	if span <= 1.0 or half_w <= 0.1 or color.a <= 0.001:
		return
	var swell := minf(22.0, span * 0.12)
	var tip := minf(tip_len, span * 0.35)
	var xs := PackedFloat32Array([
		x0,
		x0 + swell,
		x1 - tip,
		x1 - tip * 0.42,
		x1,
	])
	var ws := PackedFloat32Array([
		half_w * start_taper,
		half_w * 1.06,
		half_w * 0.88,
		half_w * 0.42,
		0.0,
	])
	var alphas := PackedFloat32Array([0.92, 1.0, 0.96, 0.78, 0.0])
	draw_ribbon_strip(canvas, xs, ws, alphas, color, soft_edge)


## Draws a multi-station horizontal ribbon along +x given x positions, half
## widths, and per-station alpha multipliers. Uses a 3-row feathered mesh when
## `soft_edge` is true, or a crisp 2-row solid strip otherwise.
static func draw_ribbon_strip(canvas: CanvasItem, xs: PackedFloat32Array, ws: PackedFloat32Array,
		alphas: PackedFloat32Array, color: Color, soft_edge := true) -> void:
	var count := xs.size()
	if count < 2 or color.a <= 0.001:
		return
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	if soft_edge:
		var edge_clear := Color(color.r, color.g, color.b, 0.0)
		for i in count:
			var x := xs[i]
			var w := ws[i]
			var mid := Color(color.r, color.g, color.b, color.a * alphas[i])
			points.append(Vector2(x, -w))
			colors.append(edge_clear)
			points.append(Vector2(x, 0.0))
			colors.append(mid)
			points.append(Vector2(x, w))
			colors.append(edge_clear)
		for i in count - 1:
			var a := i * 3
			var b := (i + 1) * 3
			indices.append_array([
				a, b, b + 1, a, b + 1, a + 1,
				a + 1, b + 1, b + 2, a + 1, b + 2, a + 2,
			])
	else:
		for i in count:
			var x := xs[i]
			var w := ws[i]
			var col := Color(color.r, color.g, color.b, color.a * alphas[i])
			points.append(Vector2(x, -w))
			colors.append(col)
			points.append(Vector2(x, w))
			colors.append(col)
		for i in count - 1:
			var a := i * 2
			var b := (i + 1) * 2
			indices.append_array([a, b, b + 1, a, b + 1, a + 1])
	RenderingServer.canvas_item_add_triangle_array(canvas.get_canvas_item(), indices, points, colors)


## Draws a crisp incandescent muzzle-origin starburst flare at `at`.
static func draw_muzzle_flare(canvas: CanvasItem, at: Vector2, radius: float, glow: Color, core: Color,
		angle := 0.0) -> void:
	if radius <= 0.5 or (glow.a <= 0.001 and core.a <= 0.001):
		return
	SoftShape.ellipse(canvas, at, Vector2(radius * 1.15, radius * 0.95), Color(glow, glow.a * 0.85), 0.25)
	var spikes := PackedVector2Array()
	for i in 8:
		var r := radius * (1.05 if i % 2 == 0 else 0.22)
		if i == 0:
			r *= 1.35
		spikes.append(at + Vector2.RIGHT.rotated(angle + i * PI / 4.0) * r)
	canvas.draw_colored_polygon(spikes, Color(core, core.a * 0.9))
	SoftShape.ellipse(canvas, at, Vector2.ONE * (radius * 0.36), core, 0.45)
