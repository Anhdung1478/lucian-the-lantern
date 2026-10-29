extends GutTest

const STAGES := [[1, 1], [2, 1], [2, 2], [2, 3], [3, 1], [3, 2], [3, 3], [3, 4], [3, 5], [4, 1], [4, 2], [4, 3], [5, 1], [5, 2], [5, 3], [5, 4], [5, 5],
	[6, 1], [6, 2], [6, 3], [6, 4], [6, 5]]
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


# --- Act 6's abyss (Layers.CHASM), on small maps built here ---------------

const CHASM_MAP := Vector2(3000, 2000)
## Across the whole height: nothing on foot gets from one side to the other.
const CHASM_STRIP := [Vector2(1400, 0), Vector2(1600, 0), Vector2(1600, 2000), Vector2(1400, 2000)]
## A block in the middle that paths go around.
const CHASM_BLOCK := [Vector2(1400, 400), Vector2(1600, 400), Vector2(1600, 1600), Vector2(1400, 1600)]


func _chasm_map(chasm: Array) -> StageMap:
	var map := StageMap.new()
	map.size = CHASM_MAP
	map.chasm_polygons.append(PackedVector2Array(chasm))
	add_child_autofree(map)
	return map


func _lucian_at(at: Vector2) -> Lucian:
	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
	lucian.position = at
	add_child_autofree(lucian)
	return lucian


## Waits until the navigation map has taken in `map`'s region around `at`.
func _synced(map: StageMap, at: Vector2) -> void:
	var nav_map := map.get_world_2d().navigation_map
	for frame in SYNC_FRAMES:
		if NavigationServer2D.map_get_iteration_id(nav_map) > 0 \
				and NavigationServer2D.map_get_closest_point_owner(nav_map, at) == map.navigation.get_rid():
			return
		await wait_physics_frames(1)
	fail_test("the navigation map never took in the abyss")


func test_the_chasm_layer_is_named() -> void:
	assert_eq(Layers.CHASM, 32)
	assert_eq(ProjectSettings.get_setting("layer_names/2d_physics/layer_6"), "chasm")


## Only Act 6 has an abyss and ledges, only Act 5 the mist.
func test_maps_have_no_abyss_ledges_or_mist_by_default() -> void:
	for act_stage in STAGES:
		var map := StageMaps.create(act_stage[0], act_stage[1])
		assert_eq(map.chasm_polygons.is_empty(), act_stage[0] != 6, str(act_stage))
		if act_stage[0] != 6:
			assert_true(map.ledge_points.is_empty(), str(act_stage))
		assert_eq(map.mist.is_empty(), act_stage[0] != 5, str(act_stage))
		map.free()


## A collision polygon or a nav obstruction can't have a hole, nor cross
## itself: the abyss is several simple polygons.
func test_no_chasm_polygon_is_a_hole_or_crosses_itself() -> void:
	for act_stage in STAGES:
		var map := StageMaps.create(act_stage[0], act_stage[1])
		for polygon in map.chasm_polygons:
			assert_gte(polygon.size(), 3, str(act_stage))
			assert_false(Geometry2D.is_polygon_clockwise(polygon), "%s: a hole of %d points" % [act_stage, polygon.size()])
			assert_false(_crosses_itself(polygon), "%s: a polygon of %d points crosses itself" % [act_stage, polygon.size()])
		map.free()


## Two edges of `polygon` that aren't neighbors meet.
func _crosses_itself(polygon: PackedVector2Array) -> bool:
	var count := polygon.size()
	for i in count:
		for j in range(i + 2, count):
			if i == 0 and j == count - 1:
				continue
			if Geometry2D.segment_intersects_segment(polygon[i], polygon[(i + 1) % count], polygon[j], polygon[(j + 1) % count]) != null:
				return true
	return false


func test_the_abyss_is_a_body_on_its_own_layer_and_not_walkable() -> void:
	var map := _chasm_map(CHASM_BLOCK)
	var chasm: StaticBody2D = map.get_node("Chasm")
	assert_eq(chasm.collision_layer, Layers.CHASM)
	assert_eq(chasm.collision_mask, 0)
	assert_eq(chasm.get_child_count(), 1)
	assert_eq((map.get_node("Walls") as StaticBody2D).collision_layer, Layers.WORLD, "the walls keep theirs")
	assert_false(map.is_walkable(Vector2(1500, 1000), 0.0), "in it")
	assert_false(map.is_walkable(Vector2(1380, 1000)), "within the margin of its edge")
	assert_true(map.is_walkable(Vector2(1380, 1000), 10.0), "past a small margin")
	assert_true(map.is_walkable(Vector2(1000, 1000)))


