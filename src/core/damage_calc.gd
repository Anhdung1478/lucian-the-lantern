class_name DamageCalc
extends RefCounted
## Damage formulas (LoL armor / MR curve).


static func resist_multiplier(resist: float) -> float:
	if resist >= 0.0:
		return 100.0 / (100.0 + resist)
	return 2.0 - 100.0 / (100.0 - resist)


static func mitigate(amount: float, type: DamageInfo.Type, armor: float, mr: float) -> float:
	match type:
		DamageInfo.Type.PHYSICAL:
			return amount * resist_multiplier(armor)
		DamageInfo.Type.MAGIC:
			return amount * resist_multiplier(mr)
	return amount


## `roll` is a random value in [0, 1), passed in so callers and tests control it.
static func is_crit(chance: float, roll: float) -> bool:
	return roll < chance


## Damage multiplier for a piercing shot that already hit `prior_hits` enemies.
static func falloff_multiplier(prior_hits: int, per_hit: float, minimum: float) -> float:
	return maxf(minimum, 1.0 - per_hit * prior_hits)
