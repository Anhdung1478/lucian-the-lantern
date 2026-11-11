extends GutTest
## R1: Resolve. Each defeat on a story stage not yet cleared gives a stack
## there, up to 5: more damage dealt and less taken, 10% a stack on Easy and
## Normal, 5% on Hard, none on Extreme, until the stage is cleared.


# --- The rule ------------------------------------------------------------------


func test_a_stack_is_worth_10_percent_5_on_hard_and_nothing_on_extreme() -> void:
	assert_eq(Difficulty.LEVELS.map(func(level: int) -> float: return Difficulty.resolve_step(level)), [0.1, 0.1, 0.05, 0.0])
	assert_eq(Difficulty.resolve_step(7), 0.1, "an unknown level is Normal")


func test_each_defeat_is_a_stack_up_to_5() -> void:
	assert_eq(Resolve.MAX_STACKS, 5)
	for level in [Difficulty.EASY, Difficulty.NORMAL, Difficulty.HARD]:
		assert_eq(range(8).map(func(defeats: int) -> int: return Resolve.stacks(defeats, level)), [0, 1, 2, 3, 4, 5, 5, 5],
			Difficulty.name_of(level))
	assert_eq(Resolve.stacks(3, Difficulty.EXTREME), 0, "Extreme has no Resolve")
	assert_eq(Resolve.stacks(-2, Difficulty.NORMAL), 0)


func test_a_stack_raises_the_damage_dealt_and_lowers_the_damage_taken() -> void:
	for level in [Difficulty.EASY, Difficulty.NORMAL]:
		assert_almost_eq(Resolve.damage_dealt_scale(0, level), 1.0, 0.0001)
		assert_almost_eq(Resolve.damage_taken_scale(0, level), 1.0, 0.0001)
		assert_almost_eq(Resolve.damage_dealt_scale(3, level), 1.3, 0.0001, Difficulty.name_of(level))
		assert_almost_eq(Resolve.damage_taken_scale(3, level), 0.7, 0.0001, Difficulty.name_of(level))
		assert_almost_eq(Resolve.damage_dealt_scale(5, level), 1.5, 0.0001)
		assert_almost_eq(Resolve.damage_taken_scale(5, level), 0.5, 0.0001, "5 stacks halve it")
	assert_almost_eq(Resolve.damage_dealt_scale(5, Difficulty.HARD), 1.25, 0.0001)
	assert_almost_eq(Resolve.damage_taken_scale(5, Difficulty.HARD), 0.75, 0.0001)
	assert_almost_eq(Resolve.damage_dealt_scale(2, Difficulty.HARD), 1.1, 0.0001)
	assert_almost_eq(Resolve.damage_dealt_scale(5, Difficulty.EXTREME), 1.0, 0.0001)
	assert_almost_eq(Resolve.damage_taken_scale(5, Difficulty.EXTREME), 1.0, 0.0001)
	assert_eq([Resolve.percent(3, Difficulty.NORMAL), Resolve.percent(3, Difficulty.HARD), Resolve.percent(5, Difficulty.EASY)], [30, 15, 50])


# --- On Lucian -----------------------------------------------------------------


func _lucian(stacks: int, level := Difficulty.NORMAL) -> Lucian:
	var lucian: Lucian = load("res://src/lucian/lucian.tscn").instantiate()
	# Shots and trails go here and are freed with it.
	lucian.projectile_parent = add_child_autofree(Node2D.new())
	add_child_autofree(lucian)
	var setup := StageSetup.new()
	setup.difficulty = level
	setup.resolve = stacks
	setup.defeats = stacks
	lucian.apply_setup(setup)
	return lucian


## A plain enemy with no armor.
func _enemy(hp := 10000.0) -> Enemy:
	var enemy := Enemy.new()
	enemy.max_hp = hp
	enemy.position = Vector2(300, 0)
	add_child_autofree(enemy)
	return enemy


func test_lucian_takes_less_with_each_stack_on_top_of_the_difficulty() -> void:
	var expected := {Difficulty.EASY: 0.8 * 0.7, Difficulty.NORMAL: 0.7, Difficulty.HARD: 1.1 * 0.85, Difficulty.EXTREME: 1.3}
	for level: int in expected:
		var lucian := _lucian(3, level)
		assert_almost_eq(lucian.damage_taken_scale, expected[level], 0.0001, Difficulty.name_of(level))
		var before := lucian.hp
		lucian.take_damage(DamageInfo.create(100.0, DamageInfo.Type.TRUE, &"test"))
		assert_almost_eq(before - lucian.hp, 100.0 * expected[level], 0.01, Difficulty.name_of(level))
	var none := _lucian(0, Difficulty.HARD)
	assert_almost_eq(none.damage_taken_scale, 1.1, 0.0001, "no stack: the difficulty alone")
	assert_almost_eq(_lucian(5).damage_taken_scale, 0.5, 0.0001, "5 stacks halve it")


func test_lucian_deals_more_with_each_stack_whatever_the_source() -> void:
	var lucian := _lucian(3)
	assert_almost_eq(lucian.damage_dealt_scale, 1.3, 0.0001)
	var enemy := _enemy()
	for source: StringName in [&"basic", &"lightslinger", &"q", &"r", &"hextech_gunblade", &"smite"]:
		assert_almost_eq(enemy.take_damage(lucian.make_damage(100.0, DamageInfo.Type.TRUE, source)), 130.0, 0.01, String(source))
	assert_almost_eq(enemy.take_damage(lucian.roll_attack(1.0, &"basic")), lucian.stats.ad * 1.3, 0.01, "an attack, before armor")
	assert_almost_eq(_enemy().take_damage(_lucian(2, Difficulty.HARD).make_damage(100.0, DamageInfo.Type.TRUE, &"q")), 110.0, 0.01, "Hard: 5% a stack")
	assert_almost_eq(_enemy().take_damage(_lucian(0).make_damage(100.0, DamageInfo.Type.TRUE, &"q")), 100.0, 0.01, "no stack")


func test_the_burns_lucian_applies_tick_harder_too() -> void:
	var lucian := _lucian(5)
	var enemy := _enemy()
	enemy.add_burn(&"test", 20.0, 1.0, DamageInfo.Type.TRUE, lucian)
	await wait_physics_frames(roundi(DamageOverTime.TICK * Engine.physics_ticks_per_second) + 2)
	assert_almost_eq(enemy.max_hp - enemy.hp, 20.0 * DamageOverTime.TICK * 1.5, 0.01, "one tick, half as much again")


func test_another_attackers_hit_is_not_raised() -> void:
	_lucian(5)
	var enemy := _enemy()
	assert_almost_eq(enemy.take_damage(DamageInfo.create(100.0, DamageInfo.Type.TRUE, &"test")), 100.0, 0.01, "nobody's hit")
	var senna := Node2D.new()
	add_child_autofree(senna)
	assert_almost_eq(enemy.take_damage(DamageInfo.create(100.0, DamageInfo.Type.TRUE, &"senna", senna)), 100.0, 0.01, "an ally's hit")


func test_set_resolve_changes_both_shares_at_once() -> void:
	var lucian := _lucian(4)
	lucian.set_resolve(0)
	assert_eq([lucian.resolve, lucian.damage_dealt_scale, lucian.damage_taken_scale], [0, 1.0, 1.0])
	lucian.set_resolve(2, 6)
	assert_eq([lucian.resolve, lucian.defeats], [2, 6])
	assert_almost_eq(lucian.damage_dealt_scale, 1.2, 0.0001)
	assert_almost_eq(lucian.damage_taken_scale, 0.8, 0.0001)
