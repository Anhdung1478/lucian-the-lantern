class_name TestArena
extends Node2D
## Open test map: a floor with a faint grid and solid border walls.
## The playable area starts at (0, 0) and the walls sit just outside it.

const WALL_THICKNESS := 64.0
const GRID_STEP := 128.0

@export var size := Vector2(4800, 2700)
@export var floor_color := Color("1b2027")
@export var grid_color := Color(1, 1, 1, 0.045)
@export var wall_color := Color("4a4f57")
@export var wall_edge_color := Color("6b717b")


func _ready() -> void:
	var walls := StaticBody2D.new()
	walls.name = "Walls"
	walls.collision_layer = Layers.WORLD
	walls.collision_mask = 0
	for rect in _wall_rects():
		var box := RectangleShape2D.new()
		box.size = rect.size
		var shape := CollisionShape2D.new()
		shape.shape = box
		shape.position = rect.get_center()
		walls.add_child(shape)
	add_child(walls)


func get_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, size)


func _draw() -> void:
	draw_rect(get_bounds(), floor_color)
	var x := GRID_STEP
	while x < size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color, 2.0)
		x += GRID_STEP
	var y := GRID_STEP
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), grid_color, 2.0)
		y += GRID_STEP
	for rect in _wall_rects():
		draw_rect(rect, wall_color)
	draw_rect(get_bounds(), wall_edge_color, false, 4.0)


func _wall_rects() -> Array[Rect2]:
	var t := WALL_THICKNESS
	return [
		Rect2(-t, -t, size.x + 2 * t, t),
		Rect2(-t, size.y, size.x + 2 * t, t),
		Rect2(-t, 0, t, size.y),
		Rect2(size.x, 0, t, size.y),
	]
