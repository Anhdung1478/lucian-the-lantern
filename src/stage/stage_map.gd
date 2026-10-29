class_name StageMap
extends Node2D
## A stage's ground: its size, its walls on Layers.WORLD (the border, plus
## polygons and circles inside) and the points the stage uses. Subclasses
## fill the lists in _init and draw the ground in _draw. The playable area
## starts at (0, 0); the border walls sit just outside it.

const WALL_THICKNESS := 64.0

@export var size := Vector2(4800, 2700)

var lucian_start := Vector2.ZERO
## Senna's place in Act 1.
var ally_start := Vector2.ZERO
var merchant_point := Vector2.ZERO
var boss_point := Vector2.ZERO
## Where wave enemies come from, taken in turn.
var spawn_points: Array[Vector2] = []
## Camp id -> point: wave enemies whose data names a camp here come out of it.
var camps := {}
var wall_polygons: Array[PackedVector2Array] = []
## Round walls: (x, y, radius).
var wall_circles: Array[Vector3] = []


func _ready() -> void:
	var walls := StaticBody2D.new()
	walls.name = "Walls"
	walls.collision_layer = Layers.WORLD
	walls.collision_mask = 0
	for rect in border_rects():
		var box := RectangleShape2D.new()
		box.size = rect.size
		var shape := CollisionShape2D.new()
		shape.shape = box
		shape.position = rect.get_center()
		walls.add_child(shape)
	for polygon in wall_polygons:
		var solid := CollisionPolygon2D.new()
		solid.polygon = polygon
		walls.add_child(solid)
	for circle in wall_circles:
		var round_shape := CircleShape2D.new()
		round_shape.radius = circle.z
		var shape := CollisionShape2D.new()
		shape.shape = round_shape
		shape.position = Vector2(circle.x, circle.y)
		walls.add_child(shape)
	add_child(walls)


func get_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, size)


## Inside the area and at least `margin` away from every wall.
func is_walkable(point: Vector2, margin := 40.0) -> bool:
	if not get_bounds().grow(-margin).has_point(point):
		return false
	for polygon in wall_polygons:
		if Geometry2D.is_point_in_polygon(point, polygon) or _distance_to_edge(point, polygon) < margin:
			return false
	for circle in wall_circles:
		if point.distance_to(Vector2(circle.x, circle.y)) < circle.z + margin:
			return false
	return true


func border_rects() -> Array[Rect2]:
	var t := WALL_THICKNESS
	return [
		Rect2(-t, -t, size.x + 2 * t, t),
		Rect2(-t, size.y, size.x + 2 * t, t),
		Rect2(-t, 0, t, size.y),
		Rect2(size.x, 0, t, size.y),
	]


static func _distance_to_edge(point: Vector2, polygon: PackedVector2Array) -> float:
	var best := INF
	for i in polygon.size():
		var closest := Geometry2D.get_closest_point_to_segment(point, polygon[i], polygon[(i + 1) % polygon.size()])
		best = minf(best, point.distance_to(closest))
	return best
