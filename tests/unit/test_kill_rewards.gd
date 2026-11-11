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


func test_a_boss_scale_multiplies_a_bosss_blue_and_sure_orange() -> void:
	var boss := _mini_boss()
	boss.kind = &"boss"
	var tiers := {1.0: [100, 5], 1.3: [130, 7], 1.6: [160, 8]}
	for scale: float in tiers:
		var reward := KillRewards.roll(boss, 1, StageSetup.new(), rng, false, scale)
		assert_eq([reward.blue, reward.orange], tiers[scale], "×%s" % scale)
	assert_eq(KillRewards.roll(boss, 1, StageSetup.new(), rng).blue, 100, "unscaled by default")


func test_a_boss_scale_multiplies_a_mini_bosss_blue_and_orange_but_not_gold() -> void:
	var reward := KillRewards.roll(_mini_boss(), 1, StageSetup.new(), rng, false, 1.3)
	assert_eq([reward.blue, reward.orange], [65, 4])
	assert_eq(reward.gold, 400)
	assert_eq(reward.xp, 200)


func test_a_boss_scale_leaves_normals_and_summons_alone() -> void:
	assert_eq(KillRewards.roll(SIEGE, 2, StageSetup.new(), rng, false, 2.0).blue, 10)
	assert_eq(KillRewards.roll(_mini_boss(), 1, StageSetup.new(), rng, true, 2.0).blue, 0)


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


## V1.5 (P3): Act 3's monsters pay their stage's gold share; XP and essence
## don't change.
func test_act_3_s_monsters_pay_70_percent_more_gold_in_its_stages() -> void:
	var raptor: EnemyData = load("res://data/enemies/raptor.tres")
	var sentinel: EnemyData = load("res://data/enemies/blue_sentinel.tres")
	var plain := KillRewards.roll(raptor, 3, StageSetup.new(), rng)
	for number in range(1, 6):
		var run := StageSetup.new()
		run.stage_id = Journey.stage_id(3, number)
		var reward := KillRewards.roll(raptor, 3, run, rng)
		assert_eq(reward.gold, roundi(20 * 1.5 * 1.7), run.stage_id)
		assert_eq([reward.xp, reward.blue], [plain.xp, plain.blue], run.stage_id)
		assert_eq(KillRewards.roll(sentinel, 3, run, rng).gold, roundi(160 * 1.5 * 1.7), "%s: elites too" % run.stage_id)


func test_the_gold_share_leaves_other_stages_bosses_and_endless_alone() -> void:
	assert_eq(WavePlan.gold_share("2-3", WavePlan.MELEE), 1.0)
	assert_eq(WavePlan.gold_share("4-1", WavePlan.SHADOW_MELEE), 1.0)
	assert_eq(WavePlan.gold_share("5-2", WavePlan.SPIDERLING), 1.0)
	assert_eq(WavePlan.gold_share("3-2", WavePlan.INFERNAL_DRAKE), 1.0, "a mini boss")
	assert_eq(WavePlan.gold_share("3-5", &"elder_dragon"), 1.0, "a boss")
	assert_eq(WavePlan.gold_share(EndlessPlan.STAGE_ID, &"raptor"), 1.0, "Endless pays its own way")
	assert_eq(WavePlan.gold_share("", &"raptor"), 1.0, "the sandbox")


## The gold every kill in a story stage's first `waves` waves pays (all of
## them for -1), an Ancient Krug's splits included, with no tree bonus.
func _stage_gold(act: int, number: int, waves := -1) -> int:
	var run := StageSetup.new()
	run.act = act
	run.stage_id = Journey.stage_id(act, number)
	var plan := WavePlan.waves(run.stage_id)
	var gold := 0
	for wave: Array in plan.slice(0, plan.size() if waves < 0 else waves):
		for id: StringName in wave:
			var data: EnemyData = load("res://data/enemies/%s.tres" % id)
			gold += KillRewards.roll(data, act, run, rng).gold
			if data.split_into != &"":
				var split: EnemyData = load("res://data/enemies/%s.tres" % data.split_into)
				gold += data.split_count * KillRewards.roll(split, act, run, rng).gold
	return gold