func test_lucian_cannot_walk_into_the_abyss() -> void:
	var map := _chasm_map(CHASM_STRIP)
	var lucian := _lucian_at(Vector2(1000, 1000))
	await _synced(map, Vector2(1000, 1000))
	lucian.command_move(Vector2(2000, 1000))
	await wait_seconds(2.0)
	assert_lt(lucian.global_position.x, 1400.0 - Lucian.HIT_RADIUS + 1.0, "at its edge at most")
	assert_gt(lucian.global_position.x, 1250.0, "he walked up to it")


func test_a_displacement_stops_at_the_abyss() -> void:
	_chasm_map(CHASM_STRIP)
	var lucian := _lucian_at(Vector2(1000, 1000))
	await wait_physics_frames(2)
	lucian.displace(Vector2(2000, 1000), 1500.0)
	assert_eq(lucian.collision_mask, Layers.WORLD | Layers.CHASM)
	await wait_seconds(0.9)
	assert_false(lucian.is_displaced())
	assert_lt(lucian.global_position.x, 1400.0 - Lucian.HIT_RADIUS + 1.0, "pulled to its edge, not into it")
	assert_gt(lucian.global_position.x, 1300.0)
	assert_eq(lucian.collision_mask, Layers.WORLD | Layers.ENEMY_BODY | Layers.CHASM)


func test_a_dash_stops_at_the_abyss() -> void:
	_chasm_map(CHASM_STRIP)
	var lucian := _lucian_at(Vector2(1200, 1000))
	await wait_physics_frames(2)
	lucian.start_dash(Vector2.RIGHT, 425.0, 1500.0)
	assert_eq(lucian.collision_mask, Layers.WORLD | Layers.CHASM, "through enemies, not over the abyss")
	await wait_seconds(0.5)
	assert_false(lucian.is_dashing())
	assert_lt(lucian.global_position.x, 1400.0 - Lucian.HIT_RADIUS + 1.0)
	assert_gt(lucian.global_position.x, 1300.0)


func test_flash_cannot_land_on_the_abyss() -> void:
	_chasm_map(CHASM_STRIP)
	var lucian := _lucian_at(Vector2(1200, 1000))
	await wait_physics_frames(2)
	assert_eq(lucian.collision_mask, Layers.WORLD | Layers.ENEMY_BODY | Layers.CHASM, "his walking mask")
	assert_false(lucian.fits_at(Vector2(1500, 1000)))
	assert_true(lucian.use_summoner(0, Vector2(1500, 1000)))
	assert_lt(lucian.global_position.x, 1400.0 - Lucian.HIT_RADIUS + 0.5, "it stepped back to the edge")
	assert_gt(lucian.global_position.x, 1300.0, "it still blinked")


func test_an_enemy_bolt_flies_over_the_abyss() -> void:
	_chasm_map(CHASM_STRIP)
	var lucian := _lucian_at(Vector2(2000, 1000))
	await wait_physics_frames(2)
	var bolt := EnemyProjectile.new()
	bolt.launch(Vector2(1000, 1000), Vector2.RIGHT, DamageInfo.create(20.0, DamageInfo.Type.MAGIC, &"test"), lucian)
	bolt.speed = 1500.0
	bolt.max_range = 1500.0
	var hit := [0]
	bolt.hit_lucian.connect(func() -> void: hit[0] += 1)
	add_child_autofree(bolt)
	await wait_physics_frames(50)
	assert_eq(hit[0], 1, "over the abyss to Lucian")


func test_an_enemy_body_stops_at_the_abyss() -> void:
	_chasm_map(CHASM_STRIP)
	var lucian := _lucian_at(Vector2(2000, 1000))
	await wait_physics_frames(2)
	# Untouchable, so the minion thinks nothing: it walks only where told,
	# straight in, with no path to stop it short.
	lucian.invulnerable = true
	var minion := Minion.new()
	minion.setup(load("res://data/enemies/melee_minion.tres"), 1, 1, lucian)
	minion.position = Vector2(1250, 1000)
	add_child_autofree(minion)
	await wait_physics_frames(1)
	for frame in 60:
		minion.walk(Vector2.RIGHT, 1.0 / 60.0)
		await wait_physics_frames(1)
	assert_lt(minion.global_position.x, 1400.0, "its body stops at the edge")
	assert_gt(minion.global_position.x, 1300.0, "it walked up to it")


func test_a_path_goes_around_the_abyss() -> void:
	var map := _chasm_map(CHASM_BLOCK)
	await _synced(map, Vector2(1100, 1000))
	var path := NavigationServer2D.map_get_path(map.get_world_2d().navigation_map, Vector2(1100, 1000), Vector2(1900, 1000), true)
	assert_gt(path.size(), 2, "around, not straight")
	if path.is_empty():
		return
	assert_lt(path[path.size() - 1].distance_to(Vector2(1900, 1000)), 2.0)
	for i in path.size() - 1:
		var leg := PackedVector2Array([path[i], path[i + 1]])
		assert_true(Geometry2D.intersect_polyline_with_polygon(leg, PackedVector2Array(CHASM_BLOCK)).is_empty(), "leg %d stays off it" % i)


