extends GutTest

const STAGES := [[1, 1], [2, 1], [2, 2], [2, 3], [3, 1], [3, 2], [3, 3], [3, 4], [3, 5], [4, 1], [4, 2], [4, 3]]
## The navigation map may sync on a background thread: poll it, at most this
## many physics frames.
const SYNC_FRAMES := 180
## How far apart the samples along a throw are, checking what it flies over.
const SAMPLE_STEP := 10.0


func test_every_point_is_walkable_and_inside() -> void:
	for act_stage in STAGES:
		var map := StageMaps.create(act_stage[0], act_stage[1])
		var points: Array[Vector2] = [map.lucian_start, map.merchant_point, map.boss_point]
		if act_stage[0] == 1:
			points.append(map.ally_start)
		points.append_array(map.spawn_points)
		points.append_array(map.camps.values())
		assert_false(map.spawn_points.is_empty(), str(act_stage))
		for point in points:
			assert_true(map.is_walkable(point), "%s: %s" % [act_stage, point])
		map.free()


func test_mid_lane_has_two_jungle_walls() -> void:
	var map := MidLaneMap.new()
	assert_eq(map.wall_polygons.size(), 2)
	map.free()


func test_act_2_stages_differ() -> void:
	assert_eq(TrainingGroundMap.pillars(1).size(), 6)
	assert_eq(TrainingGroundMap.pillars(2).size(), 8)
	assert_eq(TrainingGroundMap.pillars(3).size(), 10)
	var first := TrainingGroundMap.new(1)
	var second := TrainingGroundMap.new(2)
	assert_lt(first.spawn_points.size(), second.spawn_points.size())
	first.free()
	second.free()


func test_lucian_cannot_walk_into_the_jungle() -> void:
	var map := MidLaneMap.new()
	add_child_autofree(map)
	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
	lucian.position = map.lucian_start
	add_child_autofree(lucian)
	await wait_physics_frames(1)
	lucian.command_move(map.lucian_start + map.across() * 900.0)
	await wait_seconds(1.8)
	assert_true(map.is_walkable(lucian.global_position, 0.0))


func test_training_keeps_its_arena_and_dummy() -> void:
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	add_child_autofree(stage)
	await wait_physics_frames(2)
	assert_is(stage.arena, TestArena)
	assert_not_null(stage.dummy)


func test_an_act_stage_swaps_the_map_and_drops_the_dummy() -> void:
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	var run := StageSetup.new()
	run.act = 2
	run.stage = 1
	run.stage_id = "2-1"
	stage.setup(run)
	add_child_autofree(stage)
	await wait_physics_frames(2)
	assert_is(stage.arena, TrainingGroundMap)
	assert_null(stage.dummy)
	assert_eq(stage.lucian.global_position, stage.arena.lucian_start)
	assert_eq(get_tree().get_nodes_in_group(&"enemies").size(), 0)


## Every point opens onto the paths: the navigation reaches it from the start.
func test_every_point_is_reachable_from_the_start() -> void:
	for act_stage in STAGES:
		var map := StageMaps.create(act_stage[0], act_stage[1])
		add_child(map)
		var nav_map := map.get_world_2d().navigation_map
		var synced := false
		for frame in SYNC_FRAMES:
			if NavigationServer2D.map_get_iteration_id(nav_map) > 0 \
					and NavigationServer2D.map_get_closest_point_owner(nav_map, map.lucian_start) == map.navigation.get_rid():
				synced = true
				break
			await wait_physics_frames(1)
		assert_true(synced, "%s: the navigation map took in the walls" % [act_stage])
		var points: Array[Vector2] = [map.merchant_point, map.boss_point]
		points.append_array(map.spawn_points)
		points.append_array(map.camps.values())
		for point in points:
			var path := NavigationServer2D.map_get_path(nav_map, map.lucian_start, point, true)
			assert_false(path.is_empty(), "%s: a path to %s" % [act_stage, point])
			if not path.is_empty():
				assert_lt(path[path.size() - 1].distance_to(point), 2.0, "%s: %s opens onto the paths" % [act_stage, point])
		map.free()
		await wait_physics_frames(1)


