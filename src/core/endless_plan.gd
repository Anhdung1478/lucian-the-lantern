class_name EndlessPlan
extends RefCounted
## Endless mode's waves, strength and maps (design: Endless mode). Every
## 10th wave is one boss alone; every other 5th wave is a normal wave with a
## mini boss last; any other wave is normal: enemies of 2 kinds from NORMALS
## plus a few elites. Neither a boss nor a mini boss comes twice in a row.
## The waves draw only from the acts the save has cleared (cleared_pool).
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
## × (1 + TIER_HP(k−1)), k being the tier; a boss has at least
## BOSS_WAVE_SHARE of the HP the wave before it brings (wave_hp). Damage ×
## (1 + TIER_POWER(k−1)), or the square root of how much damage_scale has
## grown since the kind's first wave when that is more (×1 at tier 1).
const BOSS_HP := 15000.0
const MINI_BOSS_HP := 9000.0
const TIER_HP := 0.3
const TIER_POWER := 0.15
const BOSS_WAVE_SHARE := 0.6
## A boss or mini boss from Act LATE_ACT on deals LATE_POWER[k − 1] of its
## power at tier k (1 and 2), then all of it.
const LATE_ACT := 5
const LATE_POWER: Array[float] = [0.8, 0.9]
## Kills pay like act 1 + (w − 1) / REWARD_ACT_WAVES, at least like the
## acts the save has cleared, at most like the last act.
const REWARD_ACT_WAVES := 10
## Wave -> Vector2i(blue, orange) paid the first time a save wins that wave
## (SaveGame.endless_milestones), as is: no bonus or multiplier raises it.
const MILESTONES := {
	10: Vector2i(300, 5),
	20: Vector2i(600, 10),
	30: Vector2i(900, 15),
	40: Vector2i(1200, 20),
}

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

## Pool id -> its act, filled on act_of's first call.
static var _acts := {}


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
## the elites, then the mini boss; or the boss alone, all from the first
## `acts` acts (cleared_pool). `last_boss` and `last_mini_boss` are the run's
## previous picks, never picked again here.
static func wave(w: int, rng: RandomNumberGenerator, elite_mult := 1, last_boss := &"", last_mini_boss := &"", acts := Journey.ACTS.size()) -> Array[StringName]:
	var groups := []
	if is_boss_wave(w):
		groups.append([pick_boss(rng, last_boss, acts), 1])
	else:
		groups.append_array(_normals(normal_count(w), rng, acts))
		var elites := cleared_pool(ELITES, acts)
		for i in elite_count(w, elite_mult):
			groups.append([elites[rng.randi_range(0, elites.size() - 1)], 1])
		if is_mini_boss_wave(w):
			groups.append([pick_mini_boss(rng, last_mini_boss, acts), 1])
	var ids: Array[StringName] = []
	ids.assign(WavePlan.expand([groups])[0])
	return ids


## A random boss of the first `acts` acts, never `last`.
static func pick_boss(rng: RandomNumberGenerator, last := &"", acts := Journey.ACTS.size()) -> StringName:
	return _pick(cleared_pool(BOSSES, acts), rng, last)


## A random mini boss of the first `acts` acts, never `last`.
static func pick_mini_boss(rng: RandomNumberGenerator, last := &"", acts := Journey.ACTS.size()) -> StringName:
	return _pick(cleared_pool(MINI_BOSSES, acts), rng, last)


## The ids of `pool` whose act (act_of) is one of the first `acts`, at least
## the Journey.ENDLESS_ACT acts Endless opens after: never too few to pick
## from (Acts 1–3 give 6 normals, 5 elites, 2 mini bosses and 2 bosses).
static func cleared_pool(pool: Array[StringName], acts: int) -> Array[StringName]:
	var last := maxi(acts, Journey.ENDLESS_ACT)
	var found: Array[StringName] = []
	for id in pool:
		if act_of(id) <= last:
			found.append(id)
	return found


## The act whose story brings pool id `id` (an enemy, a pack or a boss)
## first, in WavePlan's stages; 0 when none does.
static func act_of(id: StringName) -> int:
	if _acts.is_empty():
		for act in range(1, Journey.ACTS.size() + 1):
			for stage in range(1, Journey.stage_count(act) + 1):
				var stage_id := Journey.stage_id(act, stage)
				var ids: Array = [WavePlan.boss(stage_id)]
				for wave_groups: Array in WavePlan.STAGES.get(stage_id, []):
					for group: Array in wave_groups:
						ids.append(group[0])
				for found: StringName in ids:
					if found != &"" and not _acts.has(found):
						_acts[found] = act
	return _acts.get(id, 0)


## A normal or elite enemy's HP multiplier in wave `w` (in place of
## EnemyData.hp_scale).
static func hp_scale(w: int) -> float:
	var n := maxi(w - 1, 0)
	return (1.0 + HP_GROWTH * n) * (1.0 + WAVE_GROWTH * n)


## A normal or elite enemy's damage multiplier in wave `w`.
static func damage_scale(w: int) -> float:
	var n := maxi(w - 1, 0)
	return (1.0 + DAMAGE_GROWTH * n) * (1.0 + WAVE_GROWTH * n)