func test_an_enemy_walks_around_the_abyss_to_lucian() -> void:
	var map := _chasm_map(CHASM_BLOCK)
	var lucian := _lucian_at(Vector2(1100, 1000))
	await _synced(map, Vector2(1100, 1000))
	var minion := Minion.new()
	minion.setup(load("res://data/enemies/melee_minion.tres"), 1, 1, lucian)
	minion.position = Vector2(1900, 1000)
	add_child_autofree(minion)
	var block := PackedVector2Array(CHASM_BLOCK)
	var entered := false
	var reached := false
	for frame in 600:
		await wait_physics_frames(1)
		lucian.hp = lucian.stats.max_hp
		entered = entered or Geometry2D.is_point_in_polygon(minion.global_position, block)
		if minion.distance_to_target() <= minion.attack_range + Lucian.HIT_RADIUS + 5.0:
			reached = true
			break
	assert_true(reached, "it reached Lucian within 10 s")
	assert_false(entered, "never on the abyss")
	assert_gt(minion.path_follower.queries, 0, "the abyss blocked its line: it took a path")


# --- Act 5: the dead forest ---------------------------------------------


func _forest(stage: int) -> DeadForestMap:
	return StageMaps.create(5, stage) as DeadForestMap


func test_act_5_stages_are_the_dead_forest() -> void:
	for stage in range(1, 6):
		var map := _forest(stage)
		assert_not_null(map, str(stage))
		assert_eq(map.size, Vector2(5400, 3400))
		assert_eq(map.lucian_start, Vector2(500, 1700))
		assert_eq(map.merchant_point, Vector2(2500, 1700))
		assert_eq(map.spawn_points.size(), 4)
		map.free()


func test_the_forest_camps_and_boss_spots_come_stage_by_stage() -> void:
	var expected := {
		1: {}, 2: {&"maokai": Vector2(3900, 1700)}, 3: {&"nest": Vector2(5000, 900)},
		4: {&"elise": Vector2(3900, 1400), &"nest": Vector2(5000, 2500)}, 5: {&"nest": Vector2(5000, 900)},
	}
	for stage in range(1, 6):
		var map := _forest(stage)
		assert_eq(map.camps, expected[stage], str(stage))
		map.free()
	for pair in [[5, Vector2(4300, 1700)], [2, Vector2(3900, 1700)], [4, Vector2(3900, 1400)]]:
		var map := _forest(pair[0])
		assert_eq(map.boss_point, pair[1], str(pair[0]))
		map.free()


func test_the_forest_has_the_planned_tree_and_mist_counts() -> void:
	var trees := [14, 16, 18, 18, 10]
	var mist := [2, 3, 3, 4, 2]
	for stage in range(1, 6):
		assert_eq(DeadForestMap.trees(stage).size(), trees[stage - 1], "trees %d" % stage)
		var map := _forest(stage)
		assert_eq(map.mist.size(), mist[stage - 1], "mist %d" % stage)
		for bank in map.mist:
			assert_between(bank.z, 380.0, 520.0)
		map.free()


func test_the_forest_trees_keep_their_gaps() -> void:
	for stage in range(1, 6):
		var trees := DeadForestMap.trees(stage)
		var clear := DeadForestMap.keep_clear(stage)
		var ring := DeadForestMap.trunks(stage)
		assert_eq(trees, DeadForestMap.trees(stage), "a fixed list")
		for i in trees.size():
			var tree := trees[i]
			var at := Vector2(tree.x, tree.y)
			assert_between(tree.z, 45.0, 90.0)
			for point in clear:
				assert_gte(at.distance_to(point) - tree.z, 220.0, "%d: tree %s near %s" % [stage, at, point])
			for j in range(i + 1, trees.size()):
				assert_gte(at.distance_to(Vector2(trees[j].x, trees[j].y)) - tree.z - trees[j].z, 160.0, "%d: trees %d and %d" % [stage, i, j])
			for trunk in ring:
				assert_gte(at.distance_to(Vector2(trunk.x, trunk.y)) - tree.z - trunk.z, 160.0, "%d: a tree by the dead tree" % stage)


func test_the_forest_mist_stays_off_every_point() -> void:
	for stage in range(1, 6):
		var map := _forest(stage)
		var points: Array[Vector2] = [map.lucian_start, map.merchant_point, map.boss_point]
		points.append_array(map.camps.values())
		for point in points:
			for bank in map.mist:
				assert_gt(point.distance_to(Vector2(bank.x, bank.y)), bank.z, "%d: %s in mist" % [stage, point])
		map.free()