func test_no_wall_polygon_is_a_hole() -> void:
	for act_stage in STAGES:
		var map := StageMaps.create(act_stage[0], act_stage[1])
		for polygon in map.wall_polygons:
			assert_false(Geometry2D.is_polygon_clockwise(polygon), "%s: a hole of %d points" % [act_stage, polygon.size()])
		map.free()


func test_the_jungle_loops_keep_their_inner_jungle_as_its_own_wall() -> void:
	var map := JungleMap.new(1)
	var low := (JungleMap.MID_Y + JungleMap.LOW_Y) * 0.5
	for side: Array in [[JungleMap.LEFT_X, JungleMap.RIVER_X], [JungleMap.RIVER_X, JungleMap.RIGHT_X]]:
		var inner := Vector2((side[0] + side[1]) * 0.5, low)
		var holding := map.wall_polygons.filter(func(polygon: PackedVector2Array) -> bool:
			return Geometry2D.is_point_in_polygon(inner, polygon))
		assert_eq(holding.size(), 1, "%s is jungle, in one wall" % inner)
		# The paths round the loop stay open.
		for point: Vector2 in [Vector2(side[0], low), Vector2(side[1], low), Vector2(inner.x, JungleMap.MID_Y), Vector2(inner.x, JungleMap.LOW_Y)]:
			assert_true(map.is_walkable(point), "%s on the loop is open" % point)
	map.free()


func test_the_jungle_paths_reach_the_map_edge_twice() -> void:
	var map := JungleMap.new(1)
	assert_true(map.is_walkable(Vector2(1, JungleMap.MID_Y), 0.0))
	assert_true(map.is_walkable(Vector2(map.size.x - 1, JungleMap.MID_Y), 0.0))
	map.free()


func test_the_dragon_pit_is_round_with_rocks_in_a_ring() -> void:
	var map := DragonPitMap.new()
	var middle := map.size * 0.5
	assert_eq(map.size, Vector2(3600, 3600))
	assert_eq(map.wall_polygons.size(), DragonPitMap.WALL_PIECES)
	assert_eq(map.wall_circles.size(), DragonPitMap.ROCKS)
	for rock in map.wall_circles:
		assert_almost_eq(Vector2(rock.x, rock.y).distance_to(middle), DragonPitMap.ROCK_RING, 0.5)
	for i in 16:
		var direction := Vector2.from_angle(TAU * i / 16)
		assert_true(map.is_walkable(middle + direction * (DragonPitMap.FLOOR_RADIUS - 50.0), 0.0), "the floor reaches its rim")
		assert_false(map.is_walkable(middle + direction * (DragonPitMap.FLOOR_RADIUS + 30.0), 0.0), "rock past the rim")
	assert_true(map.camps.is_empty())
	assert_eq(map.spawn_points.size(), 3, "north, east and west")
	assert_eq(map.boss_point, middle)
	assert_gt(map.lucian_start.y, middle.y, "Lucian starts at the south")
	assert_gt(map.merchant_point.y, middle.y)
	map.free()


## No wave comes in next to Lucian's start (out of his and Gromp's range).
func test_the_dragon_pit_spawns_far_from_the_start() -> void:
	var map := DragonPitMap.new()
	for point in map.spawn_points:
		assert_gte(point.distance_to(map.lucian_start), 1000.0, str(point))
	map.free()


func test_act_3_stages_pick_their_maps() -> void:
	for stage in range(1, 5):
		var map := StageMaps.create(3, stage)
		assert_is(map, JungleMap)
		assert_eq((map as JungleMap).stage, stage)
		map.free()
	var pit := StageMaps.create(3, 5)
	assert_is(pit, DragonPitMap)
	pit.free()


