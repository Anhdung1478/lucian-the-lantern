extends GutTest
## Enemies and Lucian walk around walls: straight while the line to the goal
## is clear, else along a path on the navigation the map bakes from its walls.

## A 1200-long wall standing between LUCIAN_AT and BEHIND.
const WALL := [Vector2(1460, 400), Vector2(1540, 400), Vector2(1540, 1600), Vector2(1460, 1600)]
const MAP_SIZE := Vector2(3000, 2000)
const LUCIAN_AT := Vector2(1100, 1000)
const BEHIND := Vector2(1800, 1000)
## Past the wall and out of Lucian's attack range from anywhere on his side.
const FAR_BEHIND := Vector2(2400, 1000)
## The navigation map may sync on a background thread: poll it, at most this
## many physics frames.
const SYNC_FRAMES := 180

var lucian: Lucian
var map: StageMap


## The walled map and Lucian at LUCIAN_AT, under `parent` (this test by default).
func _build(parent: Node = null) -> void:
	if parent == null:
		parent = self
	map = StageMap.new()
	map.size = MAP_SIZE
	map.wall_polygons.append(PackedVector2Array(WALL))
	parent.add_child(map)
	autofree(map)
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	lucian.position = LUCIAN_AT
	parent.add_child(lucian)
	autofree(lucian)


## The walled map with its walls taken in by the navigation map.
func _build_synced() -> void:
	_build()
	var nav_map := map.get_world_2d().navigation_map
	var region := map.navigation.get_rid()
	for frame in SYNC_FRAMES:
		if NavigationServer2D.map_get_iteration_id(nav_map) > 0 and NavigationServer2D.map_get_closest_point_owner(nav_map, LUCIAN_AT) == region:
			return
		await wait_physics_frames(1)
	fail_test("the navigation map never took in the walls")


func _minion(at: Vector2, parent: Node = null) -> Minion:
	var minion := Minion.new()
	minion.setup(load("res://data/enemies/melee_minion.tres"), 1, 1, lucian)
	minion.position = at
	(parent if parent else self).add_child(minion)
	autofree(minion)
	return minion


func test_a_melee_minion_walks_around_the_wall_to_lucian() -> void:
	await _build_synced()
	var minion := _minion(BEHIND)
	var reached: bool = await wait_until(func() -> bool:
		return minion.distance_to_target() <= minion.attack_range + Lucian.HIT_RADIUS + 5.0, 8.0)
	assert_true(reached, "it reached Lucian within 8 s")
	assert_gt(minion.path_follower.queries, 0, "it followed a path")


func test_lucian_walks_around_the_wall_to_a_point_behind_it() -> void:
	await _build_synced()
	lucian.command_move(BEHIND)
	var arrived: bool = await wait_until(func() -> bool: return lucian._order == Lucian.Order.NONE, 8.0)
	assert_true(arrived, "the move ended")
	assert_lt(lucian.global_position.distance_to(BEHIND), 5.0)


func test_a_click_inside_the_wall_ends_at_the_closest_reachable_point() -> void:
	await _build_synced()
	# Nearer his side of the wall, whose face is at x = 1460.
	lucian.command_move(Vector2(1480, 1000))
	var arrived: bool = await wait_until(func() -> bool: return lucian._order == Lucian.Order.NONE, 4.0)
	assert_true(arrived, "he doesn't push against the wall forever")
	assert_lt(lucian.global_position.distance_to(Vector2(1424, 1000)), 10.0)


func test_attack_move_chases_the_nearest_enemy_around_the_wall() -> void:
	await _build_synced()
	# Lucian can't be fought, so the minion stands still behind the wall.
	lucian.invulnerable = true
	var minion := _minion(FAR_BEHIND)
	lucian.command_attack_move(LUCIAN_AT)
	assert_eq(lucian._target, minion)
	var shot: bool = await wait_until(func() -> bool: return minion.hp < minion.max_hp, 8.0)
	assert_true(shot, "he went around the wall and shot it")
	assert_gt(lucian.path_follower.queries, 0, "he followed a path")


func test_with_a_clear_line_both_walk_straight() -> void:
	await _build_synced()
	var minion := _minion(Vector2(500, 1000))
	var goal := Vector2(1100, 1300)
	lucian.command_move(goal)
	await wait_seconds(1.2)
	assert_lt(lucian.global_position.distance_to(goal), 5.0)
	assert_gt(minion.global_position.x, 650.0, "the minion walked")
	assert_eq(lucian.path_follower.queries, 0)
	assert_eq(minion.path_follower.queries, 0)


func test_before_the_first_sync_everyone_walks_straight() -> void:
	var viewport := SubViewport.new()
	add_child_autofree(viewport)
	var nav_map := viewport.world_2d.navigation_map
	# Never synced: as at the very start of a stage.
	NavigationServer2D.map_set_active(nav_map, false)
	_build(viewport)
	var minion := _minion(BEHIND, viewport)
	lucian.command_move(BEHIND)
	await wait_seconds(0.6)
	assert_eq(NavigationServer2D.map_get_iteration_id(nav_map), 0, "still not synced")
	assert_gt(lucian.global_position.x, LUCIAN_AT.x + 150.0, "Lucian walked at the wall")
	assert_almost_eq(lucian.global_position.y, LUCIAN_AT.y, 1.0, "straight")
	assert_lt(minion.global_position.x, BEHIND.x - 100.0, "the minion walked at the wall")
	assert_eq(lucian.path_follower.queries, 0)
	assert_eq(minion.path_follower.queries, 0)
	assert_engine_error_count(0)


func test_every_map_bakes_walkable_ground() -> void:
	for act_stage in [[0, 0], [1, 1], [2, 1], [2, 2], [2, 3]]:
		var stage_map := StageMaps.create(act_stage[0], act_stage[1])
		add_child_autofree(stage_map)
		assert_gt(stage_map.navigation.navigation_polygon.get_polygon_count(), 0, str(act_stage))
	assert_engine_error_count(0)