func test_maokais_dead_tree_is_a_ring_open_to_the_west() -> void:
	var ring := DeadForestMap.trunks(2)
	assert_eq(ring.size(), 6)
	for stage in [1, 3, 4, 5]:
		assert_true(DeadForestMap.trunks(stage).is_empty(), str(stage))
	var map := _forest(2)
	for trunk in ring:
		assert_true(map.wall_circles.has(trunk))
	# The camp and its jitter stay walkable, and the west side is open.
	for jitter in [Vector2.ZERO, Vector2(90, 90), Vector2(-90, -90), Vector2(90, -90), Vector2(-90, 90)]:
		assert_true(map.is_walkable(Vector2(3900, 1700) + jitter), str(jitter))
	var west := Vector2(3900, 1700) + Vector2(-DeadForestMap.TRUNK_RING, 0)
	assert_true(map.is_walkable(west), "the gap")
	var east := Vector2(3900, 1700) + Vector2(DeadForestMap.TRUNK_RING, 0)
	assert_false(map.is_walkable(east), "a trunk")
	map.free()


func test_the_graveyard_and_the_nest_exist_only_when_planned() -> void:
	for stage in range(1, 6):
		var map := _forest(stage)
		assert_eq(DeadForestMap.has_graveyard(stage), stage == 5)
		assert_eq(map.camps.has(&"nest"), stage >= 3, str(stage))
		var graves := DeadForestMap.graves()
		var in_map := 0
		for grave in graves:
			if map.wall_polygons.has(grave):
				in_map += 1
		assert_eq(in_map, graves.size() if stage == 5 else 0, "graves in %d" % stage)
		map.free()
	for rect in DeadForestMap.tombstones():
		assert_eq(rect.size, Vector2(40, 70))
		assert_gt(rect.position.x, DeadForestMap.GRAVEYARD_X)
	assert_eq(DeadForestMap.CRYPT_SLABS.size(), 2)
	for tree in DeadForestMap.trees(5):
		assert_lt(tree.x + tree.z, DeadForestMap.GRAVEYARD_X, "5-5's trees stand west of the graveyard")


func test_the_forest_has_a_ragged_tree_line_top_and_bottom() -> void:
	var map := _forest(1)
	assert_false(map.is_walkable(Vector2(2000, 100)))
	assert_false(map.is_walkable(Vector2(2000, 3300)))
	assert_true(map.is_walkable(Vector2(2000, 700)))
	map.free()


## The mean luminance of enemy `id`'s art over its solid pixels (alpha over
## 0.9), each pixel times `shade` first (the art as the game tints it).
func _art_luminance(id: StringName, shade := Color.WHITE) -> float:
	var path := (load("res://data/enemies/%s.tres" % id) as EnemyData).art.resource_path
	var image := Image.new()
	assert_eq(image.load_svg_from_string(FileAccess.get_file_as_string(path)), OK, path)
	var total := 0.0
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a > 0.9:
				total += (pixel * shade).get_luminance()
				count += 1
	return total / maxi(count, 1)


## The visual pass: spiderlings, most of every Act 5 wave, were dark grey on
## the dark forest floor, seen only by their health bars. Their art stands
## off the floor now; veiled, they are still a dark silhouette.
func test_a_spiderling_reads_on_the_forest_floor() -> void:
	var ground := DeadForestMap.FLOOR_COLOR.get_luminance()
	assert_gt(_art_luminance(WavePlan.SPIDERLING) - ground, 0.08, "lighter than the floor")
	assert_lt(_art_luminance(WavePlan.SPIDERLING, EnemyUnit.VEIL_SHADE), ground - 0.1, "veiled: a dark silhouette")


# --- Act 6: Thresh's domain ----------------------------------------------

const DOMAIN_SIZE := Vector2(5600, 3400)
## A spawn's jitter keeps a body this far off the abyss: the plan's Act 6
## wave enemies are r 42 at most.
const BODY_MARGIN := 45.0
const PLATFORM_MIDDLE := Vector2(2800, 1700)
const PLATFORM_RADIUS := 1400.0


func _domain(stage: int) -> ThreshDomainMap:
	return StageMaps.create(6, stage) as ThreshDomainMap


func _in_abyss(map: StageMap, point: Vector2) -> bool:
	for polygon in map.chasm_polygons:
		if Geometry2D.is_point_in_polygon(point, polygon):
			return true
	return false


func _in_any(point: Vector2, polygons: Array[PackedVector2Array]) -> bool:
	for polygon in polygons:
		if Geometry2D.is_point_in_polygon(point, polygon):
			return true
	return false


