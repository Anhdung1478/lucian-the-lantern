class_name KillRewards
extends RefCounted
## What a kill gives (design doc §9): stage gold (× its stage's
## WavePlan.gold_share) and XP for the run, blue and orange essence for
## good, plus the data's extra essence. Boss and mini boss purple comes
## from SaveGame.award_boss. The tree's Stage Gold, Bonus
## XP and Essence Drops raise them, then an Endless modifier's multipliers
## (StageSetup.gold_mult, blue_mult, orange_mult; XP has none), and the
## difficulty's essence (Difficulty.essence_scale: blue, the orange chance
## and sure orange). Pure: the randomness comes from `rng`.

const ORANGE_CHANCE := {&"normal": 0.01, &"elite": 0.1}
## The orange chance grows by this share of itself per act after the first:
## ×1.0 in Act 1 up to ×2.0 in Act 6.
const ORANGE_ACT_GROWTH := 0.2
## An elite killed by Smite: its orange chance × this.
const SMITE_ELITE_ORANGE := 3.0
const ELITE_BLUE := 5
const BOSS_BLUE := 100
const BOSS_ORANGE := 5
const MINI_BOSS_BLUE := 50
const MINI_BOSS_ORANGE := 3
## A summon's share of its gold and XP (a Maiden's ghoul): no farming.
const SUMMON_SHARE := 0.25


## A `summoned` enemy pays SUMMON_SHARE of its gold and XP, rounded, and no
## essence at all (its kind's and its data's extra included). A boss's or
## mini boss's base blue and sure orange are multiplied by `boss_scale`
## (Endless's tier, EndlessPlan.reward_scale), rounded; gold, XP and the
## data's extras are not. Sure orange, the boss's and the data's extra, is
## multiplied by the difficulty's essence scale, rounded. `smite_kill`:
## Smite's hit killed it (Enemy.killed_by), which raises an elite's orange
## chance. `traited`: an elite with a trait, which pays EliteTrait.PAY_BONUS
## more gold and XP.
static func roll(data: EnemyData, act: int, run: StageSetup, rng: RandomNumberGenerator, summoned := false, boss_scale := 1.0, smite_kill := false, traited := false) -> Dictionary:
	var scale := data.reward_scale(act) * (SUMMON_SHARE if summoned else 1.0) * (1.0 + EliteTrait.PAY_BONUS if traited else 1.0)
	var reward := {
		"gold": roundi(data.gold * scale * WavePlan.gold_share(run.stage_id, data.id) * (1.0 + run.gold_bonus) * run.gold_mult),
		"xp": roundi(data.xp * scale * (1.0 + run.xp_bonus)),
		"blue": 0,
		"orange": 0,
	}
	if summoned:
		return reward
	var essence := Difficulty.essence_scale(run.difficulty)
	var blue := act
	if data.kind == &"boss":
		blue = roundi(BOSS_BLUE * boss_scale)
		reward.orange = roundi(BOSS_ORANGE * boss_scale * essence)
	elif data.kind == &"mini_boss":
		blue = roundi(MINI_BOSS_BLUE * boss_scale)
		reward.orange = roundi(MINI_BOSS_ORANGE * boss_scale * essence)
	else:
		if data.kind == &"elite":
			blue = act * ELITE_BLUE
		if rng.randf() < orange_chance(data.kind, act, run, smite_kill):
			reward.orange = 1
	reward.blue = roundi((blue + data.extra_blue) * (1.0 + run.essence_bonus) * run.blue_mult * essence)
	reward.orange += roundi(data.extra_orange * essence)
	return reward


## A normal's or an elite's chance to drop an orange essence in `act`: its
## kind's, grown by the act (× SMITE_ELITE_ORANGE for an elite Smite killed),
## then raised by the tree's Essence Drops, an Endless modifier's orange
## multiplier and the difficulty's essence scale.
static func orange_chance(kind: StringName, act: int, run: StageSetup, smite_kill := false) -> float:
	var grown: float = ORANGE_CHANCE[kind] * (1.0 + ORANGE_ACT_GROWTH * (act - 1))
	if smite_kill and kind == &"elite":
		grown *= SMITE_ELITE_ORANGE
	return grown * (1.0 + run.essence_bonus) * run.orange_mult * Difficulty.essence_scale(run.difficulty)


## Endless: the purple a boss or mini boss pays on every kill, its repeat
## purple × the run's purple multiplier.
static func repeat_purple(data: EnemyData, run: StageSetup) -> int:
	return roundi(data.purple_repeat * run.purple_mult)