func test_the_jungle_camps_and_points() -> void:
	var map := JungleMap.new(1)
	for camp: StringName in [&"raptors", &"wolves", &"krugs", &"gromp", &"blue", &"red", &"scuttle", &"drake"]:
		assert_true(map.camps.has(camp), camp)
	assert_eq(map.camps[&"drake"], map.boss_point, "the drake pit")
	assert_lt(map.camps[&"raptors"].x, map.size.x * 0.5)
	assert_lt(map.camps[&"gromp"].y, map.size.y * 0.5)
	assert_gt(map.camps[&"krugs"].x, map.size.x * 0.5)
	assert_gt(map.lucian_start.y, map.size.y * 0.5, "Lucian starts at the bottom")
	map.free()


## Each stage's terrain: none in 3-1 and 3-3; lava and Blast Cones in 3-2;
## shallow water and Honeyfruit in 3-4. All of it on the floor.
func test_terrain_sits_on_the_floor() -> void:
	var expected := {1: [0, 0, 0, 0], 2: [5, 0, 0, 4], 3: [0, 0, 0, 0], 4: [0, 1, 4, 0]}
	for stage: int in expected:
		var map := JungleMap.new(stage)
		var counts := [0, 0, 0, 0]
		for node in map.build_terrain(null):
			if node is HazardZone:
				var zone := node as HazardZone
				counts[0 if zone.effect == HazardZone.Effect.BURN else 1] += 1
				for point in zone.outline():
					assert_true(map.is_walkable(point, 0.0), "3-%d: %s on the floor" % [stage, point])
			else:
				counts[2 if node is Honeyfruit else 3] += 1
				assert_true(map.is_walkable(node.position), "3-%d: %s on the floor" % [stage, node.position])
			node.free()
		assert_eq(counts, expected[stage], "3-%d: [lava, water, Honeyfruit, Blast Cones]" % stage)
		map.free()


## 3-2's pit keeps its lava at the back, behind the drake: the middle of the
## pit and the floor in front of it stay open for the fight.
func test_the_pit_lava_stays_behind_the_drake() -> void:
	var in_pit := 0
	for pool in JungleMap.LAVA_POOLS:
		var at := Vector2(pool.x, pool.y)
		if at.distance_to(JungleMap.PIT) >= JungleMap.PIT_RADIUS:
			continue
		in_pit += 1
		assert_lt(at.y, JungleMap.PIT.y, "%s is behind the pit's middle" % at)
		assert_gt(at.distance_to(JungleMap.PIT) - pool.z, 150.0, "%s leaves the middle open" % at)
	assert_eq(in_pit, 2)


func test_lava_is_40_magic_a_second_and_water_slows_25_percent() -> void:
	for stage in [2, 4]:
		var map := JungleMap.new(stage)
		for node in map.build_terrain(null):
			if node is HazardZone:
				var zone := node as HazardZone
				if zone.effect == HazardZone.Effect.BURN:
					assert_eq(zone.dps, 40.0)
					assert_eq(zone.damage_type, DamageInfo.Type.MAGIC)
					assert_between(zone.radius, 140.0, 220.0)
				else:
					assert_eq(zone.slow, 0.25)
				assert_eq(zone.lifetime, 0.0, "for good")
			node.free()
		map.free()


## Each Blast Cone stands beside a clump no more than 500 thick: standing
## by it, Lucian is thrown over the clump, always onto walkable ground.
func test_blast_cones_throw_lucian_over_a_clump_to_walkable_ground() -> void:
	var map := JungleMap.new(2)
	for node in map.build_terrain(null):
		if node is BlastCone:
			var crossings := 0
			for i in 16:
				var from: Vector2 = node.position + Vector2.from_angle(TAU * i / 16) * 150.0
				if not map.is_walkable(from, Lucian.HIT_RADIUS):
					continue
				var to := BlastCone.landing_spot(node.position, from, map)
				if to == from:
					continue
				assert_true(map.is_walkable(to, BlastCone.LANDING_MARGIN), "%s lands on %s" % [node.position, to])
				var jungle := _jungle_along(map, from, to)
				if jungle > 0.0 and jungle <= 500.0:
					crossings += 1
			assert_gt(crossings, 0, "%s throws over a clump" % node.position)
		node.free()
	map.free()


