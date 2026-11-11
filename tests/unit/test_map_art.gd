extends GutTest

const AREA := Rect2(100, 50, 800, 600)
## A wall shaped like an L, not convex.
const WALL := [Vector2(0, 0), Vector2(400, 0), Vector2(400, 100), Vector2(100, 100), Vector2(100, 300), Vector2(0, 300)]


## Stages ([act, stage]) whose maps have ambient life; [0, 0] is the Training arena.
const AMBIENT_STAGES := [[1, 1], [2, 1], [2, 3], [4, 1], [5, 1], [5, 2], [5, 4], [5, 5], [6, 1], [6, 3], [6, 5], [0, 0]]


## A small map with a firefly.
class LitMap:
	extends StageMap

	func _init() -> void:
		size = Vector2(400, 300)

	func build_ambience() -> MapAmbience:
		var ambience := MapAmbience.new()
		ambience.add(MapAmbience.Kind.FIREFLY, PackedVector2Array([Vector2(200, 150)]), Color.YELLOW, MapArt.rng(1))
		return ambience


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real settings.
	if GameSettings._instance == null or GameSettings._instance.path == GameSettings.DEFAULT_PATH:
		GameSettings._instance = GameSettings.new("user://test_map_art_settings.json")


func after_each() -> void:
	GameSettings.instance().set_value(&"quality", "high")


func _wall() -> PackedVector2Array:
	return PackedVector2Array(WALL)


func test_the_same_seed_scatters_the_same_points() -> void:
	var first := MapArt.scatter(MapArt.rng(4), AREA, 50)
	assert_eq(first, MapArt.scatter(MapArt.rng(4), AREA, 50))
	assert_ne(first, MapArt.scatter(MapArt.rng(5), AREA, 50))
	assert_eq(MapArt.grid(MapArt.rng(4), AREA, 90.0), MapArt.grid(MapArt.rng(4), AREA, 90.0))
	assert_eq(MapArt.scatter_band(MapArt.rng(4), Vector2.ZERO, Vector2(500, 300), 60.0, 40),
		MapArt.scatter_band(MapArt.rng(4), Vector2.ZERO, Vector2(500, 300), 60.0, 40))


func test_scattered_points_stay_inside_their_area() -> void:
	var points := MapArt.scatter(MapArt.rng(1), AREA, 300)
	assert_eq(points.size(), 300)
	for point in points:
		assert_true(AREA.has_point(point), str(point))


func test_scatter_keeps_only_the_points_keep_says_yes_to() -> void:
	var left := func(point: Vector2) -> bool: return point.x < AREA.get_center().x
	var points := MapArt.scatter(MapArt.rng(1), AREA, 300, left)
	assert_between(points.size(), 100, 200, "about half")
	for point in points:
		assert_lt(point.x, AREA.get_center().x)


func test_a_band_scatters_within_half_its_width_of_its_line() -> void:
	var from := Vector2(0, 0)
	var to := Vector2(600, 300)
	for point in MapArt.scatter_band(MapArt.rng(2), from, to, 50.0, 200):
		var on_line := Geometry2D.get_closest_point_to_segment(point, from, to)
		assert_lte(point.distance_to(on_line), 50.01, str(point))


func test_a_grid_puts_one_point_in_a_cell_inside_the_area() -> void:
	var cell := 100.0
	var points := MapArt.grid(MapArt.rng(3), AREA, cell)
	assert_eq(points.size(), 48, "8 by 6 cells")
	var cells := {}
	for point in points:
		assert_true(AREA.has_point(point), str(point))
		cells[Vector2i(((point - AREA.position) / cell).floor())] = true
	assert_eq(cells.size(), points.size(), "never two in a cell")
	assert_gt(points[0].y, points[-1].y, "from the bottom row up")


func test_points_along_an_outline_sit_inset_inside_it() -> void:
	var wall := _wall()
	var points := MapArt.along(wall, 40.0, 10.0)
	assert_gt(points.size(), 20)
	for point in points:
		assert_true(Geometry2D.is_point_in_polygon(point, wall), str(point))
		assert_almost_eq(MapArt.edge_distance(point, wall), 10.0, 0.01, str(point))
	for point in MapArt.along(wall, 40.0, -10.0):
		assert_false(Geometry2D.is_point_in_polygon(point, wall), str(point))


func test_inward_points_into_the_polygon_either_winding() -> void:
	var wall := _wall()
	assert_eq(MapArt.inward(wall, 0), Vector2(0, 1), "under the top edge")
	assert_eq(MapArt.inward(wall, 3), Vector2(-1, 0), "left of the inner corner's edge")
	wall.reverse()
	assert_eq(MapArt.inward(wall, 4), Vector2(0, 1), "the top edge, wound the other way")


func test_the_light_comes_from_the_top_left() -> void:
	assert_gt(MapArt.SHADOW_DIR.x, 0.0)
	assert_gt(MapArt.SHADOW_DIR.y, 0.0)
	assert_almost_eq(MapArt.SHADOW_DIR.length(), 1.0, 0.001)


