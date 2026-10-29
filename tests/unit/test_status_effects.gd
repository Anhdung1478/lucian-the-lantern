extends GutTest
## Slows, burns, stat buffs (the jungle buffs), untargetable enemies and the
## throw over walls (Lucian.launch).

const Slot := ChampionProgress.Slot

var lucian: Lucian
var effects: Node2D
## [DamageInfo, amount] per hit Lucian took.
var received: Array[Array] = []


func before_each() -> void:
	received.clear()
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	# Shots, bolts and trails go here, so they are freed with the test.
	effects = Node2D.new()
	add_child_autofree(effects)
	lucian.projectile_parent = effects
	add_child_autofree(lucian)
	lucian.global_position = Vector2.ZERO
	lucian.damage_received.connect(func(info: DamageInfo, amount: float) -> void: received.append([info, amount]))


## A plain enemy at `at`.
func _enemy(at: Vector2, hp := 100.0) -> Enemy:
	var enemy := Enemy.new()
	enemy.radius = 20.0
	enemy.max_hp = hp
	enemy.position = at
	add_child_autofree(enemy)
	return enemy


func _minion(at: Vector2, data: EnemyData = null) -> Minion:
	var minion := Minion.new()
	minion.setup(data if data else load("res://data/enemies/melee_minion.tres"), 1, 1, lucian)
	minion.position = at
	minion.projectile_parent = effects
	add_child_autofree(minion)
	return minion


func _dummy(at: Vector2) -> TrainingDummy:
	var dummy: TrainingDummy = load("res://src/enemies/training_dummy.tscn").instantiate()
	dummy.position = at
	add_child_autofree(dummy)
	return dummy