## The whole bridges of a stage: those whose middle is walkable.
func _whole_bridges(map: StageMap) -> Array[Vector3]:
	var whole: Array[Vector3] = []
	for bridge in ThreshDomainMap.BRIDGES:
		if map.is_walkable(Vector2((bridge.x + bridge.y) * 0.5, bridge.z), 0.0):
			whole.append(bridge)
	return whole


func test_act_6_stages_are_thresh_domain() -> void:
	for stage in range(1, 6):
		var map := _domain(stage)
		assert_not_null(map, str(stage))
		assert_eq(map.size, DOMAIN_SIZE)
		assert_eq(map.stage, stage)
		assert_false(map.chasm_polygons.is_empty(), "%d has an abyss" % stage)
		map.free()
	for stage in range(1, 5):
		var map := _domain(stage)
		assert_eq(map.merchant_point, Vector2(2800, 1700))
		assert_eq(map.boss_point, Vector2(4700, 1700))
		map.free()


## West (the start, x 200 to 1700), center (the merchant) and east (the boss
## spot and the two east spawn points).
func test_the_three_plateaus_hold_their_points() -> void:
	var plateaus := ThreshDomainMap.plateaus()
	assert_eq(plateaus.size(), 3)
	var west := StageMap._bounds_of(plateaus[0])
	assert_eq(west.position.x, 200.0)
	assert_eq(west.end.x, 1700.0)
	for stage in range(1, 5):
		var map := _domain(stage)
		assert_true(Geometry2D.is_point_in_polygon(map.lucian_start, plateaus[0]), "%d: the start" % stage)
		assert_true(Geometry2D.is_point_in_polygon(map.merchant_point, plateaus[1]), "%d: the merchant" % stage)
		for point: Vector2 in [map.boss_point, Vector2(5250, 1250), Vector2(5250, 2150)]:
			assert_true(Geometry2D.is_point_in_polygon(point, plateaus[2]), "%d: %s" % [stage, point])
		map.free()


## Two bridges in each gap, 280 wide; from 6-3, 200 wide and the north-west
## one broken. A gap is wider than Flash reaches.
func test_act_6_bridges_by_stage() -> void:
	var expected := {1: [4, 280.0], 2: [4, 280.0], 3: [3, 200.0], 4: [3, 200.0]}
	for stage: int in expected:
		var map := _domain(stage)
		var whole := _whole_bridges(map)
		assert_eq(whole.size(), expected[stage][0], "%d: bridges" % stage)
		var half: float = expected[stage][1] * 0.5
		for bridge in whole:
			var middle := Vector2((bridge.x + bridge.y) * 0.5, bridge.z)
			assert_true(map.is_walkable(middle + Vector2(0, half - 5.0), 0.0), "%d: %s is %d wide" % [stage, middle, expected[stage][1]])
			assert_true(map.is_walkable(middle - Vector2(0, half - 5.0), 0.0))
			assert_false(map.is_walkable(middle + Vector2(0, half + 5.0), 0.0), "%d: %s is no wider" % [stage, middle])
			assert_false(map.is_walkable(middle - Vector2(0, half + 5.0), 0.0))
		var north_west: Vector3 = ThreshDomainMap.BRIDGES[0]
		assert_lt(north_west.z, 1700.0, "north")
		assert_eq(north_west.x, 1700.0, "west: it leaves the west plateau")
		assert_eq(whole.has(north_west), stage < 3, "%d: the north-west bridge is broken from 6-3" % stage)
		map.free()
	for bridge in ThreshDomainMap.BRIDGES:
		assert_gt(bridge.y - bridge.x, SummonerSpells.FLASH_RANGE, "Flash can't skip a bridge")


## The east end of the east plateau, and the far (east) end of every whole
## bridge; in 6-5, the north, east and south stubs. Each on the ground, its
## spawn jitter keeping the biggest body (r 42) BODY_MARGIN off the abyss,
## even on a 200 bridge.
func test_act_6_spawn_points_stand_on_the_ground_with_room_for_their_jitter() -> void:
	for stage in range(1, 6):
		var map := _domain(stage)
		var jitter := map.spawn_jitter
		assert_lt(jitter, StageMap.SPAWN_JITTER, "less than the usual spread")
		for point in map.spawn_points:
			assert_true(_in_any(point, map.ground), "%d: %s on a plateau, a bridge or a stub" % [stage, point])
			for corner: Vector2 in [Vector2(jitter, jitter), Vector2(-jitter, jitter), Vector2(jitter, -jitter), Vector2(-jitter, -jitter)]:
				assert_true(map.is_walkable(point + corner, BODY_MARGIN), "%d: %s's jitter %s" % [stage, point, corner])
		if stage < 5:
			assert_has(map.spawn_points, Vector2(5250, 1250))
			assert_has(map.spawn_points, Vector2(5250, 2150))
			var whole := _whole_bridges(map)
			assert_eq(map.spawn_points.size(), 2 + whole.size(), str(stage))
			for bridge in whole:
				var far_end := Vector2(bridge.y, bridge.z)
				var near := map.spawn_points.filter(func(point: Vector2) -> bool: return point.distance_to(far_end) < 100.0)
				assert_eq(near.size(), 1, "%d: a spawn point at %s" % [stage, far_end])
		map.free()


