class_name EndlessModifiers
extends RefCounted
## Endless mode's modifiers (design doc §14): after each boss wave the player
## picks one of three cards, two of #1–5 and Nothing (#6); the pick replaces
## the last one. Each is a downside and a reward. Data and pure helpers: the
## stage applies the enemy and Lucian effects, apply_rewards writes the reward
## multipliers on the run, and KillRewards reads them.

## No modifier yet: a run's start.
const NONE := 0
## The card that clears the modifier.
const NOTHING := 6
## Cards offered besides Nothing.
const OFFERED := 2
## The StageSetup reward multipliers a row can set; 1.0 when it doesn't.
const REWARDS: Array[StringName] = [&"gold_mult", &"blue_mult", &"orange_mult", &"purple_mult"]
## Id -> its card's two lines and icon, and what it changes (missing = none):
## - enemy_speed: enemies' move speed, at spawn;
## - elite_mult: EndlessPlan's elite count;
## - run_scale: Lucian's stats, applied like a skin's scale;
## - boss_hp: bosses' and mini bosses' max HP, at spawn;
## - gold_mult, blue_mult, orange_mult (the drop chance), purple_mult
##   (KillRewards.repeat_purple): the run's rewards.
const ROWS := {
	1: {
		"downside": "Enemies move 20% faster", "reward": "+30% gold",
		"icon": "res://assets/art/stats/move_speed.svg",
		"enemy_speed": 1.2, "gold_mult": 1.3,
	},
	2: {
		"downside": "Elites twice as often", "reward": "×1.5 orange drop rate",
		"icon": "res://assets/art/ui/essence_orange.svg",
		"elite_mult": 2, "orange_mult": 1.5,
	},
	3: {
		"downside": "−10% max HP", "reward": "+15% blue",
		"icon": "res://assets/art/stats/max_hp.svg",
		"run_scale": {&"max_hp": 0.9}, "blue_mult": 1.15,
	},
	4: {
		"downside": "−5% AD", "reward": "+10% gold",
		"icon": "res://assets/art/stats/ad.svg",
		"run_scale": {&"ad": 0.95}, "gold_mult": 1.1,
	},
	5: {
		"downside": "Bosses and mini bosses +25% max HP", "reward": "×1.5 purple",
		"icon": "res://assets/art/ui/skull.svg",
		"boss_hp": 1.25, "purple_mult": 1.5,
	},
	6: {"downside": "Nothing", "reward": "Nothing"},
}


## The cards after a boss wave: OFFERED of #1–5 at random, never `current`,
## then NOTHING.
static func offer(rng: RandomNumberGenerator, current: int) -> Array[int]:
	var pool: Array[int] = []
	for id in range(1, NOTHING):
		if id != current:
			pool.append(id)
	var cards: Array[int] = []
	for i in OFFERED:
		cards.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	cards.append(NOTHING)
	return cards


static func downside(id: int) -> String:
	return _row(id).get("downside", "")


static func reward(id: int) -> String:
	return _row(id).get("reward", "")


## Its card's icon; null for Nothing.
static func icon(id: int) -> Texture2D:
	var path: String = _row(id).get("icon", "")
	return load(path) if path != "" else null


static func enemy_speed(id: int) -> float:
	return _row(id).get("enemy_speed", 1.0)


static func elite_mult(id: int) -> int:
	return _row(id).get("elite_mult", 1)


## Lucian's stat multipliers, keyed like StatBlock (a skin's scale).
static func run_scale(id: int) -> Dictionary[StringName, float]:
	var scale: Dictionary[StringName, float] = {}
	scale.assign(_row(id).get("run_scale", {}))
	return scale


static func boss_hp(id: int) -> float:
	return _row(id).get("boss_hp", 1.0)


## Writes modifier `id`'s reward multipliers on `run`, the others back to 1:
## a new pick replaces the old one.
static func apply_rewards(run: StageSetup, id: int) -> void:
	for key in REWARDS:
		run.set(key, float(_row(id).get(key, 1.0)))


static func _row(id: int) -> Dictionary:
	return ROWS.get(id, {})