func _wall(at: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.collision_layer = Layers.WORLD
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(40, 400)
	shape.shape = box
	shape.position = at
	wall.add_child(shape)
	add_child_autofree(wall)


func _sfx() -> Sfx:
	var sfx := Sfx.new()
	add_child_autofree(sfx)
	return sfx


func _in_range() -> float:
	return lucian.attack_range() * 0.5


func _equip(id: StringName) -> void:
	lucian.inventory.put(Inventory.EQUIP_START, lucian.item_catalog.find(id))


func _buff_ids() -> Array:
	return lucian.buffs().map(func(buff: Dictionary) -> StringName: return buff.id)


# --- Lucian slows ---------------------------------------------------------


func test_the_strongest_of_two_slows_wins_and_speed_returns_when_they_expire() -> void:
	var speed := lucian.current_move_speed()
	lucian.add_slow(&"water", 0.25, 0.4)
	lucian.add_slow(&"bite", 0.4, 0.2)
	assert_almost_eq(lucian.slow_amount(), 0.4, 0.001)
	assert_almost_eq(lucian.current_move_speed(), speed * 0.6, 0.01, "not 0.25 + 0.4")
	assert_true(_buff_ids().has(Lucian.SLOWED), "shows in the buff row")
	await wait_seconds(0.3)
	assert_almost_eq(lucian.current_move_speed(), speed * 0.75, 0.01, "the weaker one is left")
	await wait_seconds(0.2)
	assert_almost_eq(lucian.current_move_speed(), speed, 0.01)
	assert_false(_buff_ids().has(Lucian.SLOWED))


func test_the_same_slow_id_replaces_the_old_one() -> void:
	lucian.add_slow(&"water", 0.4, 1.0)
	lucian.add_slow(&"water", 0.1, 1.0)
	assert_almost_eq(lucian.slow_amount(), 0.1, 0.001)


func test_tenacity_does_not_shorten_a_slow() -> void:
	lucian.tree_bonus = {&"tenacity": 0.5}
	lucian.refresh_stats()
	lucian.add_slow(&"water", 0.3, 0.3)
	await wait_seconds(0.2)
	assert_almost_eq(lucian.slow_amount(), 0.3, 0.001)


# --- Lucian burns ---------------------------------------------------------


func test_a_magic_burn_is_lowered_by_magic_resist() -> void:
	lucian.add_burn(&"poison", 10.0, 3.0, DamageInfo.Type.MAGIC)
	await wait_seconds(0.6)
	assert_eq(received.size(), 1, "one tick after half a second")
	var info: DamageInfo = received[0][0]
	assert_true(info.over_time)
	assert_eq(info.source, &"burn")
	var expected := DamageCalc.mitigate(5.0, DamageInfo.Type.MAGIC, lucian.stats.armor, lucian.stats.mr, 0.0, 0.0)
	assert_lt(expected, 5.0)
	assert_almost_eq(received[0][1], expected, 0.01)
	assert_true(_buff_ids().has(Lucian.BURNING), "shows in the buff row")


func test_true_damage_burns_are_not_lowered() -> void:
	lucian.add_burn(&"fire", 10.0, 3.0, DamageInfo.Type.TRUE)
	await wait_seconds(0.6)
	assert_eq(received.size(), 1)
	assert_almost_eq(received[0][1], 5.0, 0.001)


func test_a_burn_tick_makes_no_hurt_sound_and_no_flash() -> void:
	var sfx := _sfx()
	lucian.add_burn(&"fire", 10.0, 3.0, DamageInfo.Type.TRUE)
	await wait_seconds(0.6)
	assert_eq(received.size(), 1)
	assert_false(sfx._last_played.has(&"hurt"))
	assert_eq(lucian.visuals.modulate, Color.WHITE)
	lucian.take_damage(DamageInfo.create(5.0, DamageInfo.Type.TRUE, &"basic"))
	assert_true(sfx._last_played.has(&"hurt"), "a real hit still does")


func test_banshees_veil_does_not_eat_a_tick() -> void:
	_equip(&"banshees_veil")
	lucian.add_burn(&"fire", 10.0, 3.0, DamageInfo.Type.TRUE)
	await wait_seconds(0.6)
	assert_eq(received.size(), 1)
	assert_true(lucian.item_cooldown(&"banshees_veil").is_ready())


func test_thornmail_does_not_answer_a_tick() -> void:
	_equip(&"thornmail")
	var attacker := _enemy(Vector2(100, 0), 5000.0)
	lucian.add_burn(&"fire", 20.0, 3.0, DamageInfo.Type.PHYSICAL, attacker)
	await wait_seconds(0.6)
	assert_eq(received.size(), 1)
	assert_eq(attacker.hp, attacker.max_hp)
	assert_false(attacker.has_status(Enemy.GRIEVOUS_WOUNDS))


func test_death_clears_burns_and_slows() -> void:
	lucian.add_burn(&"fire", 10.0, 3.0, DamageInfo.Type.TRUE)
	lucian.add_slow(&"water", 0.3, 3.0)
	lucian.take_damage(DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test"))
	assert_true(lucian.dead)
	assert_false(lucian._burns.has(&"fire"))
	assert_eq(lucian.slow_amount(), 0.0)
	assert_false(_buff_ids().has(Lucian.BURNING))
	lucian.add_burn(&"fire", 10.0, 3.0, DamageInfo.Type.TRUE)
	assert_false(lucian._burns.has(&"fire"), "no new burn on a dead Lucian")


# --- Ticks Lucian deals ---------------------------------------------------


func test_ticks_lucian_deals_do_not_refresh_ardent_blazes_speed() -> void:
	assert_true(lucian.try_rank_up(Slot.W))
	var dummy := _dummy(Vector2(600, 0))
	var speed := lucian.current_move_speed()
	dummy.add_mark(ArdentBlaze.MARK, 6.0)
	dummy.add_burn(&"fire", 20.0, 3.0, DamageInfo.Type.TRUE, lucian)
	await wait_seconds(0.6)
	assert_lt(dummy.hp, dummy.max_hp, "a tick landed")
	assert_eq(lucian.current_move_speed(), speed)


# --- Stat buffs and the jungle buffs ---------------------------------------


func test_blue_raises_mana_regen_and_ability_haste_and_shows() -> void:
	var regen := lucian.stats.mana_regen
	var haste := lucian.stats.ability_haste
	lucian.add_jungle_buff(JungleBuffs.BLUE)
	assert_true(lucian.has_stat_buff(JungleBuffs.BLUE))
	assert_almost_eq(lucian.stats.mana_regen, regen + 10.0, 0.001)
	assert_almost_eq(lucian.stats.ability_haste, haste + 20.0, 0.001)
	var buff: Dictionary = lucian.buffs().filter(func(entry: Dictionary) -> bool: return entry.id == JungleBuffs.BLUE)[0]
	assert_eq(buff.icon, JungleBuffs.BLUE_ICON)
	assert_almost_eq(buff.left, JungleBuffs.DURATION, 0.001)
	assert_almost_eq(buff.duration, 60.0, 0.001)


func test_red_raises_hp_regen() -> void:
	var regen := lucian.stats.hp_regen
	lucian.add_jungle_buff(JungleBuffs.RED)
	assert_almost_eq(lucian.stats.hp_regen, regen + 5.0, 0.001)
	assert_true(_buff_ids().has(JungleBuffs.RED))


func test_a_stat_buff_expires_after_its_time() -> void:
	var regen := lucian.stats.mana_regen
	lucian.mana = lucian.stats.max_mana * 0.5
	lucian.add_stat_buff(JungleBuffs.BLUE, JungleBuffs.bonus(JungleBuffs.BLUE), 0.2)
	await wait_seconds(0.3)
	assert_false(lucian.has_stat_buff(JungleBuffs.BLUE))
	assert_almost_eq(lucian.stats.mana_regen, regen, 0.001)
	assert_false(_buff_ids().has(JungleBuffs.BLUE))


func test_unit_stats_take_regen_bonuses_per_second() -> void:
	var base := lucian.base_stats.at_level(1)
	var buffed := lucian.base_stats.at_level(1, {&"hp_regen": 5.0, &"mana_regen": 10.0})
	assert_almost_eq(buffed.hp_regen, base.hp_regen + 5.0, 0.001)
	assert_almost_eq(buffed.mana_regen, base.mana_regen + 10.0, 0.001)


func test_red_makes_attacks_burn_and_slow_and_skills_slow() -> void:
	lucian.add_jungle_buff(JungleBuffs.RED)
	var shot := _dummy(Vector2(600, 0))
	var cast := _dummy(Vector2(600, 200))
	var item := _dummy(Vector2(600, 400))
	lucian.on_damage_dealt(shot, lucian.make_damage(10.0, DamageInfo.Type.PHYSICAL, &"basic"), 8.0)
	lucian.on_damage_dealt(cast, lucian.make_damage(10.0, DamageInfo.Type.MAGIC, &"q"), 8.0)
	lucian.on_damage_dealt(item, lucian.make_damage(10.0, DamageInfo.Type.MAGIC, &"nashors_tooth"), 8.0)
	assert_true(shot._burns.has(JungleBuffs.RED))
	assert_almost_eq(shot.slow_amount(), JungleBuffs.RED_SLOW, 0.001)
	assert_false(cast._burns.has(JungleBuffs.RED), "skills only slow")
	assert_almost_eq(cast.slow_amount(), 0.15, 0.001)
	assert_false(item._burns.has(JungleBuffs.RED))
	assert_eq(item.slow_amount(), 0.0)


func test_reds_burn_does_not_refresh_itself() -> void:
	lucian.add_jungle_buff(JungleBuffs.RED)
	var dummy := _dummy(Vector2(600, 0))
	lucian.on_damage_dealt(dummy, lucian.make_damage(10.0, DamageInfo.Type.PHYSICAL, &"basic"), 8.0)
	await wait_seconds(1.1)
	assert_lt(dummy.hp, dummy.max_hp)
	assert_almost_eq(dummy._burns.time_left(JungleBuffs.RED), JungleBuffs.RED_BURN_TIME - 1.1, 0.1)


func test_without_red_attacks_carry_nothing() -> void:
	var dummy := _dummy(Vector2(600, 0))
	lucian.on_damage_dealt(dummy, lucian.make_damage(10.0, DamageInfo.Type.PHYSICAL, &"basic"), 8.0)
	assert_false(dummy._burns.has(JungleBuffs.RED))
	assert_eq(dummy.slow_amount(), 0.0)


# --- Enemies ----------------------------------------------------------------


func test_an_enemy_slow_uses_the_strongest_and_shows_on_its_bar() -> void:
	var minion := _minion(Vector2(3000, 0))
	minion.add_slow(&"weak", 0.2, 1.0)
	minion.add_slow(&"strong", 0.5, 0.2)
	assert_almost_eq(minion.slow_amount(), 0.5, 0.001)
	assert_almost_eq(minion.current_speed(), minion.move_speed * 0.5, 0.01)
	assert_true(minion.has_status(Enemy.SLOW))
	var slow: Dictionary = minion.statuses().filter(func(status: Dictionary) -> bool: return status.id == Enemy.SLOW)[0]
	assert_not_null(slow.icon)
	assert_almost_eq(slow.left, 1.0, 0.001, "as long as the longest slow")
	await wait_seconds(0.3)
	assert_almost_eq(minion.current_speed(), minion.move_speed * 0.8, 0.01)
	await wait_seconds(0.8)
	assert_almost_eq(minion.current_speed(), minion.move_speed, 0.01)
	assert_false(minion.has_status(Enemy.SLOW))


func test_an_enemy_burn_shows_on_its_bar() -> void:
	var minion := _minion(Vector2(3000, 0))
	minion.add_burn(&"fire", 10.0, 2.0, DamageInfo.Type.TRUE, lucian)
	assert_true(minion.has_status(Enemy.BURN))
	var burn: Dictionary = minion.statuses().filter(func(status: Dictionary) -> bool: return status.id == Enemy.BURN)[0]
	assert_eq(burn.icon, Enemy.BURN_ICON)


func test_an_enemy_burn_tick_is_quiet() -> void:
	var sfx := _sfx()
	var minion := _minion(Vector2(3000, 0))
	minion.add_burn(&"fire", 10.0, 2.0, DamageInfo.Type.TRUE, lucian)
	await wait_seconds(0.6)
	assert_lt(minion.hp, minion.max_hp)
	assert_false(sfx._last_played.has(&"hit"))
	assert_eq(minion.visuals.modulate, Color.WHITE, "no flash")


func test_an_enemy_burn_kills_with_lucians_credit() -> void:
	var minion := _minion(Vector2(3000, 0))
	minion.hp = 3.0
	watch_signals(lucian)
	minion.add_burn(&"fire", 10.0, 2.0, DamageInfo.Type.TRUE, lucian)
	await wait_seconds(0.6)
	assert_true(minion.dead)
	assert_signal_emitted_with_parameters(lucian, "enemy_killed", [minion])
	assert_false(minion.has_status(Enemy.BURN), "death clears it")
	assert_engine_error_count(0)


# --- Untargetable -----------------------------------------------------------


func test_homing_shots_in_flight_fizzle() -> void:
	var enemy := _enemy(Vector2(1500, 0))
	var shot := AttackProjectile.new()
	shot.launch(Vector2.ZERO, enemy, lucian.make_damage(10.0, DamageInfo.Type.PHYSICAL, &"basic"))
	effects.add_child(shot)
	var missile := HomingMissile.new()
	missile.launch(Vector2.ZERO, Vector2.RIGHT, enemy, lucian.make_damage(10.0, DamageInfo.Type.MAGIC, &"galeforce"))
	effects.add_child(missile)
	enemy.set_untargetable(true)
	await wait_physics_frames(3)
	assert_false(is_instance_valid(shot))
	assert_false(is_instance_valid(missile))
	assert_eq(enemy.hp, enemy.max_hp)


func test_enemy_at_and_a_click_miss_an_untargetable_enemy() -> void:
	var hidden := _enemy(Vector2(_in_range(), 0), 100.0)
	hidden.hp = 10.0
	var seen := _enemy(Vector2(lucian.attack_range() + 500.0, 0))
	hidden.set_untargetable(true)
	assert_false(Lucian.is_target(hidden))
	assert_null(lucian.enemy_at(hidden.global_position))
	assert_eq(lucian.attack_move_target(hidden.global_position), seen, "not hovered")
	assert_eq(lucian.attack_move_target(Vector2(0, 2000)), seen, "not weakest in range")
	seen.set_untargetable(true)
	assert_null(lucian.attack_move_target(hidden.global_position), "nor nearest")


func test_an_untargetable_enemy_takes_no_damage_burns_included() -> void:
	var enemy := _enemy(Vector2(3000, 0))
	enemy.set_untargetable(true)
	assert_eq(enemy.take_damage(lucian.make_damage(50.0, DamageInfo.Type.TRUE, &"q")), 0.0)
	enemy.add_burn(&"fire", 1000.0, 2.0, DamageInfo.Type.TRUE, lucian)
	await wait_seconds(0.6)
	assert_eq(enemy.hp, enemy.max_hp)
	assert_false(enemy.dead)


func test_the_attack_order_waits_through_untargetable_then_shoots() -> void:
	var enemy := _enemy(Vector2(_in_range(), 0), 5000.0)
	var spawned := [0]
	effects.child_entered_tree.connect(func(node: Node) -> void:
		if node is AttackProjectile:
			spawned[0] += 1)
	lucian.command_attack(enemy)
	await wait_physics_frames(2)
	assert_gt(lucian._windup_left, 0.0, "winding up")
	enemy.set_untargetable(true)
	await wait_seconds(0.6)
	assert_eq(spawned[0], 0, "the windup doesn't fire at it")
	assert_eq(lucian._order, Lucian.Order.ATTACK)
	assert_eq(lucian._target, enemy)
	enemy.set_untargetable(false)
	await wait_seconds(0.6)
	assert_eq(spawned[0], 1)
	assert_lt(enemy.hp, enemy.max_hp, "shoots again once it is back")


func test_the_attack_order_follows_an_untargetable_enemy() -> void:
	var enemy := _enemy(Vector2(lucian.attack_range() + 400.0, 0))
	lucian.command_attack(enemy)
	enemy.set_untargetable(true)
	await wait_seconds(0.3)
	assert_gt(lucian.global_position.x, 50.0, "walks after it")
	assert_eq(lucian._order, Lucian.Order.ATTACK)
	enemy.set_untargetable(false)
	enemy.hp = 0.0
	enemy._die()
	await wait_physics_frames(2)
	assert_eq(lucian._order, Lucian.Order.NONE, "a death still drops it")


func test_the_boss_bar_keeps_an_untargetable_boss() -> void:
	var bar := BossBar.new()
	add_child_autofree(bar)
	var data := EnemyData.new()
	data.kind = &"boss"
	data.display_name = "Test Boss"
	data.max_hp = 1000.0
	var boss := _minion(Vector2(3000, 0), data)
	bar._process(0.0)
	assert_eq(bar.boss, boss)
	boss.set_untargetable(true)
	bar._process(0.0)
	assert_eq(bar.boss, boss, "held while it lives, out of the group")
	assert_true(bar.visible)
	boss._die()
	bar._process(0.0)
	assert_null(bar.boss, "dropped once dead")


func test_a_dead_enemy_stays_out_after_set_untargetable_false() -> void:
	var minion := _minion(Vector2(3000, 0))
	minion.set_untargetable(true)
	minion._die()
	minion.set_untargetable(false)
	assert_false(minion.is_in_group(&"enemies"))
	assert_eq(minion.collision_layer, 0)
	for child in minion.get_children():
		if child is Hurtbox:
			assert_eq((child as Hurtbox).collision_layer, 0)


func test_untargetable_then_back_to_normal() -> void:
	var minion := _minion(Vector2(3000, 0))
	var hurtbox: Hurtbox = minion.get_children().filter(func(child: Node) -> bool: return child is Hurtbox)[0]
	minion.set_untargetable(true)
	assert_true(minion.untargetable)
	assert_false(minion.is_in_group(&"enemies"))
	assert_eq(minion.collision_layer, 0)
	assert_eq(hurtbox.collision_layer, 0)
	assert_true(minion.is_alive(), "still alive, only hidden")
	minion.set_untargetable(false)
	assert_false(minion.untargetable)
	assert_true(minion.is_in_group(&"enemies"))
	assert_eq(minion.collision_layer, Layers.ENEMY_BODY)
	assert_eq(hurtbox.collision_layer, Layers.ENEMY_HURTBOX)
	assert_true(Lucian.is_target(minion))
	assert_gt(minion.take_damage(lucian.make_damage(10.0, DamageInfo.Type.TRUE, &"q")), 0.0)


# --- launch -----------------------------------------------------------------


func test_a_launch_passes_a_wall_and_lands_on_the_far_side() -> void:
	_wall(Vector2(200, 0))
	await wait_physics_frames(1)
	lucian.launch(Vector2(400, 0), 0.3)
	assert_true(lucian.is_launched())
	assert_eq(lucian.collision_mask, 0)
	await wait_seconds(0.15)
	assert_gt(lucian.visuals.scale.x, 1.1, "high in the air")
	await wait_seconds(0.3)
	assert_false(lucian.is_launched())
	assert_almost_eq(lucian.global_position, Vector2(400, 0), Vector2(1, 1))
	assert_eq(lucian.visuals.scale, Vector2.ONE)
	assert_eq(lucian.collision_mask, Layers.WORLD | Layers.ENEMY_BODY)


func test_no_acting_in_flight() -> void:
	lucian.cheat_infinite_mana = true
	assert_true(lucian.try_rank_up(Slot.Q))
	lucian.command_move(Vector2(0, 500))
	lucian.launch(Vector2(300, 0), 0.3)
	assert_false(lucian.can_act())
	assert_false(lucian.try_cast(Slot.Q, Vector2(600, 0)))
	assert_false(lucian.use_summoner(0, Vector2(0, -300)))
	await wait_seconds(0.4)
	assert_true(lucian.can_act())
	assert_eq(lucian._order, Lucian.Order.NONE, "the throw drops the move")


func test_ghost_ending_mid_flight_does_not_reset_the_mask() -> void:
	lucian.set_ghosted(0.05)
	lucian.launch(Vector2(300, 0), 0.4)
	await wait_seconds(0.2)
	assert_false(lucian.is_ghosted())
	assert_eq(lucian.collision_mask, 0)
	await wait_seconds(0.3)
	assert_eq(lucian.collision_mask, Layers.WORLD | Layers.ENEMY_BODY)


func test_displace_is_ignored_in_flight() -> void:
	lucian.launch(Vector2(300, 0), 0.3)
	lucian.displace(Vector2(0, 300), 3000.0)
	assert_false(lucian.is_displaced())
	await wait_seconds(0.4)
	assert_almost_eq(lucian.global_position, Vector2(300, 0), Vector2(1, 1))


func test_stasis_ends_a_launch() -> void:
	lucian.launch(Vector2(300, 0), 0.3)
	lucian.enter_stasis(0.1, 100.0, 0.0)
	assert_false(lucian.is_launched())
	assert_eq(lucian.visuals.scale, Vector2.ONE)


func test_the_throw_builds_no_energize() -> void:
	_equip(&"statikk_shiv")
	lucian.launch(Vector2(800, 0), 0.3)
	await wait_seconds(0.5)
	assert_almost_eq(lucian.global_position, Vector2(800, 0), Vector2(1, 1))
	assert_eq(lucian.passives.energize.value, 0.0)


# --- On-hit fields ----------------------------------------------------------


func _on_hit_data(behavior: StringName) -> EnemyData:
	var data := EnemyData.new()
	data.id = &"test_monster"
	data.behavior = behavior
	data.damage = 10.0
	data.damage_type = DamageInfo.Type.MAGIC
	data.attack_range = 600.0
	data.attack_interval = 10.0
	data.keep_min = 0.0
	data.keep_max = 2000.0
	data.projectile_speed = 2000.0
	return data


func test_a_melee_hit_with_hit_slow_slows_lucian() -> void:
	var data := _on_hit_data(&"melee")
	data.hit_slow = 0.3
	data.hit_slow_time = 1.0
	var minion := _minion(Vector2(3000, 0), data)
	lucian.invulnerable = true
	minion._attack()
	assert_eq(lucian.slow_amount(), 0.0, "a refused hit carries nothing")
	lucian.invulnerable = false
	minion._attack()
	assert_almost_eq(lucian.slow_amount(), 0.3, 0.001)


func test_a_bolt_with_hit_burn_burns_lucian() -> void:
	var data := _on_hit_data(&"ranged")
	data.hit_burn = 6.0
	data.hit_burn_time = 3.0
	var minion := _minion(Vector2(300, 0), data)
	minion._attack()
	assert_false(lucian._burns.has(data.id), "not before the bolt lands")
	await wait_seconds(0.25)
	assert_true(lucian._burns.has(data.id))
	await wait_seconds(0.5)
	var ticks := received.filter(func(hit: Array) -> bool: return hit[0].over_time)
	assert_eq(ticks.size(), 1)
	assert_eq(ticks[0][0].type, DamageInfo.Type.MAGIC, "the enemy's damage type")
