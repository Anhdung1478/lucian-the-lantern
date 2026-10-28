extends GutTest

const MELEE := preload("res://data/enemies/melee_minion.tres")
const SIEGE := preload("res://data/enemies/siege_minion.tres")

var rng := RandomNumberGenerator.new()


func before_each() -> void:
	rng.seed = 7


func test_a_normal_kill_in_act_1() -> void:
	var reward := KillRewards.roll(MELEE, 1, StageSetup.new(), rng)
	assert_eq(reward.gold, 60)
	assert_eq(reward.xp, 30)
	assert_eq(reward.blue, 1)


func test_act_2_pays_more() -> void:
	var reward := KillRewards.roll(MELEE, 2, StageSetup.new(), rng)
	assert_eq(reward.gold, 75)
	assert_eq(reward.blue, 2)


func test_an_elite_gives_five_times_the_blue() -> void:
	assert_eq(KillRewards.roll(SIEGE, 2, StageSetup.new(), rng).blue, 10)


func test_tree_bonuses_multiply() -> void:
	var run := StageSetup.new()
	run.gold_bonus = 0.3
	run.xp_bonus = 0.2
	run.essence_bonus = 0.5
	var reward := KillRewards.roll(SIEGE, 1, run, rng)
	assert_eq(reward.gold, 156)
	assert_eq(reward.xp, 72)
	assert_eq(reward.blue, 8)


func test_orange_is_rare_from_normal_enemies() -> void:
	var orange := 0
	for i in 10000:
		orange += KillRewards.roll(MELEE, 1, StageSetup.new(), rng).orange
	assert_between(orange, 60, 140)
