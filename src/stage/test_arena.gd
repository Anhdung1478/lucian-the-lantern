class_name TestArena
extends StageMap
## Open test map: a floor with a faint grid and solid border walls.
## The playable area starts at (0, 0) and the walls sit just outside it.

const GRID_STEP := 128.0

@export var floor_color := Color("1b2027")
@export var grid_color := Color(1, 1, 1, 0.045)
@export var wall_color := Color("4a4f57")
@export var wall_edge_color := Color("6b717b")


func _init() -> void:
	lucian_start = Vector2(1700, 1350)
	merchant_point = size * 0.5


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
	for rect in border_rects():
		draw_rect(rect, wall_color)
	draw_rect(get_bounds(), wall_edge_color, false, 4.0)
