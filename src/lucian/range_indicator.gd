class_name RangeIndicator
extends Node2D
## Draws a cast's range around Lucian, under his body: while a HUD slot is
## hovered (pointing where he faces) and while a cast is being aimed (pointing
## at the cursor). The aimed cast wins. A child of Lucian.

const FILL := Color(0.55, 0.78, 1.0, 0.12)
const EDGE := Color(0.75, 0.9, 1.0, 0.6)
const LANDING := Color(0.85, 0.95, 1.0, 0.85)
const DASH_LENGTH := 16.0

## Set by the HUD while one of its slots is hovered.
var hovered: CastRange
## Set by the controller while a cast is being aimed.
var aimed: CastRange
## The world point the aimed cast points at.
var aim_point := Vector2.ZERO


func shown() -> CastRange:
	return aimed if aimed else hovered


func _process(_delta: float) -> void:
	visible = shown() != null
	if visible:
		queue_redraw()


func _draw() -> void:
	var shape := shown()
	if shape == null:
		return
	var lucian := get_parent() as Lucian
	if shape.kind == CastRange.Kind.CIRCLE:
		draw_circle(Vector2.ZERO, shape.reach, FILL)
		draw_arc(Vector2.ZERO, shape.reach, 0.0, TAU, 128, EDGE, 2.0, true)
		# Flash, while aimed: where Lucian lands.
		if shape.landing and shape == aimed:
			var offset := aim_point - global_position
			var at := lucian.aim_direction(aim_point) * shape.landing_distance(offset.length())
			draw_arc(at, CastRange.BODY_WIDTH * 0.5, 0.0, TAU, 48, LANDING, 2.5, true)
		return
	var direction := Vector2.from_angle(lucian.visuals.rotation)
	var distance := shape.reach
	if shape == aimed:
		direction = lucian.aim_direction(aim_point)
		distance = global_position.distance_to(aim_point)
	draw_set_transform(Vector2.ZERO, direction.angle())
	if shape.kind == CastRange.Kind.TWIN_LINES:
		for side: float in [-1.0, 1.0]:
			var y := side * shape.spread
			draw_dashed_line(Vector2(0, y), Vector2(shape.reach, y), EDGE, 3.0, DASH_LENGTH)
		return
	var half := shape.width * 0.5
	draw_rect(Rect2(0, -half, shape.reach, shape.width), FILL)
	draw_line(Vector2(0, -half), Vector2(shape.reach, -half), EDGE, 2.0, true)
	draw_line(Vector2(0, half), Vector2(shape.reach, half), EDGE, 2.0, true)
	# A dash's end is its landing ring instead.
	if not shape.landing:
		draw_line(Vector2(shape.reach, -half), Vector2(shape.reach, half), EDGE, 2.0, true)
	if shape.cross != Vector2.ZERO:
		var end := Vector2(shape.reach, 0)
		var across := Vector2(shape.cross.y, shape.cross.x)
		draw_rect(Rect2(end - shape.cross * 0.5, shape.cross), EDGE, false, 2.0)
		draw_rect(Rect2(end - across * 0.5, across), EDGE, false, 2.0)
	if shape.landing:
		var at := Vector2(shape.landing_distance(distance), 0)
		draw_arc(at, CastRange.BODY_WIDTH * 0.5, 0.0, TAU, 48, LANDING, 2.5, true)
