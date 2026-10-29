class_name DragonPitMap
extends StageMap
## Act 3, stage 5: the Elder Dragon's pit (3600 × 3600). A round stone floor
## with rock all round it. The rock is WALL_PIECES arc pieces, so no wall has
## a hole, and ROCKS rocks in a ring give cover. There are no camps: waves
## come in at the north, east and west rim, in turn (never the south, where
## Lucian starts). The merchant stands south of the middle and the dragon
## lands in the middle.

const FLOOR_RADIUS := 1650.0
const WALL_PIECES := 8
## Points along each piece's arc.
const ARC_POINTS := 12
const ROCKS := 6
const ROCK_RADIUS := 80.0
const ROCK_RING := 900.0
## The spawn points' distance from the middle, inside the rim.
const SPAWN_RING := 1450.0
const LUCIAN_START := Vector2(0, 1000)
const MERCHANT := Vector2(0, 450)
const STONE_COLOR := Color("24221f")
const BOULDER_COLOR := Color("1a1917")
const STONE_EDGE := Color("766d60")
const FLOOR_COLOR := Color("4a4540")
const RING_COLOR := Color(0.85, 0.8, 0.7, 0.12)
const HEART_COLOR := Color(0.55, 0.45, 0.95, 0.16)
const ROCK_COLOR := Color("6b6660")


func _init() -> void:
	size = Vector2(3600, 3600)
	var middle := size * 0.5
	var area := PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
	# Each piece: its arc of the rim, then out past the area's corners.
	var reach := size.length()
	for i in WALL_PIECES:
		var from := TAU * i / WALL_PIECES
		var to := TAU * (i + 1) / WALL_PIECES
		var wedge := PackedVector2Array()
		for step in ARC_POINTS + 1:
			wedge.append(middle + Vector2.from_angle(lerpf(from, to, float(step) / ARC_POINTS)) * FLOOR_RADIUS)
		wedge.append(middle + Vector2.from_angle(to) * reach)
		wedge.append(middle + Vector2.from_angle(from) * reach)
		wall_polygons.append_array(Geometry2D.intersect_polygons(area, wedge))
	for i in ROCKS:
		var rock := middle + Vector2.from_angle(TAU * i / ROCKS) * ROCK_RING
		wall_circles.append(Vector3(rock.x, rock.y, ROCK_RADIUS))
	lucian_start = middle + LUCIAN_START
	merchant_point = middle + MERCHANT
	boss_point = middle
	# Not the south rim: a wave would come in on top of Lucian's start.
	for direction in [Vector2.UP, Vector2.RIGHT, Vector2.LEFT]:
		spawn_points.append(middle + direction * SPAWN_RING)


func _draw() -> void:
	var middle := size * 0.5
	for rect in border_rects():
		draw_rect(rect, STONE_COLOR)
	draw_rect(get_bounds(), STONE_COLOR)
	draw_circle(middle, FLOOR_RADIUS, FLOOR_COLOR)
	for ring in [350.0, 700.0, 1200.0]:
		draw_arc(middle, ring, 0.0, TAU, 96, RING_COLOR, 4.0, true)
	for i in 12:
		var direction := Vector2.from_angle(TAU * (i + 0.5) / 12)
		draw_line(middle + direction * 380.0, middle + direction * 1180.0, RING_COLOR, 3.0, true)
	draw_circle(middle, 300.0, HEART_COLOR)
	var boulders := RandomNumberGenerator.new()
	boulders.seed = 13
	for polygon in wall_polygons:
		draw_colored_polygon(polygon, STONE_COLOR)
		var box := _bounds_of(polygon)
		for i in 40:
			var at := Vector2(boulders.randf_range(box.position.x, box.end.x), boulders.randf_range(box.position.y, box.end.y))
			if Geometry2D.is_point_in_polygon(at, polygon) and _distance_to_edge(at, polygon) > 60.0:
				draw_circle(at, boulders.randf_range(30.0, 60.0), BOULDER_COLOR)
	draw_arc(middle, FLOOR_RADIUS, 0.0, TAU, 128, STONE_EDGE, 12.0, true)
	for rock in wall_circles:
		draw_circle(Vector2(rock.x, rock.y), rock.z, ROCK_COLOR)
		draw_arc(Vector2(rock.x, rock.y), rock.z, 0.0, TAU, 32, ROCK_COLOR.lightened(0.3), 4.0, true)
	draw_rect(get_bounds(), STONE_EDGE, false, 4.0)
