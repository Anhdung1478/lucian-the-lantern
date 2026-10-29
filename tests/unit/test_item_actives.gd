extends GutTest
## Item actives on keys 1-6.

const EQUIP := Inventory.EQUIP_START

var lucian: Lucian
var dummy: TrainingDummy
var sources: Array[StringName] = []


func before_each() -> void:
	sources.clear()
	dummy = load("res://src/enemies/training_dummy.tscn").instantiate()
	dummy.position = Vector2(500, 0)
	add_child_autofree(dummy)
	dummy.damage_taken.connect(func(info: DamageInfo, _final: float) -> void: sources.append(info.source))
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	# Bolts and missiles go here, so they are freed with the test.
	var effects := Node2D.new()
	add_child_autofree(effects)
	lucian.projectile_parent = effects
	add_child_autofree(lucian)


func equip(id: StringName, slot := 0) -> void:
	lucian.inventory.put(EQUIP + slot, lucian.item_catalog.find(id))


func trails() -> Array[DashTrail]:
	var found: Array[DashTrail] = []
	for node in lucian.projectile_parent.get_children():
		if node is DashTrail:
			found.append(node)
	return found


func test_galeforce_leaves_a_wind_trail_from_the_start_of_the_dash() -> void:
	equip(&"galeforce")
	assert_true(lucian.use_equip_slot(0, Vector2(0, -400)))
	assert_eq(trails().size(), 1, "drawn from the start of the dash")
	assert_eq(trails()[0].color, ItemActives.GALEFORCE_TRAIL)
	assert_eq(trails()[0].position, Vector2.ZERO, "from where the dash started")
	# The dash takes 200 / 1260 = 0.16 s; the trail fades for 0.3 s after.
	await wait_seconds(0.25)
	assert_eq(trails().size(), 1)
	assert_almost_eq(trails()[0].length, 200.0, 2.0)


func test_a_trail_still_growing_goes_when_lucian_does() -> void:
	equip(&"galeforce")
	assert_true(lucian.use_equip_slot(0, Vector2(0, -400)))
	var trail := trails()[0]
	lucian.get_parent().remove_child(lucian)
	await wait_physics_frames(1)
	assert_false(is_instance_valid(trail))


func test_rocketbelt_leaves_a_violet_trail_from_the_start_of_the_dash() -> void:
	equip(&"hextech_rocketbelt")
	assert_true(lucian.use_equip_slot(0, Vector2(0, -400)))
	assert_eq(trails().size(), 1, "drawn from the start of the dash")
	assert_eq(trails()[0].color, ItemActives.ROCKETBELT_TRAIL)
	# The dash takes 275 / 800 = 0.34 s.
	await wait_seconds(0.2)
	assert_between(trails()[0].length, 100.0, 220.0, "still growing")
	await wait_seconds(0.25)
	assert_almost_eq(trails()[0].length, 275.0, 2.0)


func test_gunblade_bolts_the_enemy_near_the_cursor() -> void:
	equip(&"hextech_gunblade")
	assert_true(lucian.use_equip_slot(0, dummy.position))
	assert_eq(sources, [&"hextech_gunblade"])
	assert_true(dummy.has_status(Enemy.SLOW))
	assert_almost_eq(dummy.slow_amount(), 0.4, 0.001, "Gunblade still slows 40%")
	assert_almost_eq(lucian.item_cooldown(&"hextech_gunblade").remaining, 60.0, 0.01)


func test_gunblade_needs_an_enemy_in_range() -> void:
	dummy.position = Vector2(2000, 0)
	equip(&"hextech_gunblade")
	assert_false(lucian.use_equip_slot(0, Vector2(300, 300)), "no enemy under the cursor either")
	assert_true(lucian.item_cooldown(&"hextech_gunblade").is_ready(), "a refused use costs no cooldown")
	await wait_seconds(0.2)
	assert_eq(lucian.global_position, Vector2.ZERO, "no walking")


func test_gunblade_on_an_enemy_out_of_range_walks_over_then_casts() -> void:
	dummy.position = Vector2(1000, 0)
	await wait_physics_frames(2)
	equip(&"hextech_gunblade")
	assert_false(lucian.use_equip_slot(0, dummy.position), "not yet")
	assert_true(lucian.item_cooldown(&"hextech_gunblade").is_ready())
	# 1000 - 700 - 34 (the dummy's radius) = 266 to walk at 335.
	await wait_seconds(1.2)
	assert_eq(sources, [&"hextech_gunblade"])
	assert_almost_eq(lucian.global_position.x, 1000.0 - ItemActives.GUNBLADE_RANGE - dummy.radius, 10.0, "walked only until in range")


