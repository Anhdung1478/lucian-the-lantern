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


func _mini_boss() -> EnemyData:
	var data := EnemyData.new()
	data.kind = &"mini_boss"
	data.gold = 400
	data.xp = 200
	return data


func test_a_mini_boss_gives_50_blue_and_3_orange_in_any_act() -> void:
	for act in [1, 3]:
		var reward := KillRewards.roll(_mini_boss(), act, StageSetup.new(), rng)
		assert_eq(reward.blue, 50, "act %d" % act)
		assert_eq(reward.orange, 3, "act %d" % act)


func test_a_mini_boss_reward_does_not_scale_by_act() -> void:
	assert_eq(KillRewards.roll(_mini_boss(), 3, StageSetup.new(), rng).gold, 400)
	assert_eq(_mini_boss().hp_scale(3, 4), 1.0)
	assert_eq(_mini_boss().damage_scale(3, 4), 1.0)


## The Rift Scuttler: an elite's rewards, plus 45 blue and 4 orange.
func test_extra_essence_comes_on_top_of_the_kind() -> void:
	var scuttler: EnemyData = SIEGE.duplicate()
	scuttler.extra_blue = 45
	scuttler.extra_orange = 4
	rng.seed = 3
	var base := KillRewards.roll(SIEGE, 1, StageSetup.new(), rng)
	rng.seed = 3
	var reward := KillRewards.roll(scuttler, 1, StageSetup.new(), rng)
	assert_eq(reward.blue, base.blue + 45)
	assert_eq(reward.orange, base.orange + 4)
	assert_eq(reward.gold, base.gold)


## Phase 8: a summon (a Maiden's ghoul, a Broodmother's spiderling) pays a
## quarter of its gold and XP, rounded, and no essence at all.
func test_a_summon_pays_a_quarter_of_its_gold_and_xp() -> void:
	# A melee minion pays 60 gold and 30 XP in Act 1, x1.25 in Act 2.
	var reward := KillRewards.roll(MELEE, 2, StageSetup.new(), rng, true)
	assert_eq(reward.gold, 19, "75 x 25% = 18.75")
	assert_eq(reward.xp, 9, "37.5 x 25% = 9.375")
	assert_eq(reward.blue, 0)
	assert_eq(reward.orange, 0)


func test_a_summon_pays_its_quarter_after_the_tree_bonuses() -> void:
	var run := StageSetup.new()
	run.gold_bonus = 0.3
	run.xp_bonus = 0.2
	run.essence_bonus = 0.5
	var reward := KillRewards.roll(SIEGE, 1, run, rng, true)
	assert_eq(reward.gold, 39, "156 x 25%")
	assert_eq(reward.xp, 18, "72 x 25%")
	assert_eq(reward.blue, 0)


func test_a_summon_never_pays_essence_whatever_its_kind_or_extras() -> void:
	var summon: EnemyData = SIEGE.duplicate()
	summon.extra_blue = 45
	summon.extra_orange = 4
	for kind in [&"normal", &"elite", &"mini_boss", &"boss"]:
		summon.kind = kind
		var essence := 0
		# Enough rolls for an elite's 10% orange to come up if it could.
		for i in 200:
			var reward := KillRewards.roll(summon, 3, StageSetup.new(), rng, true)
			essence += reward.blue + reward.orange
		assert_eq(essence, 0, String(kind))


func test_not_a_summon_by_default() -> void:
	rng.seed = 7
	var plain := KillRewards.roll(SIEGE, 2, StageSetup.new(), rng)
	rng.seed = 7
	assert_eq(KillRewards.roll(SIEGE, 2, StageSetup.new(), rng, false), plain)
