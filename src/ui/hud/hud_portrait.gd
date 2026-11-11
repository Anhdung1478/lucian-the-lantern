class_name HudPortrait
extends Control
## Lucian's portrait on the bottom bar: the skin's picture cut to a disc,
## inside a gold ring with a fainter line within it, like the menus'
## medallion. The level badge sits on the ring.

const RING := 3.0
## The fainter line, this far inside the ring, and how faint it is.
const INNER_INSET := 4.5
const INNER_ALPHA := 0.5
const STEPS := 48

var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - RING * 0.5
	if texture:
		var points := PackedVector2Array()
		var uvs := PackedVector2Array()
		for i in STEPS:
			var direction := Vector2.from_angle(TAU * i / STEPS)
			points.append(center + direction * radius)
			uvs.append(Vector2(0.5, 0.5) + direction * 0.5)
		draw_colored_polygon(points, Color.WHITE, uvs, texture)
	draw_arc(center, radius, 0.0, TAU, STEPS, UiStyle.BORDER_COLOR, RING, true)
	draw_arc(center, radius - INNER_INSET, 0.0, TAU, STEPS, Color(UiStyle.BORDER_COLOR, INNER_ALPHA), 1.0, true)
