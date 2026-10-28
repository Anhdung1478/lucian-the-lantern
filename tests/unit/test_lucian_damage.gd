extends GutTest

var lucian: Lucian


func before_each() -> void:
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	# Dash trails go here and are freed with it, so none outlives its test.
	lucian.projectile_parent = add_child_autofree(Node2D.new())
	add_child_autofree(lucian)


func _hit(amount: float, type := DamageInfo.Type.PHYSICAL) -> DamageInfo:
	return DamageInfo.create(amount, type, &"basic")


func test_armor_lowers_physical_damage() -> void:
	var before := lucian.hp
	assert_true(lucian.take_damage(_hit(100.0)))
	var expected := DamageCalc.mitigate(100.0, DamageInfo.Type.PHYSICAL, lucian.stats.armor, lucian.stats.mr, 0.0, 0.0)
	assert_almost_eq(before - lucian.hp, expected, 0.01)


func test_barrier_takes_the_hit_first() -> void:
	lucian.add_barrier(1000.0, 2.0)
	var before := lucian.hp
	lucian.take_damage(_hit(100.0))
	assert_eq(lucian.hp, before)
	assert_lt(lucian.total_shield(), 1000.0)


func test_death_fires_once_and_regen_stops() -> void:
	watch_signals(lucian)
	lucian.take_damage(DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test"))
	lucian.take_damage(DamageInfo.create(10.0, DamageInfo.Type.TRUE, &"test"))
	assert_signal_emit_count(lucian, "died", 1)
	assert_true(lucian.dead)
	await wait_physics_frames(5)
	assert_eq(lucian.hp, 0.0)


func test_stats_refresh_never_revives_him() -> void:
	lucian.take_damage(DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test"))
	lucian.refresh_stats()
	assert_eq(lucian.hp, 0.0)


func test_a_dead_lucian_gains_no_hp() -> void:
	lucian.take_damage(DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test"))
	lucian.progress.add_xp(100000)
	assert_gt(lucian.progress.level, 1)
	assert_eq(lucian.hp, 0.0, "a level up (Senna's kill) while dead")
	assert_eq(lucian.heal(100.0), 0.0)
	assert_eq(lucian.hp, 0.0)


func test_invulnerable_refuses_hits() -> void:
	lucian.invulnerable = true
	var before := lucian.hp
	assert_false(lucian.take_damage(_hit(100.0)))
	assert_eq(lucian.hp, before)


func test_restore_for_gives_that_much_regen_at_once() -> void:
	lucian.hp = 100.0
	lucian.mana = 0.0
	lucian.restore_for(10.0)
	assert_almost_eq(lucian.hp, minf(100.0 + lucian.stats.hp_regen * 10.0, lucian.stats.max_hp), 0.01)
	assert_almost_eq(lucian.mana, minf(lucian.stats.mana_regen * 10.0, lucian.stats.max_mana), 0.01)


func test_displace_moves_him_and_drops_his_move() -> void:
	lucian.command_move(Vector2(0, 2000))
	lucian.displace(Vector2(300, 0), 3000.0)
	assert_true(lucian.is_displaced())
	assert_false(lucian.can_act())
	await wait_physics_frames(12)
	assert_almost_eq(lucian.global_position.x, 300.0, 2.0)
	assert_almost_eq(lucian.global_position.y, 0.0, 2.0)
	assert_false(lucian.is_displaced())


func test_displace_stops_at_a_wall() -> void:
	var wall := StaticBody2D.new()
	wall.collision_layer = Layers.WORLD
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(40, 400)
	shape.shape = box
	shape.position = Vector2(200, 0)
	wall.add_child(shape)
	add_child_autofree(wall)
	await wait_physics_frames(1)
	lucian.displace(Vector2(400, 0), 3000.0)
	await wait_physics_frames(12)
	assert_lt(lucian.global_position.x, 200.0)
	assert_false(lucian.is_displaced())


func test_damage_received_reports_the_amount() -> void:
	watch_signals(lucian)
	lucian.take_damage(DamageInfo.create(50.0, DamageInfo.Type.TRUE, &"test"))
	assert_almost_eq(get_signal_parameters(lucian, "damage_received")[1], 50.0, 0.01)


func test_displace_ends_a_dash_in_progress() -> void:
	lucian.start_dash(Vector2.RIGHT, 2000.0, 1000.0)
	lucian.displace(Vector2(0, 300), 3000.0)
	assert_false(lucian.is_dashing())
	await wait_physics_frames(12)
	assert_false(lucian.is_dashing())
	assert_false(lucian.is_displaced())
	assert_almost_eq(lucian.global_position.x, 0.0, 2.0)
	assert_almost_eq(lucian.global_position.y, 300.0, 2.0)


func test_death_ends_a_dash() -> void:
	lucian.start_dash(Vector2.RIGHT, 2000.0, 1000.0)
	lucian.take_damage(DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test"))
	assert_false(lucian.is_dashing())


func test_a_hit_just_before_death_keeps_the_grey() -> void:
	lucian.take_damage(DamageInfo.create(20.0, DamageInfo.Type.TRUE, &"test"))
	await wait_physics_frames(2)
	lucian.take_damage(DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test"))
	await wait_seconds(0.4)
	var tint := lucian.visuals.modulate
	assert_almost_eq(tint.r, Lucian.DEATH_TINT.r, 0.01, "grey, not the hurt flash's white")
	assert_lt(tint.a, 1.0, "fading out")


func test_a_hit_just_before_stasis_keeps_the_gold() -> void:
	lucian.take_damage(DamageInfo.create(20.0, DamageInfo.Type.TRUE, &"test"))
	await wait_physics_frames(2)
	lucian.enter_stasis(1.0, 100.0, 0.0)
	await wait_seconds(0.4)
	assert_eq(lucian.visuals.modulate, Lucian.STASIS_TINT)


func test_stasis_clears_a_displacement_in_flight() -> void:
	lucian.displace(Vector2(2000, 0), 1000.0)
	lucian.enter_stasis(0.1, 100.0, 0.0)
	assert_false(lucian.is_displaced())
	await wait_seconds(0.3)
	assert_false(lucian.in_stasis())
	assert_false(lucian.is_displaced())
	assert_eq(lucian.collision_mask, Layers.WORLD | Layers.ENEMY_BODY)
