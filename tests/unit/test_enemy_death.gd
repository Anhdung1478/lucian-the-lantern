extends GutTest
## Enemies that die: the died signal, the kill credit and what lets go of them.

const Slot := ChampionProgress.Slot

var lucian: Lucian


func before_each() -> void:
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)


func _enemy(hp: float, at := Vector2(300, 0)) -> Enemy:
	var enemy := Enemy.new()
	enemy.max_hp = hp
	enemy.position = at
	add_child_autofree(enemy)
	return enemy


func _true_hit(amount: float, source := &"test") -> DamageInfo:
	return lucian.make_damage(amount, DamageInfo.Type.TRUE, source)


func test_died_fires_once_and_the_enemy_leaves_the_group() -> void:
	var enemy := _enemy(100.0)
	watch_signals(enemy)
	enemy.take_damage(_true_hit(150.0))
	enemy.take_damage(_true_hit(10.0))
	assert_signal_emit_count(enemy, "died", 1)
	assert_false(enemy.is_alive())
	assert_false(enemy.is_in_group(&"enemies"))


func test_a_dead_enemy_takes_no_damage() -> void:
	var enemy := _enemy(100.0)
	enemy.take_damage(_true_hit(150.0))
	watch_signals(enemy)
	assert_eq(enemy.take_damage(_true_hit(50.0)), 0.0)
	assert_signal_not_emitted(enemy, "damage_taken")


func test_the_kill_goes_to_the_last_attacker() -> void:
	var enemy := _enemy(100.0)
	watch_signals(lucian)
	enemy.take_damage(_true_hit(150.0))
	assert_signal_emit_count(lucian, "enemy_killed", 1)


func test_on_hit_procs_after_the_killing_blow_never_kill_twice() -> void:
	lucian.inventory.put(Inventory.EQUIP_START, lucian.item_catalog.find(&"nashors_tooth"))
	var enemy := _enemy(10.0)
	watch_signals(lucian)
	enemy.take_damage(_true_hit(50.0, &"basic"))
	assert_signal_emit_count(lucian, "enemy_killed", 1)


func test_a_shot_flying_to_a_dead_enemy_is_dropped() -> void:
	var enemy := _enemy(100.0, Vector2(2000, 0))
	var shot := AttackProjectile.new()
	add_child(shot)
	shot.launch(Vector2.ZERO, enemy, _true_hit(40.0))
	enemy.take_damage(_true_hit(500.0))
	watch_signals(enemy)
	await wait_physics_frames(2)
	assert_signal_not_emitted(enemy, "damage_taken")
	assert_false(is_instance_valid(shot))


func test_an_attack_order_on_a_dead_enemy_stops() -> void:
	var enemy := _enemy(100.0, Vector2(2000, 0))
	enemy.take_damage(_true_hit(500.0))
	lucian.command_attack(enemy)
	await wait_physics_frames(3)
	assert_eq(lucian.global_position, Vector2.ZERO)


func test_a_dead_enemy_fades_then_is_freed() -> void:
	var enemy := _enemy(100.0)
	enemy.take_damage(_true_hit(500.0))
	assert_true(is_instance_valid(enemy))
	await wait_seconds(Enemy.DEATH_FADE + 0.2)
	assert_false(is_instance_valid(enemy))


func test_e_rank_5_kill_cuts_its_cooldown_by_1_second() -> void:
	lucian.progress.set_level(9)
	for i in 5:
		assert_true(lucian.try_rank_up(Slot.E))
	var e := lucian.skills[Slot.E]
	e.cooldown.start(10.0)
	_enemy(10.0).take_damage(_true_hit(50.0))
	assert_almost_eq(e.cooldown.remaining, 10.0 - RelentlessPursuit.KILL_CUT, 0.001)


func test_e_rank_4_kill_does_not() -> void:
	lucian.progress.set_level(7)
	for i in 4:
		lucian.try_rank_up(Slot.E)
	var e := lucian.skills[Slot.E]
	e.cooldown.start(10.0)
	_enemy(10.0).take_damage(_true_hit(50.0))
	assert_almost_eq(e.cooldown.remaining, 10.0, 0.001)
