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
