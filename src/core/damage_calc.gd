class_name DamageCalc
extends RefCounted
## Damage formulas (LoL armor / MR curve).


static func resist_multiplier(resist: float) -> float:
	if resist >= 0.0:
		return 100.0 / (100.0 + resist)
	return 2.0 - 100.0 / (100.0 - resist)


## Penetration only lowers a positive resist: percent first, then flat magic
## penetration, never below 0.
static func mitigate(amount: float, type: DamageInfo.Type, armor: float, mr: float,
		armor_pen := 0.0, magic_pen := 0.0, magic_pen_flat := 0.0) -> float:
	match type:
		DamageInfo.Type.PHYSICAL:
			return amount * resist_multiplier(_penetrate(armor, armor_pen))
		DamageInfo.Type.MAGIC:
			return amount * resist_multiplier(_penetrate(mr, magic_pen, magic_pen_flat))
	return amount


## `roll` is a random value in [0, 1), passed in so callers and tests control it.
static func is_crit(chance: float, roll: float) -> bool:
	return roll < chance


static func _penetrate(resist: float, pen: float, flat := 0.0) -> float:
	return maxf(resist * (1.0 - pen) - flat, 0.0) if resist > 0.0 else resist


## Damage multiplier for a piercing shot that already hit `prior_hits` enemies.
static func falloff_multiplier(prior_hits: int, per_hit: float, minimum: float) -> float:
	return maxf(minimum, 1.0 - per_hit * prior_hits)
