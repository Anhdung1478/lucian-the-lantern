extends GutTest

var lucian: Lucian


func before_each() -> void:
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)


func _minion(id: String, at: Vector2, act := 1, wave := 1) -> Minion:
	var minion := Minion.new()
	minion.setup(load("res://data/enemies/%s.tres" % id), act, wave, lucian)
	minion.position = at
	add_child_autofree(minion)
	return minion


func _wall(at: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.collision_layer = Layers.WORLD
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(40, 400)
	shape.shape = box
	wall.position = at
	wall.add_child(shape)
	add_child_autofree(wall)


func test_a_melee_minion_walks_up_and_hits() -> void:
	var minion := _minion("melee_minion", Vector2(500, 0))
	var before := lucian.hp
	await wait_seconds(2.5)
	assert_lt(minion.global_position.x, 200.0)
	assert_lt(lucian.hp, before)


func test_a_ranged_minion_keeps_its_distance() -> void:
	var minion := _minion("ranged_minion", Vector2(200, 0))
	await wait_seconds(1.5)
	assert_between(minion.global_position.distance_to(lucian.global_position), 400.0, 560.0)


func test_a_bolt_is_stopped_by_a_wall() -> void:
	_wall(Vector2(200, 0))
	await wait_physics_frames(1)
	var bolt := EnemyProjectile.new()
	bolt.launch(Vector2(500, 0), Vector2.LEFT, DamageInfo.create(50.0, DamageInfo.Type.MAGIC, &"basic"), lucian)
	add_child(bolt)
	var before := lucian.hp
	await wait_seconds(1.3)
	assert_gte(lucian.hp, before)
	assert_false(is_instance_valid(bolt))


func _bolt_at_lucian() -> EnemyProjectile:
	var bolt := EnemyProjectile.new()
	bolt.launch(Vector2(30, 0), Vector2.LEFT, DamageInfo.create(10.0, DamageInfo.Type.MAGIC, &"basic"), lucian)
	add_child_autofree(bolt)
	return bolt


func test_a_bolt_ends_on_lucian() -> void:
	var bolt := _bolt_at_lucian()
	watch_signals(lucian)
	await wait_physics_frames(3)
	assert_signal_emit_count(lucian, "damage_received", 1)
	assert_false(is_instance_valid(bolt), "it doesn't fly on past him")


func test_a_blocked_bolt_ends_too() -> void:
	lucian.invulnerable = true
	var bolt := _bolt_at_lucian()
	await wait_physics_frames(3)
	assert_false(is_instance_valid(bolt))


func test_the_shell_lands_after_its_warning_inside_the_circle() -> void:
	var warning := GroundWarning.circle(Vector2.ZERO, 110.0, 1.0)
	warning.strike(DamageInfo.create(40.0, DamageInfo.Type.TRUE, &"basic"), lucian)
	add_child(warning)
	var before := lucian.hp
	await wait_seconds(0.5)
	assert_gte(lucian.hp, before)
	await wait_seconds(0.7)
	assert_lt(lucian.hp, before)


func test_stepping_out_of_the_circle_dodges_the_shell() -> void:
	var warning := GroundWarning.circle(Vector2.ZERO, 110.0, 1.0)
	warning.strike(DamageInfo.create(40.0, DamageInfo.Type.TRUE, &"basic"), lucian)
	add_child(warning)
	lucian.global_position = Vector2(300, 0)
	var before := lucian.hp
	await wait_seconds(1.2)
	assert_gte(lucian.hp, before)


func test_empower_reaches_small_minions_not_elites() -> void:
	_minion("super_minion", Vector2(1500, 0))
	var melee := _minion("melee_minion", Vector2(1700, 0))
	var siege := _minion("siege_minion", Vector2(1500, 300))
	await wait_physics_frames(3)
	assert_true(melee.has_status(EnemyUnit.EMPOWER))
	assert_false(siege.has_status(EnemyUnit.EMPOWER))
	assert_almost_eq(melee.make_hit().amount, melee.damage * (1.0 + EnemyUnit.EMPOWER_BONUS), 0.01)


func test_a_slow_cuts_move_speed() -> void:
	var minion := _minion("melee_minion", Vector2(2000, 0))
	minion.add_status(Enemy.SLOW, 2.0)
	assert_almost_eq(minion.current_speed(), minion.move_speed * (1.0 - EnemyUnit.SLOW_AMOUNT), 0.01)


func test_numbers_scale_with_act_and_wave() -> void:
	var minion := _minion("melee_minion", Vector2(2000, 0), 2, 3)
	assert_almost_eq(minion.max_hp, 240.0 * 1.6 * 1.3, 0.01)
	assert_almost_eq(minion.damage, 12.0 * 1.25 * 1.3, 0.01)


func test_minions_stand_still_while_lucian_is_untouchable() -> void:
	lucian.invulnerable = true
	var minion := _minion("melee_minion", Vector2(500, 0))
	await wait_seconds(0.5)
	assert_almost_eq(minion.global_position.x, 500.0, 1.0)


func test_a_killed_minion_is_hit_no_more() -> void:
	var minion := _minion("melee_minion", Vector2(500, 0))
	minion.take_damage(lucian.make_damage(9999.0, DamageInfo.Type.TRUE, &"q"))
	await wait_physics_frames(2)
	var shape := CircleShape2D.new()
	shape.radius = 50.0
	assert_false(lucian.query_enemies(shape, Transform2D(0.0, minion.global_position)).has(minion))
