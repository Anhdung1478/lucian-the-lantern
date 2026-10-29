extends GutTest


func test_a_line_covers_points_along_it_only() -> void:
	assert_true(GroundWarning.in_line(Vector2.ZERO, Vector2.RIGHT, 1000.0, 70.0, Vector2(600, 30)))
	assert_false(GroundWarning.in_line(Vector2.ZERO, Vector2.RIGHT, 1000.0, 70.0, Vector2(600, 80)))
	assert_true(GroundWarning.in_line(Vector2.ZERO, Vector2.RIGHT, 1000.0, 70.0, Vector2(600, 60), 30.0))
	assert_false(GroundWarning.in_line(Vector2.ZERO, Vector2.RIGHT, 1000.0, 70.0, Vector2(-100, 0)))


func test_a_cone_covers_its_angle_and_length() -> void:
	var wide := deg_to_rad(70.0)
	assert_true(GroundWarning.in_cone(Vector2.ZERO, Vector2.RIGHT, 400.0, wide, Vector2(300, 100)))
	assert_false(GroundWarning.in_cone(Vector2.ZERO, Vector2.RIGHT, 400.0, wide, Vector2(100, 300)))
	assert_false(GroundWarning.in_cone(Vector2.ZERO, Vector2.RIGHT, 400.0, wide, Vector2(500, 0)))


func test_it_fires_once_after_its_time_and_goes() -> void:
	var warning := GroundWarning.circle(Vector2.ZERO, 100.0, 0.3)
	var fired := [0]
	warning.fired.connect(func() -> void: fired[0] += 1)
	add_child(warning)
	await wait_seconds(0.2)
	assert_eq(fired[0], 0)
	await wait_seconds(0.2)
	assert_eq(fired[0], 1)
	assert_false(is_instance_valid(warning))


func test_a_ring_covers_its_band_only() -> void:
	var warning := GroundWarning.ring(Vector2(100, 100), 450.0, 80.0, 1.0)
	add_child_autofree(warning)
	assert_true(warning.covers(Vector2(550, 100)), "on the circle")
	assert_true(warning.covers(Vector2(585, 100)), "by its outer edge")
	assert_true(warning.covers(Vector2(100, -315)), "by its inner edge")
	assert_false(warning.covers(Vector2(100, 100)), "not its middle")
	assert_false(warning.covers(Vector2(400, 100)), "not inside the band")
	assert_false(warning.covers(Vector2(700, 100)), "not outside it")
	assert_true(warning.covers(Vector2(610, 100), 30.0), "a body reaching onto it")


func test_a_ring_strikes_lucian_on_its_band() -> void:
	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
	lucian.position = Vector2(450, 0)
	add_child_autofree(lucian)
	var warning := GroundWarning.ring(Vector2.ZERO, 450.0, 80.0, 0.1)
	warning.strike(DamageInfo.create(100.0, DamageInfo.Type.TRUE, &"test"), lucian)
	add_child_autofree(warning)
	var hp := lucian.hp
	await wait_physics_frames(12)
	assert_almost_eq(lucian.hp, hp - 100.0, 1.0)