func test_act_6_camps_by_stage() -> void:
	var expected := {1: {}, 2: {&"karthus_revived": Vector2(4700, 1700)}, 3: {}, 4: {&"hecarim": Vector2(5200, 1700)}, 5: {}}
	for stage: int in expected:
		var map := _domain(stage)
		assert_eq(map.camps, expected[stage], str(stage))
		for point: Vector2 in map.camps.values():
			assert_true(Geometry2D.is_point_in_polygon(point, ThreshDomainMap.plateaus()[2]), "on the east plateau")
			for corner: Vector2 in [Vector2(90, 90), Vector2(-90, -90), Vector2(90, -90), Vector2(-90, 90)]:
				assert_true(map.is_walkable(point + corner, BODY_MARGIN), "%d: the camp's jitter %s" % [stage, corner])
		map.free()
	assert_gt(Vector2(5200, 1700).x, Vector2(4700, 1700).x, "Hecarim rides in from the east end")


## Rock spikes (r 50 to 70) stand on the plateaus, clear of every point.
func test_the_rock_spikes_give_cover_on_the_plateaus() -> void:
	var plateaus := ThreshDomainMap.plateaus()
	for stage in range(1, 5):
		var map := _domain(stage)
		assert_gte(map.wall_circles.size(), 6, str(stage))
		var counts := [0, 0, 0]
		for spike in map.wall_circles:
			var at := Vector2(spike.x, spike.y)
			assert_between(spike.z, 50.0, 70.0)
			for i in plateaus.size():
				if Geometry2D.is_point_in_polygon(at, plateaus[i]):
					counts[i] += 1
			for i in 16:
				assert_false(_in_abyss(map, at + Vector2.from_angle(TAU * i / 16) * (spike.z + 100.0)), "%d: %s keeps off the edge" % [stage, at])
			var points: Array[Vector2] = [map.lucian_start, map.merchant_point, map.boss_point]
			points.append_array(map.spawn_points)
			points.append_array(map.camps.values())
			for point in points:
				assert_gt(point.distance_to(at) - spike.z, 150.0, "%d: %s by %s" % [stage, at, point])
		for count in counts:
			assert_gte(count, 2, "%d: cover on every plateau" % stage)
		map.free()


## Ledges: 2 in 6-1 and 6-2 (north and south of the center plateau), 4 in
## 6-3 and 6-4 (the east plateau's too), none in 6-5. Each is a small island
## in the abyss (abyss for physics), its center about 260 off its edge.
func test_act_6_ledges_by_stage() -> void:
	var plateaus := ThreshDomainMap.plateaus()
	var expected := {1: [[1, -1], [1, 1]], 2: [[1, -1], [1, 1]], 3: [[1, -1], [1, 1], [2, -1], [2, 1]], 4: [[1, -1], [1, 1], [2, -1], [2, 1]], 5: []}
	for stage: int in expected:
		var map := _domain(stage)
		assert_eq(map.ledge_points.size(), expected[stage].size(), str(stage))
		var found := []
		for ledge in map.ledge_points:
			assert_false(map.is_walkable(ledge, 0.0), "%d: %s is abyss" % [stage, ledge])
			assert_true(_in_abyss(map, ledge))
			for i in 16:
				var rim := ledge + Vector2.from_angle(TAU * i / 16) * ThreshDomainMap.LEDGE_RADIUS
				assert_true(_in_abyss(map, rim), "%d: the island %s lies in the abyss" % [stage, ledge])
			# Straight toward the map's middle row, to the plateau's edge.
			var toward := 1.0 if ledge.y < 1700.0 else -1.0
			var step := 0.0
			while step < 600.0 and not map.is_walkable(ledge + Vector2(0, toward * step), 0.0):
				step += 2.0
			assert_almost_eq(step, 260.0, 4.0, "%d: %s off its edge" % [stage, ledge])
			for i in plateaus.size():
				if Geometry2D.is_point_in_polygon(ledge + Vector2(0, toward * (step + 5.0)), plateaus[i]):
					found.append([i, int(-toward)])
		assert_eq(found, expected[stage], "%d: [plateau, north -1 / south 1]" % stage)
		map.free()


