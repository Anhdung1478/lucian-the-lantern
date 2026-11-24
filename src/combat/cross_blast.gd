class_name CrossBlast
extends Node2D
## W's explosion: a sculpted 4-pointed diamond/lance flare cross that fades
## out. Also provides shared tapered cross-blade drawing helpers for all skins.

const LIFETIME := 0.35

## One arm of the cross: length × width.
var bar := Vector2.ZERO


func setup(at: Vector2, direction: Vector2, arm: Vector2) -> void:
	position = at
	rotation = direction.angle()
	bar = arm


func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, LIFETIME).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)


func _draw() -> void:
	draw_sculpted_cross(self, bar, Color(1.0, 0.48, 0.1, 0.52), Color(1.0, 0.82, 0.48, 0.88), Color(1.0, 0.97, 0.88, 1.0))


## Draws a sculpted tapered 4-pointed lance-flare cross of size `arm_bar`
## (arm length × arm width): soft outer aura blades, vivid inner lance blades,
## incandescent needle core, and central radiant bloom.
static func draw_sculpted_cross(canvas: CanvasItem, arm_bar: Vector2, outer: Color, inner: Color,
		core: Color, core_scale := 1.0) -> void:
	if arm_bar.x <= 1.0 or arm_bar.y <= 1.0:
		return
	var half_len := arm_bar.x * 0.5
	var half_w := arm_bar.y * 0.5
	# Soft outer aura blades along both axes.
	draw_blade_arm(canvas, half_len * 1.04, half_w * 1.12, outer, true, true)
	draw_blade_arm(canvas, half_len * 1.04, half_w * 1.12, outer, false, true)
	# Crisp inner themed energy blades.
	draw_blade_arm(canvas, half_len, half_w * 0.62, inner, true, true)
	draw_blade_arm(canvas, half_len, half_w * 0.62, inner, false, true)
	# Incandescent needle core.
	draw_blade_arm(canvas, half_len * 0.88, half_w * 0.22 * core_scale, core, true, false)
	draw_blade_arm(canvas, half_len * 0.88, half_w * 0.22 * core_scale, core, false, false)
	# Soft radiant central starburst bloom.
	SoftShape.ellipse(canvas, Vector2.ZERO, Vector2.ONE * (half_w * 1.35), Color(outer, outer.a * 0.85), 0.22)
	SoftShape.ellipse(canvas, Vector2.ZERO, Vector2.ONE * (half_w * 0.72), Color(core, core.a * 0.95), 0.4)


## Draws one sculpted double-ended lance/diamond flare blade from -`half_len`
## to +`half_len` along either the X (`horizontal = true`) or Y axis. Widest
## near the center, tapering smoothly to sharp glowing spear-tips at both ends.
static func draw_blade_arm(canvas: CanvasItem, half_len: float, half_w: float, color: Color,
		horizontal: bool, soft_edge := true) -> void:
	if half_len <= 1.0 or half_w <= 0.1 or color.a <= 0.001:
		return
	const POS: Array[float] = [-1.0, -0.72, -0.34, 0.0, 0.34, 0.72, 1.0]
	const PROFILE: Array[float] = [0.0, 0.26, 0.68, 1.0, 0.68, 0.26, 0.0]
	const ALPHAS: Array[float] = [0.0, 0.78, 0.96, 1.0, 0.96, 0.78, 0.0]
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var count := POS.size()
	if soft_edge:
		var edge_clear := Color(color.r, color.g, color.b, 0.0)
		for i in count:
			var along := POS[i] * half_len
			var across := PROFILE[i] * half_w
			var mid := Color(color.r, color.g, color.b, color.a * ALPHAS[i])
			if horizontal:
				points.append(Vector2(along, -across))
				points.append(Vector2(along, 0.0))
				points.append(Vector2(along, across))
			else:
				points.append(Vector2(-across, along))
				points.append(Vector2(0.0, along))
				points.append(Vector2(across, along))
			colors.append(edge_clear)
			colors.append(mid)
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
			var along := POS[i] * half_len
			var across := PROFILE[i] * half_w
			var col := Color(color.r, color.g, color.b, color.a * ALPHAS[i])
			if horizontal:
				points.append(Vector2(along, -across))
				points.append(Vector2(along, across))
			else:
				points.append(Vector2(-across, along))
				points.append(Vector2(across, along))
			colors.append(col)
			colors.append(col)
		for i in count - 1:
			var a := i * 2
			var b := (i + 1) * 2
			indices.append_array([a, b, b + 1, a, b + 1, a + 1])
	RenderingServer.canvas_item_add_triangle_array(canvas.get_canvas_item(), indices, points, colors)
