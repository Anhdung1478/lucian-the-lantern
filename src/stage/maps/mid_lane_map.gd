class_name MidLaneMap
extends StageMap
## Act 1: a long diagonal lane from the bottom-left to the top-right, jungle
## walls on both sides, and the river crossing its middle as walkable
## shallow water. Three rocks give cover. Lucian and Senna start at the
## bottom-left end; minions come from the top-right end; Thresh rises from
## the river.

const LANE_START := Vector2(500, 2700)
const LANE_END := Vector2(4700, 500)
const LANE_HALF := 450.0
## Half the river's width, and how far it runs each way from the lane's center.
const RIVER_HALF := 260.0
const RIVER_REACH := 1100.0
const ROCK_RADIUS := 70.0
const LANE_COLOR := Color("5b5244")
const JUNGLE_COLOR := Color("1d3a24")
const JUNGLE_EDGE := Color("2f5a35")
const TREE_COLOR := Color("16301d")
const RIVER_COLOR := Color("2e5f86")
const RIVER_EDGE := Color("6fb4d8")
const ROCK_COLOR := Color("6b6660")

var _river: PackedVector2Array


func _init() -> void:
	size = Vector2(5200, 3200)
	var area := PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
	var lane := _band(LANE_START - along() * 2000.0, LANE_END + along() * 2000.0, LANE_HALF)
	var river := _band(center() - across() * RIVER_REACH, center() + across() * RIVER_REACH, RIVER_HALF)
	_river = Geometry2D.intersect_polygons(area, river)[0]
	var open: PackedVector2Array = Geometry2D.merge_polygons(lane, river)[0]
	# The open lane and river cross the whole area, so every piece is jungle (no holes).
	for piece in Geometry2D.clip_polygons(area, open):
		wall_polygons.append(piece)
	lucian_start = LANE_START + along() * 300.0
	ally_start = LANE_START + along() * 120.0 + across() * 160.0
	merchant_point = center() - along() * 700.0 - across() * 160.0
	boss_point = center() + across() * 300.0
	spawn_points = [LANE_END - along() * 200.0 + across() * 160.0, LANE_END - along() * 200.0 - across() * 160.0]
	for rock: Vector2 in [center() - along() * 480.0 + across() * 230.0, center() + along() * 480.0 - across() * 230.0, center() - across() * 720.0]:
		wall_circles.append(Vector3(rock.x, rock.y, ROCK_RADIUS))


## Down the lane, toward the minions' end.
func along() -> Vector2:
	return (LANE_END - LANE_START).normalized()


## Across the lane, toward the top-left jungle.
func across() -> Vector2:
	return along().orthogonal()


func center() -> Vector2:
	return (LANE_START + LANE_END) * 0.5


func _band(from: Vector2, to: Vector2, half: float) -> PackedVector2Array:
	var side := (to - from).normalized().orthogonal() * half
	return PackedVector2Array([from + side, to + side, to - side, from - side])


func _draw() -> void:
	# The jungle runs on past the edges, where the camera still sees.
	for rect in border_rects():
		draw_rect(rect, JUNGLE_COLOR)
	draw_rect(get_bounds(), LANE_COLOR)
	draw_colored_polygon(_river, RIVER_COLOR)
	var ripples := RandomNumberGenerator.new()
	ripples.seed = 3
	for i in 40:
		var at := center() + across() * ripples.randf_range(-RIVER_REACH, RIVER_REACH) + along() * ripples.randf_range(-RIVER_HALF + 30.0, RIVER_HALF - 30.0)
		draw_arc(at, ripples.randf_range(18.0, 40.0), PI * 1.1, PI * 1.9, 12, Color(RIVER_EDGE, 0.35), 2.0, true)
	var trees := RandomNumberGenerator.new()
	trees.seed = 7
	for polygon in wall_polygons:
		draw_colored_polygon(polygon, JUNGLE_COLOR)
		var box := _bounds_of(polygon)
		for i in 70:
			var at := Vector2(trees.randf_range(box.position.x, box.end.x), trees.randf_range(box.position.y, box.end.y))
			if Geometry2D.is_point_in_polygon(at, polygon) and _distance_to_edge(at, polygon) > 80.0:
				draw_circle(at, trees.randf_range(40.0, 80.0), TREE_COLOR)
		var outline := polygon.duplicate()
		outline.append(polygon[0])
		draw_polyline(outline, JUNGLE_EDGE, 8.0, true)
	for rock in wall_circles:
		draw_circle(Vector2(rock.x, rock.y), rock.z, ROCK_COLOR)
		draw_arc(Vector2(rock.x, rock.y), rock.z, 0.0, TAU, 32, ROCK_COLOR.lightened(0.3), 4.0, true)
	draw_rect(get_bounds(), JUNGLE_EDGE, false, 4.0)


static func _bounds_of(polygon: PackedVector2Array) -> Rect2:
	var box := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		box = box.expand(point)
	return box
