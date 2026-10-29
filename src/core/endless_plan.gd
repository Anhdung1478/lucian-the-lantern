class_name EndlessPlan
extends RefCounted
## Endless mode's waves, strength and maps (design: Endless mode). Every
## 10th wave is one boss alone; every other 5th wave is a normal wave with a
## mini boss last; any other wave is normal: enemies of 2 kinds from NORMALS
## plus a few elites. Neither a boss nor a mini boss comes twice in a row.
## Pure: the randomness comes from the run's `rng`.

## The ids waves draw from. A pack (WavePlan.PACKS) brings its members.
const NORMALS: Array[StringName] = [&"melee_minion", &"ranged_minion", &"shadow_melee_minion", &"shadow_ranged_minion", &"raptors", &"wolves", &"krugs", &"gromp", &"sapling", &"spiderling", &"mist_walker", &"lantern_soul"]
const ELITES: Array[StringName] = [&"siege_minion", &"super_minion", &"shadow_siege_minion", &"shadow_super_minion", &"blue_sentinel", &"red_brambleback", &"rift_scuttler", &"maiden_of_the_mist", &"broodmother", &"spectral_rider", &"chain_warden"]
const MINI_BOSSES: Array[StringName] = [&"infernal_drake", &"ocean_drake", &"maokai", &"elise", &"karthus_revived", &"hecarim"]
## Act 1's Thresh (thresh_1) is not one: he only comes in the story.
const BOSSES: Array[StringName] = [&"akshan", &"elder_dragon", &"dark_lucian", &"karthus", &"thresh_final"]

## Every BOSS_EVERY-th wave is a boss wave; every other MINI_BOSS_EVERY-th
## wave ends with a mini boss.
const BOSS_EVERY := 10
const MINI_BOSS_EVERY := 5
## A normal wave: BASE_NORMALS + w normal enemies, at most MAX_NORMALS, of
## NORMAL_KINDS kinds; plus w / WAVES_PER_ELITE elites, at most MAX_ELITES
## (both times the elite multiplier).
const BASE_NORMALS := 8
const MAX_NORMALS := 30
const NORMAL_KINDS := 2
const WAVES_PER_ELITE := 4
const MAX_ELITES := 4
## Normal and elite HP: base × (1 + HP_GROWTH(w−1)) × (1 + WAVE_GROWTH(w−1));
## damage the same with DAMAGE_GROWTH.
const HP_GROWTH := 0.06
const DAMAGE_GROWTH := 0.025
const WAVE_GROWTH := 0.05
## Boss and mini boss HP, fixed by wave whoever comes: BOSS_HP (MINI_BOSS_HP)
## × (1 + TIER_HP(k−1)), and damage × (1 + TIER_POWER(k−1)), k being the tier.
const BOSS_HP := 15000.0
const MINI_BOSS_HP := 9000.0
const TIER_HP := 0.3
const TIER_POWER := 0.15
## Kills pay like act 1 + (w − 1) / REWARD_ACT_WAVES.
const REWARD_ACT_WAVES := 10

## The run's StageSetup.stage_id.
const STAGE_ID := "endless"
## The Journey.ENDLESS_MAPS index that rolls one of the maps.
const RANDOM := 0
## Map choice (Journey.ENDLESS_MAPS index; choice i is act i) -> the act and
## the stage variant StageMaps builds it from: Training ground's ring of 10
## pillars, the Jungle's water and Honeyfruit, the Dead forest's mist banks
## and nest.
const MAPS := {
	1: Vector2i(1, 1),
	2: Vector2i(2, 3),
	3: Vector2i(3, 4),
	4: Vector2i(4, 1),
	5: Vector2i(5, 3),
	6: Vector2i(6, 1),
}


static func is_boss_wave(w: int) -> bool:
	return w > 0 and w % BOSS_EVERY == 0


static func is_mini_boss_wave(w: int) -> bool:
	return w > 0 and w % MINI_BOSS_EVERY == 0 and not is_boss_wave(w)


## Normal enemies in wave `w` (a pack counts as its size).
static func normal_count(w: int) -> int:
	return mini(BASE_NORMALS + w, MAX_NORMALS)


## Elites in wave `w`; modifier #2's `elite_mult` of 2 doubles them.
static func elite_count(w: int, elite_mult := 1) -> int:
	return mini(w / WAVES_PER_ELITE, MAX_ELITES) * elite_mult


