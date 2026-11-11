class_name SoftShape
## Soft-edged shapes for shadows and glows, each drawn as one mesh with a
## color per point: no texture and no shader. Call them from inside a _draw.

## Points round an ellipse.
const SIDES := 24
## Each ring past the middle: how far out it lies (0 = the core's edge, 1 =
## the rim) and the share of the alpha left there. The fade is quick at
## first, then long and faint.
const RINGS := [Vector2(0.0, 1.0), Vector2(0.5, 0.4), Vector2(1.0, 0.0)]


## A filled ellipse of `color` round `center`, `half` wide and high: solid out
## to `core` of the way to its rim, then fading to nothing at the rim.
static func ellipse(canvas: CanvasItem, center: Vector2, half: Vector2, color: Color, core := 0.4) -> void:
	var points := PackedVector2Array([center])
	var colors := PackedColorArray([color])
	var indices := PackedInt32Array()
	for ring in RINGS.size():
		var reach := lerpf(core, 1.0, RINGS[ring].x)
		var shade := Color(color, color.a * RINGS[ring].y)
		var first := 1 + ring * SIDES
		for i in SIDES:
			points.append(center + Vector2.from_angle(TAU * i / SIDES) * half * reach)
			colors.append(shade)
			var next := (i + 1) % SIDES
			if ring == 0:
				indices.append_array([0, first + i, first + next])
			else:
				var inner := first - SIDES
				indices.append_array([inner + i, first + i, first + next, inner + i, first + next, inner + next])
	RenderingServer.canvas_item_add_triangle_array(canvas.get_canvas_item(), indices, points, colors)
