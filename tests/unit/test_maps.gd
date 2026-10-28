extends GutTest

const STAGES := [[1, 1], [2, 1], [2, 2], [2, 3]]


func test_every_point_is_walkable_and_inside() -> void:
	for act_stage in STAGES:
		var map := StageMaps.create(act_stage[0], act_stage[1])
		var points: Array[Vector2] = [map.lucian_start, map.merchant_point, map.boss_point]
		if act_stage[0] == 1:
			points.append(map.ally_start)
		points.append_array(map.spawn_points)
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