## Wave `w`'s enemy ids in spawn order (WavePlan.expand): the normal enemies,
## the elites, then the mini boss; or the boss alone. `last_boss` and
## `last_mini_boss` are the run's previous picks, never picked again here.
static func wave(w: int, rng: RandomNumberGenerator, elite_mult := 1, last_boss := &"", last_mini_boss := &"") -> Array[StringName]:
	var groups := []
	if is_boss_wave(w):
		groups.append([pick_boss(rng, last_boss), 1])
	else:
		groups.append_array(_normals(normal_count(w), rng))
		for i in elite_count(w, elite_mult):
			groups.append([ELITES[rng.randi_range(0, ELITES.size() - 1)], 1])
		if is_mini_boss_wave(w):
			groups.append([pick_mini_boss(rng, last_mini_boss), 1])
	var ids: Array[StringName] = []
	ids.assign(WavePlan.expand([groups])[0])
	return ids


## A random boss, never `last`.
static func pick_boss(rng: RandomNumberGenerator, last := &"") -> StringName:
	return _pick(BOSSES, rng, last)


## A random mini boss, never `last`.
static func pick_mini_boss(rng: RandomNumberGenerator, last := &"") -> StringName:
	return _pick(MINI_BOSSES, rng, last)


## A normal or elite enemy's HP multiplier in wave `w` (in place of
## EnemyData.hp_scale).
static func hp_scale(w: int) -> float:
	var n := maxi(w - 1, 0)
	return (1.0 + HP_GROWTH * n) * (1.0 + WAVE_GROWTH * n)


## A normal or elite enemy's damage multiplier in wave `w`.
static func damage_scale(w: int) -> float:
	var n := maxi(w - 1, 0)
	return (1.0 + DAMAGE_GROWTH * n) * (1.0 + WAVE_GROWTH * n)


## A boss's max HP in wave `w` (each phase, for Thresh).
static func boss_hp(w: int) -> float:
	return BOSS_HP * (1.0 + TIER_HP * (_boss_tier(w) - 1))


static func mini_boss_hp(w: int) -> float:
	return MINI_BOSS_HP * (1.0 + TIER_HP * (_mini_boss_tier(w) - 1))


## A boss's damage multiplier in wave `w`: its basic attack and every skill hit.
static func boss_power(w: int) -> float:
	return 1.0 + TIER_POWER * (_boss_tier(w) - 1)


## A mini boss's damage multiplier in wave `w`.
static func mini_boss_power(w: int) -> float:
	return 1.0 + TIER_POWER * (_mini_boss_tier(w) - 1)


## The act whose gold, XP and blue a kill in wave `w` pays.
static func reward_act(w: int) -> int:
	return 1 + maxi(w - 1, 0) / REWARD_ACT_WAVES


## Map choice `choice` (1–6) as Vector2i(act, stage variant); ZERO for none.
static func map_for(choice: int) -> Vector2i:
	return MAPS.get(choice, Vector2i.ZERO)


static func map_name(choice: int) -> String:
	return Journey.ENDLESS_MAPS[choice]


## The map played for `choice`: itself, or for RANDOM (or an unknown choice)
## one of the maps rolled with `rng`.
static func resolve_map(choice: int, rng: RandomNumberGenerator) -> int:
	return choice if MAPS.has(choice) else rng.randi_range(1, MAPS.size())


## k: 1 for wave 10's boss, 2 for wave 20's... (1 when called up earlier).
static func _boss_tier(w: int) -> int:
	return maxi(w / BOSS_EVERY, 1)


## k: 1 for wave 5's mini boss, 2 for wave 15's... (1 when called up earlier).
static func _mini_boss_tier(w: int) -> int:
	return maxi((w + MINI_BOSS_EVERY) / BOSS_EVERY, 1)


static func _pick(pool: Array[StringName], rng: RandomNumberGenerator, last: StringName) -> StringName:
	var choices: Array[StringName] = []
	for id in pool:
		if id != last:
			choices.append(id)
	return choices[rng.randi_range(0, choices.size() - 1)]


## `count` normal enemies of NORMAL_KINDS kinds drawn from NORMALS, as
## [id, n] groups. A pack comes whole: each step adds one more of the kind
## with the fewest enemies so far that still fits, so 2 packs can leave the
## wave up to 2 short.
static func _normals(count: int, rng: RandomNumberGenerator) -> Array:
	var pool := NORMALS.duplicate()
	var kinds: Array[StringName] = []
	var units: Array[int] = []
	var enemies: Array[int] = []
	for i in NORMAL_KINDS:
		kinds.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
		units.append(0)
		enemies.append(0)
	var total := 0
	while true:
		var next := -1
		for i in kinds.size():
			if total + _size(kinds[i]) <= count and (next < 0 or enemies[i] < enemies[next]):
				next = i
		if next < 0:
			break
		units[next] += 1
		enemies[next] += _size(kinds[next])
		total += _size(kinds[next])
	var groups := []
	for i in kinds.size():
		if units[i] > 0:
			groups.append([kinds[i], units[i]])
	return groups


## Enemies a pool id brings: a pack's size, else 1.
static func _size(id: StringName) -> int:
	return WavePlan.PACKS.get(id, [id]).size()
