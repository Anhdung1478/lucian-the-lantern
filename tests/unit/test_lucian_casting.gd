extends GutTest

const Slot := ChampionProgress.Slot

var lucian: Lucian


func before_each() -> void:
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	# Shots and beams go here, so they are freed with the test.
	var effects := Node2D.new()
	add_child_autofree(effects)
	lucian.projectile_parent = effects
	add_child_autofree(lucian)


func test_cannot_cast_unlearned_skill() -> void:
	assert_false(lucian.try_cast(Slot.Q, Vector2.RIGHT))


func test_cast_spends_mana_and_starts_cooldown() -> void:
	lucian.try_rank_up(Slot.Q)
	var mana_before := lucian.mana
	assert_true(lucian.try_cast(Slot.Q, lucian.global_position + Vector2.RIGHT * 100))
	assert_almost_eq(lucian.mana, mana_before - 50.0, 0.001)
	assert_almost_eq(lucian.skills[Slot.Q].cooldown.remaining, 9.0, 0.001)


func test_cannot_cast_while_on_cooldown() -> void:
	lucian.try_rank_up(Slot.Q)
	lucian.try_cast(Slot.Q, Vector2.RIGHT)
	lucian.skills[Slot.Q].cooldown.reduce(1.0)
	lucian.lock_cast(0.0)
	assert_false(lucian.try_cast(Slot.Q, Vector2.RIGHT))


func test_cannot_cast_without_mana() -> void:
	lucian.try_rank_up(Slot.Q)
	lucian.mana = 10.0
	assert_false(lucian.try_cast(Slot.Q, Vector2.RIGHT))
	assert_eq(lucian.mana, 10.0)


func test_no_cooldowns_cheat() -> void:
	lucian.cheat_no_cooldowns = true
	lucian.try_rank_up(Slot.Q)
	lucian.try_cast(Slot.Q, Vector2.RIGHT)
	assert_true(lucian.skills[Slot.Q].cooldown.is_ready())


func test_turning_on_no_cooldowns_refreshes_running_cooldowns() -> void:
	lucian.progress.set_level(3)
	lucian.try_rank_up(Slot.Q)
	lucian.try_rank_up(Slot.E)
	lucian.try_cast(Slot.Q, Vector2.RIGHT)
	lucian.skills[Slot.E].cooldown.start(10.0)
	lucian.cheat_no_cooldowns = true
	assert_true(lucian.skills[Slot.Q].cooldown.is_ready())
	assert_true(lucian.skills[Slot.E].cooldown.is_ready())


func test_cannot_cast_during_cast_lock() -> void:
	lucian.progress.set_level(3)
	lucian.try_rank_up(Slot.Q)
	lucian.try_rank_up(Slot.W)
	lucian.lock_cast(0.5)
	assert_false(lucian.try_cast(Slot.W, Vector2.RIGHT))


func test_level_up_raises_max_and_current_hp() -> void:
	lucian.hp = 500.0
	var old_max := lucian.stats.max_hp
	lucian.progress.set_level(2)
	assert_gt(lucian.stats.max_hp, old_max)
	assert_almost_eq(lucian.hp, 500.0 + lucian.stats.max_hp - old_max, 0.001)


func test_q_cast_greys_e() -> void:
	lucian.progress.set_level(3)
	lucian.try_rank_up(Slot.Q)
	lucian.try_rank_up(Slot.E)
	assert_false(lucian.is_skill_blocked(Slot.E))
	assert_true(lucian.try_cast(Slot.Q, lucian.global_position + Vector2.RIGHT * 100))
	assert_true(lucian.is_skill_blocked(Slot.E))
	await wait_seconds(0.4)
	assert_false(lucian.is_skill_blocked(Slot.E))


func test_r_greys_q_and_w_but_not_e() -> void:
	lucian.progress.set_level(6)
	lucian.try_rank_up(Slot.R)
	assert_true(lucian.try_cast(Slot.R, lucian.global_position + Vector2.RIGHT * 100))
	assert_true(lucian.is_skill_blocked(Slot.Q))
	assert_true(lucian.is_skill_blocked(Slot.W))
	assert_false(lucian.is_skill_blocked(Slot.E))


func test_lucian_has_a_health_bar_that_never_turns() -> void:
	var bar := lucian.get_node("HealthBar") as LucianHealthBar
	assert_not_null(bar)
	lucian.visuals.face(Vector2.DOWN)
	assert_eq(bar.global_rotation, 0.0)


func test_setup_without_the_passive_never_charges_it() -> void:
	var setup := StageSetup.new()
	setup.passive = false
	lucian.apply_setup(setup)
	lucian.try_rank_up(Slot.Q)
	lucian.try_cast(Slot.Q, lucian.global_position + Vector2.RIGHT * 100)
	assert_false(lucian.passive.charged)


func test_setup_with_nothing_bought_blocks_rank_ups() -> void:
	var setup := StageSetup.new()
	setup.bought = [0, 0, 0, 0]
	lucian.apply_setup(setup)
	assert_eq(lucian.progress.skill_points(), 1)
	assert_false(lucian.progress.can_rank_up(Slot.Q))


func test_setup_equip_slots_lock_the_rest() -> void:
	var setup := StageSetup.new()
	setup.equip_slots = 1
	lucian.apply_setup(setup)
	assert_eq(lucian.inventory.unlocked_equip, 1)


func test_setup_stat_bonus_adds_to_stats_and_fills_hp_and_mana() -> void:
	var base := lucian.base_ad()
	var setup := StageSetup.new()
	setup.stat_bonus = {&"ad": 8.0}
	lucian.apply_setup(setup)
	assert_almost_eq(lucian.stats.ad, base + 8.0, 0.001)
	assert_eq(lucian.hp, lucian.stats.max_hp)
	assert_eq(lucian.mana, lucian.stats.max_mana)


func test_setup_regen_bonus_raises_the_regen_per_second() -> void:
	var hp_before := lucian.stats.hp_regen
	var mana_before := lucian.stats.mana_regen
	var setup := StageSetup.new()
	setup.stat_bonus = {&"hp_regen": 1.5, &"mana_regen": 1.8}
	lucian.apply_setup(setup)
	assert_almost_eq(lucian.stats.hp_regen, hp_before + 1.5, 0.001)
	assert_almost_eq(lucian.stats.mana_regen, mana_before + 1.8, 0.001)