func _act_gold(act: int) -> float:
	var total := 0
	for number in range(1, Journey.stage_count(act) + 1):
		total += _stage_gold(act, number)
	return float(total) / Journey.stage_count(act)


## The cheapest fragment (Tear of the Goddess, 650 from V1.5) at 3-1's first break.
func test_3_1_s_first_break_pays_for_the_cheapest_fragment() -> void:
	assert_gte(_stage_gold(3, 1, 1), 650)


func test_act_3_s_stages_pay_near_the_line_between_act_2_s_and_act_4_s() -> void:
	var line := (_act_gold(2) + _act_gold(4)) / 2.0
	var act_3 := _act_gold(3)
	assert_between(act_3, line * 0.9, _act_gold(4), "Act 2 %d, Act 3 %d, Act 4 %d" % [_act_gold(2), act_3, _act_gold(4)])


## V1.5 (P6): a normal's and an elite's orange chance × (1 + 0.2 × (act − 1)).
func test_the_orange_chance_grows_with_the_act() -> void:
	var run := StageSetup.new()
	for act in range(1, 7):
		var growth := 1.0 + 0.2 * (act - 1)
		assert_almost_eq(KillRewards.orange_chance(&"normal", act, run), 0.01 * growth, 0.00001, "a normal in act %d" % act)
		assert_almost_eq(KillRewards.orange_chance(&"elite", act, run), 0.1 * growth, 0.00001, "an elite in act %d" % act)
	assert_almost_eq(KillRewards.orange_chance(&"elite", 6, run), 0.2, 0.00001, "×2 in Act 6")


func test_the_act_s_growth_stacks_with_the_tree_and_an_endless_modifier() -> void:
	var run := StageSetup.new()
	run.essence_bonus = 0.5
	run.orange_mult = 1.5
	assert_almost_eq(KillRewards.orange_chance(&"elite", 3, run), 0.1 * 1.4 * 1.5 * 1.5, 0.00001)


func test_act_6_s_normals_drop_orange_twice_as_often() -> void:
	var orange := 0
	for i in 10000:
		orange += KillRewards.roll(MELEE, 6, StageSetup.new(), rng).orange
	assert_between(orange, 140, 260, "2%")


## V1.5 (P13): an elite killed by Smite has 3× the orange chance, on top of
## the act's growth and the difficulty's essence scale.
func test_an_elite_killed_by_smite_has_three_times_the_orange_chance() -> void:
	var run := StageSetup.new()
	assert_almost_eq(KillRewards.orange_chance(&"elite", 1, run, true), 0.3, 0.00001)
	assert_almost_eq(KillRewards.orange_chance(&"normal", 1, run, true), 0.01, 0.00001, "a normal: no bonus")
	assert_almost_eq(KillRewards.orange_chance(&"elite", 1, run), 0.1, 0.00001, "not by default")
	run.difficulty = Difficulty.EXTREME
	assert_almost_eq(KillRewards.orange_chance(&"elite", 6, run, true), 0.1 * 2.0 * 3.0 * 1.5, 0.00001, "stacks")


func test_roll_passes_a_smite_kill_to_the_orange_chance() -> void:
	var run := StageSetup.new()
	run.orange_mult = 3.4
	var plain := 0
	var smitten := 0
	for i in 200:
		plain += KillRewards.roll(SIEGE, 1, run, rng).orange
		smitten += KillRewards.roll(SIEGE, 1, run, rng, false, 1.0, true).orange
	assert_lt(plain, 200, "34%")
	assert_eq(smitten, 200, "102%: always")


func test_a_boss_s_sure_orange_does_not_grow_with_the_act() -> void:
	var boss := _mini_boss()
	boss.kind = &"boss"
	assert_eq(KillRewards.roll(boss, 6, StageSetup.new(), rng).orange, KillRewards.BOSS_ORANGE)
	assert_eq(KillRewards.roll(_mini_boss(), 6, StageSetup.new(), rng).orange, KillRewards.MINI_BOSS_ORANGE)