## A warden on a ledge can be shot from the edge: walkable ground for
## Lucian's body lies within his attack range of every ledge.
func test_every_ledge_is_within_lucians_attack_range_of_walkable_ground() -> void:
	var reach: float = (load("res://data/lucian_stats.tres") as UnitStats).attack_range
	assert_eq(reach, 500.0)
	for stage in range(1, 5):
		var map := _domain(stage)
		for ledge in map.ledge_points:
			var closest := INF
			for i in 180:
				var direction := Vector2.from_angle(TAU * i / 180)
				var distance := 150.0
				while distance <= reach:
					if map.is_walkable(ledge + direction * distance, Lucian.HIT_RADIUS):
						closest = minf(closest, distance)
						break
					distance += 5.0
			assert_lte(closest, reach, "%d: %s" % [stage, ledge])
			assert_lt(closest, 350.0, "%d: %s in easy reach from the edge" % [stage, ledge])
		map.free()


## Every spot of the map is on the ground or in the abyss, never both: the
## abyss pieces are the map less the plateaus and bridges (or the platform).
func test_the_abyss_is_everything_but_the_ground() -> void:
	for stage in range(1, 6):
		var map := _domain(stage)
		var wrong := 0
		# Offsets that fall on no edge of the plateaus, bridges or seams.
		var x := 37.0
		while x < DOMAIN_SIZE.x:
			var y := 61.0
			while y < DOMAIN_SIZE.y:
				var point := Vector2(x, y)
				if _in_abyss(map, point) == _in_any(point, map.ground):
					wrong += 1
				y += 100.0
			x += 100.0
		assert_eq(wrong, 0, "%d: spots both or neither" % stage)
		map.free()


## The navigation never reaches a ledge (its path ends at the plateau's
## edge), and a path from the start to the merchant or the boss spot never
## crosses the abyss: it takes a bridge.
func test_the_ledges_are_out_of_reach_on_foot_and_paths_keep_to_the_bridges() -> void:
	for stage in range(1, 6):
		var map := _domain(stage)
		add_child(map)
		await _synced(map, map.lucian_start)
		var nav_map := map.get_world_2d().navigation_map
		for ledge in map.ledge_points:
			var path := NavigationServer2D.map_get_path(nav_map, map.lucian_start, ledge, true)
			assert_false(path.is_empty(), "%d: a path toward %s" % [stage, ledge])
			if not path.is_empty():
				assert_gt(path[path.size() - 1].distance_to(ledge), ThreshDomainMap.LEDGE_RADIUS, "%d: %s can't be reached" % [stage, ledge])
		for goal: Vector2 in [map.merchant_point, map.boss_point]:
			var path := NavigationServer2D.map_get_path(nav_map, map.lucian_start, goal, true)
			assert_false(path.is_empty())
			if not path.is_empty():
				assert_lt(path[path.size() - 1].distance_to(goal), 2.0, "%d: the path reaches %s" % [stage, goal])
			var over := 0
			for i in path.size() - 1:
				var steps := ceili(path[i].distance_to(path[i + 1]) / SAMPLE_STEP)
				for s in steps + 1:
					if _in_abyss(map, path[i].lerp(path[i + 1], float(s) / maxi(steps, 1))):
						over += 1
			assert_eq(over, 0, "%d: the path to %s keeps off the abyss" % [stage, goal])
		map.free()
		await wait_physics_frames(1)


## Ordered across the abyss to a ledge, Lucian walks to the plateau's edge
## and never stands on the abyss.
func test_the_abyss_stops_lucian_at_the_edge_on_act_6() -> void:
	var map := _domain(1)
	add_child_autofree(map)
	var ledge := map.ledge_points[0]
	var edge_y := ledge.y + 260.0
	var lucian := _lucian_at(Vector2(ledge.x, edge_y + 300.0))
	await _synced(map, lucian.global_position)
	lucian.command_move(ledge)
	var entered := false
	for frame in 90:
		await wait_physics_frames(1)
		entered = entered or _in_abyss(map, lucian.global_position)
	assert_false(entered, "never on the abyss")
	assert_lt(lucian.global_position.y, edge_y + 80.0, "he walked up to the edge")
	assert_gt(lucian.global_position.y, edge_y, "and stopped there")


## A bolt from a ledge flies over the abyss to Lucian on the plateau.
func test_an_enemy_bolt_flies_over_the_act_6_abyss() -> void:
	var map := _domain(1)
	add_child_autofree(map)
	var ledge := map.ledge_points[0]
	var lucian := _lucian_at(ledge + Vector2(0, 400))
	await wait_physics_frames(2)
	var bolt := EnemyProjectile.new()
	bolt.launch(ledge, Vector2.DOWN, DamageInfo.create(20.0, DamageInfo.Type.MAGIC, &"test"), lucian)
	bolt.speed = 1200.0
	bolt.max_range = 700.0
	var hit := [0]
	bolt.hit_lucian.connect(func() -> void: hit[0] += 1)
	add_child_autofree(bolt)
	await wait_physics_frames(40)
	assert_eq(hit[0], 1, "over the abyss to Lucian")