func test_the_border_rings_the_bounds_without_covering_them() -> void:
	var rects := MapArt.border(AREA, 64.0)
	var total := 0.0
	for rect in rects:
		assert_false(rect.intersects(AREA), str(rect))
		total += rect.get_area()
	assert_almost_eq(total, AREA.grow(64.0).get_area() - AREA.get_area(), 0.01, "no gaps, no overlaps")


func test_facets_gather_triangles() -> void:
	var facets := MapArt.Facets.new()
	facets.triangle(Vector2.ZERO, Vector2.RIGHT, Vector2.DOWN, Color.WHITE)
	facets.quad(Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN, Color.WHITE)
	facets.line(Vector2.ZERO, Vector2(10, 0), 2.0, Color.WHITE)
	assert_eq(facets.count(), 5)
	assert_eq(facets.colors.size(), facets.points.size())


func test_a_rock_and_a_tuft_lie_where_they_are_put() -> void:
	var facets := MapArt.Facets.new()
	MapArt.rock(facets, MapArt.rng(6), Vector2(300, 200), 70.0, Color.GRAY)
	for point in facets.points:
		assert_lte(point.distance_to(Vector2(300, 200)), 70.01, "inside its round wall")
	facets = MapArt.Facets.new()
	MapArt.tuft(facets, MapArt.rng(6), Vector2(50, 50), 16.0, Color.GREEN)
	for point in facets.points:
		assert_lte(point.distance_to(Vector2(50, 50)), 16.0 * 1.2)
		assert_lte(point.y, 50.0 + 2.0, "it grows up")


func test_a_bare_tree_keeps_its_limbs_inside_its_wall() -> void:
	var facets := MapArt.Facets.new()
	MapArt.limbs(facets, MapArt.rng(8), Vector2(300, 200), 70.0, 7, Color.GRAY, Color.WHITE)
	assert_gt(facets.count(), 14, "limbs, forks and light")
	for point in facets.points:
		assert_lte(point.distance_to(Vector2(300, 200)), 70.01, "inside its round wall")


func test_ambience_motes_stay_near_their_spots() -> void:
	var ambience := MapAmbience.new()
	add_child_autofree(ambience)
	var dice := MapArt.rng(8)
	ambience.add(MapAmbience.Kind.FIREFLY, PackedVector2Array([Vector2(100, 100)]), Color.YELLOW, dice)
	ambience.add(MapAmbience.Kind.GLINT, PackedVector2Array([Vector2(200, 100)]), Color.WHITE, dice)
	ambience.add(MapAmbience.Kind.DUST, PackedVector2Array([Vector2(300, 100)]), Color.WHITE, dice)
	assert_eq(ambience.count(), 3)
	for t in range(0, 600, 7):
		var time := t * 0.1
		assert_lte(ambience.place_of(0, time).distance_to(Vector2(100, 100)), MapAmbience.FIREFLY_ROAM.length())
		assert_eq(ambience.place_of(1, time), Vector2(200, 100))
		assert_lte(ambience.place_of(2, time).distance_to(Vector2(300, 100)), MapAmbience.DUST_REACH * 0.5 + 0.01)
		for i in 3:
			assert_between(ambience.glow_of(i, time), 0.0, 1.0)


func test_ambience_is_off_on_low_effects() -> void:
	var ambience := MapAmbience.new()
	add_child_autofree(ambience)
	assert_true(ambience.visible)
	assert_true(ambience.is_processing())
	GameSettings.instance().set_value(&"quality", "low")
	assert_false(ambience.visible)
	assert_false(ambience.is_processing())
	GameSettings.instance().set_value(&"quality", "high")
	assert_true(ambience.visible)
	assert_true(ambience.is_processing())


func test_a_map_adds_its_ambience_off_on_low_effects() -> void:
	var map := LitMap.new()
	add_child_autofree(map)
	assert_true(map.get_node("Ambience").visible)
	GameSettings.instance().set_value(&"quality", "low")
	map = LitMap.new()
	add_child_autofree(map)
	var ambience: MapAmbience = map.get_node("Ambience")
	assert_false(ambience.visible)
	assert_false(ambience.is_processing())


func test_a_map_s_motes_stay_on_it() -> void:
	for act_stage: Array in AMBIENT_STAGES:
		var map := StageMaps.create(act_stage[0], act_stage[1])
		var ambience := map.build_ambience()
		assert_not_null(ambience, str(act_stage))
		if ambience:
			assert_gt(ambience.count(), 0, str(act_stage))
			for i in ambience.count():
				for time: float in [0.0, 7.0, 31.0]:
					assert_true(map.get_bounds().grow(MapAmbience.FIREFLY_ROAM.length()).has_point(ambience.place_of(i, time)),
						"%s: mote %d" % [act_stage, i])
			ambience.free()
		map.free()
