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


## Phase 9: an Endless modifier's reward multipliers (StageSetup, 1 = none).
func test_the_reward_multipliers_are_1_by_default() -> void:
	var run := StageSetup.new()
	assert_eq(run.gold_mult, 1.0)
	assert_eq(run.blue_mult, 1.0)
	assert_eq(run.orange_mult, 1.0)
	assert_eq(run.purple_mult, 1.0)


func test_the_gold_multiplier_raises_the_gold_only() -> void:
	var run := StageSetup.new()
	run.gold_mult = 1.3
	var reward := KillRewards.roll(MELEE, 1, run, rng)
	assert_eq(reward.gold, 78, "60 x 1.3")
	assert_eq(reward.xp, 30, "XP is not multiplied")
	assert_eq(reward.blue, 1)


func test_the_gold_multiplier_comes_after_the_tree_bonus() -> void:
	var run := StageSetup.new()
	run.gold_bonus = 0.3
	run.gold_mult = 1.1
	assert_eq(KillRewards.roll(SIEGE, 1, run, rng).gold, 172, "120 x 1.3 x 1.1 = 171.6")


func test_the_blue_multiplier_raises_the_blue() -> void:
	var run := StageSetup.new()
	run.blue_mult = 1.15
	assert_eq(KillRewards.roll(SIEGE, 4, run, rng).blue, 23, "4 x 5 = 20, x 1.15")
	assert_eq(KillRewards.roll(MELEE, 4, run, rng).gold, KillRewards.roll(MELEE, 4, StageSetup.new(), rng).gold)


func test_the_orange_multiplier_raises_the_orange_chance() -> void:
	var run := StageSetup.new()
	run.orange_mult = 1.5
	var base := 0
	var raised := 0
	for i in 10000:
		base += KillRewards.roll(SIEGE, 1, StageSetup.new(), rng).orange
	rng.seed = 7
	for i in 10000:
		raised += KillRewards.roll(SIEGE, 1, run, rng).orange
	assert_between(base, 900, 1100, "an elite's 10%")
	assert_between(raised, 1350, 1650, "x 1.5")


func test_the_orange_multiplier_leaves_a_bosss_sure_orange() -> void:
	var run := StageSetup.new()
	run.orange_mult = 1.5
	assert_eq(KillRewards.roll(_mini_boss(), 1, run, rng).orange, KillRewards.MINI_BOSS_ORANGE)


func test_repeat_purple_is_raised_by_the_purple_multiplier() -> void:
	var boss := _mini_boss()
	boss.purple_repeat = 3
	var run := StageSetup.new()
	assert_eq(KillRewards.repeat_purple(boss, run), 3)
	run.purple_mult = 1.5
	assert_eq(KillRewards.repeat_purple(boss, run), 5, "roundi(4.5)")
	boss.purple_repeat = 10
	assert_eq(KillRewards.repeat_purple(boss, run), 15)
