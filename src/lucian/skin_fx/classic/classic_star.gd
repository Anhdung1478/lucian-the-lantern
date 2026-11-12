class_name ClassicStar
extends RefCounted
## Drawing helper for Classic's light: a four-point star.


## A star of four points on `canvas`: `radius` to each tip, pinched in to
## `waist` (0-1 of the radius) between them, turned by `angle`.
static func draw(canvas: CanvasItem, center: Vector2, radius: float, angle: float, color: Color, waist := 0.2) -> void:
	var points := PackedVector2Array()
	for i in 8:
		var length := radius if i % 2 == 0 else radius * waist
		points.append(center + Vector2.RIGHT.rotated(angle + i * PI / 4.0) * length)
	canvas.draw_colored_polygon(points, color)