## The HP normal wave `w` brings as planned, before the difficulty: its
## normal_count normal enemies at the normal pool's mean HP, its elite_count
## elites at the elite pool's (both of the first `acts` acts), × hp_scale(w).
## The draw is random, so this is its expected total: the same every run. 0
## before wave 1.
static func wave_hp(w: int, acts := Journey.ACTS.size()) -> float:
	if w < 1:
		return 0.0
	return (normal_count(w) * _mean_hp(cleared_pool(NORMALS, acts)) + elite_count(w) * _mean_hp(cleared_pool(ELITES, acts))) * hp_scale(w)


## A boss's max HP in wave `w` (each phase, for Thresh): its tier's, or
## BOSS_WAVE_SHARE of the wave before's HP when that is more.
static func boss_hp(w: int, acts := Journey.ACTS.size()) -> float:
	return maxf(BOSS_HP * (1.0 + TIER_HP * (_boss_tier(w) - 1)), BOSS_WAVE_SHARE * wave_hp(w - 1, acts))


static func mini_boss_hp(w: int) -> float:
	return MINI_BOSS_HP * (1.0 + TIER_HP * (_mini_boss_tier(w) - 1))


## Boss `id`'s damage multiplier in wave `w`: its basic attack and every
## skill hit. Its tier's, or the square root of the normal damage_scale's
## growth since the first boss wave (BOSS_EVERY) when that is more, so it
## keeps up with the waves and the first boss is ×1; × its late_share.
static func boss_power(w: int, id := &"") -> float:
	var tier := _boss_tier(w)
	return _power(tier, w, BOSS_EVERY) * late_share(id, tier)


## Mini boss `id`'s damage multiplier in wave `w`, as a boss's, grown since
## the first mini boss wave (MINI_BOSS_EVERY).
static func mini_boss_power(w: int, id := &"") -> float:
	var tier := _mini_boss_tier(w)
	return _power(tier, w, MINI_BOSS_EVERY) * late_share(id, tier)


## The share of its power boss or mini boss `id` deals at tier `tier`:
## LATE_POWER's at tiers 1 and 2 for one from Act LATE_ACT on, else all.
static func late_share(id: StringName, tier: int) -> float:
	if act_of(id) < LATE_ACT or tier > LATE_POWER.size():
		return 1.0
	return LATE_POWER[tier - 1]


## What a boss or mini boss in wave `w` pays more blue and orange essence
## than in the story: its tier's HP factor (not a boss's wave_hp floor), 1
## at tier 1 and +0.3 a tier. Anything else pays 1.0.
static func reward_scale(kind: StringName, w: int) -> float:
	match kind:
		&"boss":
			return 1.0 + TIER_HP * (_boss_tier(w) - 1)
		&"mini_boss":
			return 1.0 + TIER_HP * (_mini_boss_tier(w) - 1)
	return 1.0


## The act whose gold, XP and blue a kill in wave `w` pays: one more every
## REWARD_ACT_WAVES waves, at least `acts_cleared` (the save's) and at most
## the last act.
static func reward_act(w: int, acts_cleared := 0) -> int:
	return mini(maxi(1 + maxi(w - 1, 0) / REWARD_ACT_WAVES, acts_cleared), Journey.ACTS.size())


## What winning wave `w` pays the first time, as Vector2i(blue, orange);
## ZERO for a wave with no milestone.
static func milestone(w: int) -> Vector2i:
	return MILESTONES.get(w, Vector2i.ZERO)


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


## A boss's or mini boss's power at tier `tier` in wave `w`, before its
## late_share: its tier's, or √(damage_scale(w) / damage_scale(first)) when
## that is more, `first` being its kind's first wave (so ×1 there, and
## before it).
static func _power(tier: int, w: int, first: int) -> float:
	return maxf(1.0 + TIER_POWER * (tier - 1), sqrt(damage_scale(w) / damage_scale(first)))


static func _pick(pool: Array[StringName], rng: RandomNumberGenerator, last: StringName) -> StringName:
	var choices: Array[StringName] = []
	for id in pool:
		if id != last:
			choices.append(id)
	return choices[rng.randi_range(0, choices.size() - 1)]


## `count` normal enemies of NORMAL_KINDS kinds drawn from the NORMALS of
## the first `acts` acts, as [id, n] groups. A pack comes whole: each step
## adds one more of the kind with the fewest enemies so far that still fits,
## so 2 packs can leave the wave up to 2 short.
static func _normals(count: int, rng: RandomNumberGenerator, acts: int) -> Array:
	var pool := cleared_pool(NORMALS, acts)
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


## One enemy's mean base HP in `pool`: each entry weighs the same, a pack
## as its members' mean.
static func _mean_hp(pool: Array[StringName]) -> float:
	var total := 0.0
	for id in pool:
		var members: Array = WavePlan.PACKS.get(id, [id])
		var hp := 0.0
		for member: StringName in members:
			hp += (load(Stage.ENEMY_PATH % member) as EnemyData).max_hp
		total += hp / members.size()
	return total / pool.size()


## Enemies a pool id brings: a pack's size, else 1.
static func _size(id: StringName) -> int:
	return WavePlan.PACKS.get(id, [id]).size()
