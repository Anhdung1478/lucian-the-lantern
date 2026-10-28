class_name KillRewards
extends RefCounted
## What a kill gives (design doc §9): stage gold and XP for the run, blue
## and orange essence for good. Boss purple comes from SaveGame.award_boss.
## The tree's Stage Gold, Bonus XP and Essence Drops raise them. Pure: the
## randomness comes from `rng`.

const ORANGE_CHANCE := {&"normal": 0.01, &"elite": 0.1}
const ELITE_BLUE := 5
const BOSS_BLUE := 100
const BOSS_ORANGE := 5


static func roll(data: EnemyData, act: int, run: StageSetup, rng: RandomNumberGenerator) -> Dictionary:
	var scale := data.reward_scale(act)
	var reward := {
		"gold": roundi(data.gold * scale * (1.0 + run.gold_bonus)),
		"xp": roundi(data.xp * scale * (1.0 + run.xp_bonus)),
		"blue": 0,
		"orange": 0,
	}
	var blue := act
	if data.kind == &"boss":
		blue = BOSS_BLUE
		reward.orange = BOSS_ORANGE
	else:
		if data.kind == &"elite":
			blue = act * ELITE_BLUE
		if rng.randf() < ORANGE_CHANCE[data.kind] * (1.0 + run.essence_bonus):
			reward.orange = 1
	reward.blue = roundi(blue * (1.0 + run.essence_bonus))
	return reward
