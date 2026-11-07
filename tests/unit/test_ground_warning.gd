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


func test_a_cone_counts_a_body_reaching_over_its_side() -> void:
	var warning := GroundWarning.cone(Vector2.ZERO, Vector2.RIGHT, 400.0, deg_to_rad(60.0), 1.0)
	add_child_autofree(warning)
	# The side edge runs at 30°. Lucian's 30 px body 300 out covers asin(30 / 300) ≈ 5.7° more.
	var just_out := Vector2.from_angle(deg_to_rad(34.0)) * 300.0
	assert_false(warning.covers(just_out), "his center is outside the edge")
	assert_true(warning.covers(just_out, Lucian.HIT_RADIUS), "but his body reaches over it")
	var farther := Vector2.from_angle(deg_to_rad(37.0)) * 300.0
	assert_false(warning.covers(farther, Lucian.HIT_RADIUS), "farther out, his body is clear")
	assert_true(warning.covers(Vector2(-20, 10), Lucian.HIT_RADIUS), "a body over the tip")
	assert_true(warning.covers(Vector2(420, 0), Lucian.HIT_RADIUS), "a body over the far edge")
	assert_false(warning.covers(Vector2(440, 0), Lucian.HIT_RADIUS), "a body past the far edge")


func test_a_cone_strikes_lucian_standing_half_over_its_side() -> void:
	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
	lucian.position = Vector2.from_angle(deg_to_rad(34.0)) * 300.0
	add_child_autofree(lucian)
	var warning := GroundWarning.cone(Vector2.ZERO, Vector2.RIGHT, 400.0, deg_to_rad(60.0), 0.1)
	warning.strike(DamageInfo.create(100.0, DamageInfo.Type.TRUE, &"test"), lucian)
	add_child_autofree(warning)
	var hp := lucian.hp
	await wait_physics_frames(12)
	assert_almost_eq(lucian.hp, hp - 100.0, 1.0)


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


# --- A warning dies with its caster -----------------------------------------


func _lucian() -> Lucian:
	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)
	return lucian


func _caster() -> Enemy:
	var enemy := Enemy.new()
	enemy.max_hp = 100.0
	enemy.position = Vector2(300, 0)
	add_child_autofree(enemy)
	return enemy


## A circle on Lucian, firing after `seconds`, that strikes him for 100 from
## `caster`.
func _struck(lucian: Lucian, caster: Enemy, seconds: float) -> GroundWarning:
	var warning := GroundWarning.circle(Vector2.ZERO, 100.0, seconds)
	warning.strike(DamageInfo.create(100.0, DamageInfo.Type.TRUE, &"test", caster), lucian)
	add_child_autofree(warning)
	return warning


func test_a_warning_goes_without_striking_once_its_caster_dies() -> void:
	var lucian := _lucian()
	var caster := _caster()
	var warning := _struck(lucian, caster, 0.3)
	var fired := [0]
	warning.fired.connect(func() -> void: fired[0] += 1)
	var hp := lucian.hp
	await wait_physics_frames(2)
	caster.take_damage(DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test"))
	assert_false(caster.is_alive())
	await wait_physics_frames(2)
	assert_true(not is_instance_valid(warning) or warning.is_queued_for_deletion(), "it goes at once")
	await wait_seconds(0.4)
	assert_eq(lucian.hp, hp, "no strike")
	assert_eq(fired[0], 0, "and no fired")


func test_a_warning_whose_caster_is_freed_never_strikes() -> void:
	var lucian := _lucian()
	var caster := _caster()
	var warning := _struck(lucian, caster, 0.3)
	var hp := lucian.hp
	caster.free()
	await wait_seconds(0.5)
	assert_false(is_instance_valid(warning))
	assert_eq(lucian.hp, hp)


func test_a_living_caster_s_warning_still_strikes() -> void:
	var lucian := _lucian()
	var caster := _caster()
	_struck(lucian, caster, 0.1)
	var hp := lucian.hp
	await wait_physics_frames(12)
	assert_almost_eq(lucian.hp, hp - 100.0, 1.0)