func test_an_act_3_stage_puts_its_terrain_in_the_world() -> void:
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), 3, 2))
	add_child_autofree(stage)
	await wait_physics_frames(2)
	assert_is(stage.arena, JungleMap)
	var zones := stage.get_node("World").get_children().filter(func(node: Node) -> bool: return node is HazardZone)
	var cones := get_tree().get_nodes_in_group(&"plants")
	assert_eq(zones.size(), 5)
	assert_eq(cones.size(), 4)
	for cone: BlastCone in cones:
		assert_eq(cone.lucian, stage.lucian)
		assert_eq(cone.arena, stage.arena)
	for zone: HazardZone in zones:
		assert_eq(zone.lucian, stage.lucian)
	assert_eq(get_tree().get_nodes_in_group(&"enemies").size(), 0, "plants are not enemies")
	assert_lt(stage.arena.z_index, zones[0].z_index, "the lava draws over the floor")
	assert_lt(zones[0].z_index, stage.lucian.z_index, "and under the units")


## How much of the line from `from` to `to` runs through walls.
func _jungle_along(map: StageMap, from: Vector2, to: Vector2) -> float:
	var length := 0.0
	var steps := ceili(from.distance_to(to) / SAMPLE_STEP)
	for i in steps:
		if not map.is_walkable(from.lerp(to, (i + 0.5) / steps), 0.0):
			length += from.distance_to(to) / steps
	return length


func test_act_4_is_the_dark_mid_lane() -> void:
	for stage in range(1, 4):
		var map := StageMaps.create(4, stage)
		assert_is(map, DarkMidLaneMap, str(stage))
		assert_eq(map.wall_polygons.size(), 2)
		assert_eq(map.lane_color, Color("37313f"))
		assert_eq(map.jungle_color, Color("120f1a"))
		assert_eq(map.jungle_edge, Color("5e4285"))
		assert_eq(map.tree_color, Color("0c0a12"))
		assert_eq(map.river_color, Color("2a1f45"))
		assert_eq(map.river_edge, Color("9467d0"))
		assert_eq(map.rock_color, Color("4a4554"))
		map.free()


## Still dark (each color darker than Act 1's lane), but the lane and the
## river stand apart from the jungle, and the rocks from the lane, so the
## dark units have something to show on.
func test_the_dark_lane_reads_against_its_jungle() -> void:
	var map := DarkMidLaneMap.new()
	var light := MidLaneMap.new()
	for color: Color in [map.lane_color, map.river_color, map.rock_color, map.jungle_edge]:
		assert_lt(color.get_luminance(), light.lane_color.get_luminance(), "%s stays dark" % color.to_html(false))
	assert_gt(map.lane_color.get_luminance() - map.jungle_color.get_luminance(), 0.12, "lane vs jungle")
	assert_gt(map.river_color.get_luminance() - map.jungle_color.get_luminance(), 0.07, "river vs jungle")
	assert_gt(map.rock_color.get_luminance() - map.lane_color.get_luminance(), 0.05, "rocks vs lane")
	assert_gt(map.jungle_edge.get_luminance() - map.jungle_color.get_luminance(), 0.15, "the jungle's edge")
	map.free()
	light.free()


func test_the_dark_lane_keeps_act_1s_layout_and_act_1_keeps_its_colors() -> void:
	var light := MidLaneMap.new()
	var dark := DarkMidLaneMap.new()
	assert_eq(dark.boss_point, light.boss_point)
	assert_eq(dark.lucian_start, light.lucian_start)
	assert_eq(dark.spawn_points, light.spawn_points)
	assert_eq(dark.wall_polygons, light.wall_polygons)
	assert_eq(light.lane_color, Color("5b5244"))
	assert_eq(light.jungle_color, Color("1d3a24"))
	assert_eq(light.river_edge, Color("6fb4d8"))
	light.free()
	dark.free()