func test_galeforce_and_rocketbelt_dash_only_as_far_as_the_cursor() -> void:
	equip(&"galeforce")
	equip(&"hextech_rocketbelt", 1)
	assert_true(lucian.use_equip_slot(0, Vector2(0, -100)))
	await wait_seconds(0.3)
	assert_almost_eq(lucian.global_position, Vector2(0, -100), Vector2(1, 1))
	assert_true(lucian.use_equip_slot(1, lucian.global_position), "aimed right on him")
	await wait_physics_frames(3)
	assert_almost_eq(lucian.global_position, Vector2(0, -100), Vector2(1, 1), "no dash")
	assert_eq(lucian.collision_mask, Layers.WORLD | Layers.ENEMY_BODY)


func test_an_active_on_cooldown_is_refused() -> void:
	equip(&"hextech_gunblade")
	lucian.use_equip_slot(0, dummy.position)
	assert_false(lucian.use_equip_slot(0, dummy.position))


func test_copies_share_one_cooldown_kept_after_selling() -> void:
	equip(&"hextech_gunblade", 0)
	equip(&"hextech_gunblade", 1)
	lucian.use_equip_slot(0, dummy.position)
	assert_false(lucian.use_equip_slot(1, dummy.position), "the other copy shares the cooldown")
	lucian.inventory.clear()
	equip(&"hextech_gunblade", 2)
	assert_false(lucian.use_equip_slot(2, dummy.position))


func test_galeforce_dashes_then_fires_missiles() -> void:
	equip(&"galeforce")
	var start := lucian.global_position
	assert_true(lucian.use_equip_slot(0, Vector2(0, -400)))
	assert_true(lucian.is_dashing())
	await wait_seconds(1.5)
	assert_almost_eq(lucian.global_position.distance_to(start), ItemActives.GALEFORCE_DASH, 2.0)
	assert_eq(sources.count(&"galeforce"), ItemActives.GALEFORCE_MISSILES)


func test_galeforce_lets_lucian_walk_once_the_dash_lands() -> void:
	equip(&"galeforce")
	assert_almost_eq(ItemActives.GALEFORCE_DASH_SPEED, 1260.0, 0.01)
	assert_true(lucian.use_equip_slot(0, Vector2(0, -400)))
	lucian.command_move(Vector2(-1000, -200))
	await wait_seconds(0.1)
	assert_almost_eq(lucian.global_position.x, 0.0, 0.5, "no walking during the dash")
	# The dash takes 200 / 1260 = 0.16 s.
	await wait_seconds(0.25)
	assert_lt(lucian.global_position.x, -20.0, "walking right after it")


func test_rocketbelt_dashes_and_fires_bolts_without_move_speed() -> void:
	equip(&"hextech_rocketbelt")
	var speed := lucian.current_move_speed()
	assert_true(lucian.use_equip_slot(0, dummy.position))
	assert_eq(lucian.current_move_speed(), speed)
	await wait_seconds(0.5)
	assert_eq(sources.count(&"hextech_rocketbelt"), 1, "each enemy is hit once")


func test_rocketbelt_lets_lucian_walk_once_the_dash_lands() -> void:
	equip(&"hextech_rocketbelt")
	assert_almost_eq(ItemActives.ROCKETBELT_DASH_SPEED, 800.0, 0.01)
	assert_lt(ItemActives.ROCKETBELT_DASH_SPEED, ItemActives.ROCKETBELT_BOLT_SPEED, "the bolts outrun Lucian")
	assert_true(lucian.use_equip_slot(0, Vector2(0, -400)))
	lucian.command_move(Vector2(-1000, -275))
	await wait_seconds(0.25)
	assert_almost_eq(lucian.global_position.x, 0.0, 0.5, "no walking during the dash")
	# The dash takes 275 / 800 = 0.34 s.
	await wait_seconds(0.3)
	assert_lt(lucian.global_position.x, -20.0, "walking right after it")


func test_rocketbelt_bolts_reach_900_units() -> void:
	dummy.position = Vector2(850, 0)
	equip(&"hextech_rocketbelt")
	assert_true(lucian.use_equip_slot(0, dummy.position))
	await wait_seconds(0.8)
	assert_has(sources, &"hextech_rocketbelt")


func test_rocketbelt_bolts_stop_at_900_units() -> void:
	dummy.position = Vector2(1000, 0)
	equip(&"hextech_rocketbelt")
	assert_true(lucian.use_equip_slot(0, dummy.position))
	await wait_seconds(1.0)
	assert_does_not_have(sources, &"hextech_rocketbelt")


func test_turning_on_no_cooldowns_refreshes_item_cooldowns() -> void:
	equip(&"hextech_gunblade")
	assert_true(lucian.use_equip_slot(0, dummy.position))
	lucian.cheat_no_cooldowns = true
	assert_true(lucian.item_cooldown(&"hextech_gunblade").is_ready())


func test_items_without_actives_do_nothing() -> void:
	equip(&"bf_sword")
	assert_false(lucian.use_equip_slot(0, dummy.position))
