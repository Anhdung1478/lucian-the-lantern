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


func test_gunblade_bolts_the_enemy_near_the_cursor() -> void:
	equip(&"hextech_gunblade")
	assert_true(lucian.use_equip_slot(0, dummy.position))
	assert_eq(sources, [&"hextech_gunblade"])
	assert_true(dummy.has_status(Enemy.SLOW))
	assert_almost_eq(lucian.item_cooldown(&"hextech_gunblade").remaining, 60.0, 0.01)


func test_gunblade_needs_an_enemy_in_range() -> void:
	dummy.position = Vector2(2000, 0)
	equip(&"hextech_gunblade")
	assert_false(lucian.use_equip_slot(0, dummy.position))
	assert_true(lucian.item_cooldown(&"hextech_gunblade").is_ready(), "a refused use costs no cooldown")


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
	await wait_seconds(1.0)
	assert_almost_eq(lucian.global_position.distance_to(start), ItemActives.GALEFORCE_DASH, 2.0)
	assert_eq(sources.count(&"galeforce"), ItemActives.GALEFORCE_MISSILES)


func test_rocketbelt_dashes_fires_bolts_and_speeds_up() -> void:
	equip(&"hextech_rocketbelt")
	var speed := lucian.current_move_speed()
	assert_true(lucian.use_equip_slot(0, dummy.position))
	assert_gt(lucian.current_move_speed(), speed * 1.5)
	await wait_seconds(0.5)
	assert_eq(sources.count(&"hextech_rocketbelt"), 1, "each enemy is hit once")


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