## Flash from the west plateau's edge, between the bridges, falls short of
## the center plateau.
func test_flash_cannot_cross_a_gap() -> void:
	var map := _domain(1)
	add_child_autofree(map)
	var lucian := _lucian_at(Vector2(1700.0 - Lucian.HIT_RADIUS - 2.0, 1700))
	# Flash's sparks go with the map.
	lucian.projectile_parent = map
	await wait_physics_frames(2)
	assert_true(lucian.use_summoner(0, Vector2(2500, 1700)))
	assert_lt(lucian.global_position.x, 1700.0, "still on the west plateau")


## From 6-3, Flash from the broken bridge's stub falls short of the other.
func test_flash_cannot_cross_the_broken_bridge() -> void:
	var map := _domain(3)
	add_child_autofree(map)
	var bridge: Vector3 = ThreshDomainMap.BRIDGES[0]
	var stub_end := bridge.x
	while map.is_walkable(Vector2(stub_end + 2.0, bridge.z), 0.0):
		stub_end += 2.0
	assert_between(stub_end, bridge.x + 50.0, bridge.x + 200.0, "a stub is left of it")
	var lucian := _lucian_at(Vector2(stub_end - Lucian.HIT_RADIUS - 2.0, bridge.z))
	lucian.projectile_parent = map
	await wait_physics_frames(2)
	assert_true(lucian.use_summoner(0, Vector2(bridge.y + 200.0, bridge.z)))
	assert_lt(lucian.global_position.x, stub_end, "still on the stub")


## 6-5: a round platform (r 1400) with no walls on it, Thresh at its center,
## the merchant south of him, Lucian at the west rim, and a bridge stub at
## north, east, south and west. Waves come from the north, east and south
## stubs, far from Lucian's start; not the west one. The rest is abyss.
func test_the_final_platform_is_round_and_open() -> void:
	var map := _domain(5)
	assert_true(map.wall_polygons.is_empty(), "no walls")
	assert_true(map.wall_circles.is_empty(), "no rocks")
	assert_true(map.ledge_points.is_empty())
	assert_true(map.camps.is_empty())
	assert_eq(map.boss_point, PLATFORM_MIDDLE)
	assert_eq(map.merchant_point, Vector2(2800, 1950))
	for ring: float in [0.0, 350.0, 700.0, 1050.0, PLATFORM_RADIUS - 10.0]:
		for i in 48:
			var point := PLATFORM_MIDDLE + Vector2.from_angle(TAU * i / 48) * ring
			assert_true(map.is_walkable(point, 0.0), "%s on the platform" % point)
	var west := map.lucian_start - PLATFORM_MIDDLE
	assert_lt(absf(west.angle_to(Vector2.LEFT)), 0.2, "west")
	assert_between(west.length(), PLATFORM_RADIUS - 400.0, PLATFORM_RADIUS - 100.0, "near the rim")
	assert_eq(map.spawn_points.size(), 3)
	for direction: Vector2 in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		var stubs := map.spawn_points.filter(func(point: Vector2) -> bool:
			return (point - PLATFORM_MIDDLE).normalized().dot(direction) > 0.99 and point.distance_to(PLATFORM_MIDDLE) > PLATFORM_RADIUS)
		assert_eq(stubs.size(), 0 if direction == Vector2.LEFT else 1, "a spawn point on the stub at %s" % direction)
	for point in map.spawn_points:
		assert_gte(point.distance_to(map.lucian_start), 1000.0, "%s far from the start" % point)
	assert_true(map.is_walkable(ThreshDomainMap.stub_end(3) + Vector2(110, 0)), "the west stub is still there")
	# Past the rim: the abyss, but for the stubs.
	for i in 72:
		var direction := Vector2.from_angle(TAU * i / 72)
		var point := PLATFORM_MIDDLE + direction * (PLATFORM_RADIUS + 30.0)
		var on_stub := false
		for axis: Vector2 in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
			on_stub = on_stub or absf(direction.cross(axis)) * (PLATFORM_RADIUS + 30.0) < 200.0 and direction.dot(axis) > 0.0
		if not on_stub:
			assert_true(_in_abyss(map, point), "%s past the rim" % point)
	map.free()


## The visual pass: the final Thresh starts on the platform's heart. On the
## old dark heart his green-black art, darker still in Phase 2, vanished; on
## the pale one he stands out in both phases.
func test_thresh_reads_on_the_final_platform_heart() -> void:
	var heart := ThreshDomainMap.HEART_COLOR.get_luminance()
	assert_gt(heart - _art_luminance(WavePlan.THRESH_FINAL), 0.15, "Phase 1")
	assert_gt(heart - _art_luminance(WavePlan.THRESH_FINAL, ThreshFinal.PHASE_2_SHADE), 0.2, "Phase 2")
