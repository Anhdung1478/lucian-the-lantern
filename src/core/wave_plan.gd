class_name WavePlan
extends RefCounted
## Which enemies each wave of a stage brings (docs/act1_the_loss.md,
## docs/act2_the_sentinels.md, docs/act3_the_jungle.md), and each stage's
## boss. A wave can name a pack in place of an enemy id: it brings the
## pack's members, in order.

const MELEE := &"melee_minion"
const RANGED := &"ranged_minion"
const SIEGE := &"siege_minion"
const SUPER := &"super_minion"
## Act 3's elites, one at a time.
const BLUE_SENTINEL := &"blue_sentinel"
const RED_BRAMBLEBACK := &"red_brambleback"
const SCUTTLER := &"rift_scuttler"
## Act 3's mini bosses, each last in its stage's last wave.
const INFERNAL_DRAKE := &"infernal_drake"
const OCEAN_DRAKE := &"ocean_drake"
## Pack id -> its members, in spawn order. They come out of their camp.
const PACKS := {
	&"raptors": [&"raptor_big", &"raptor", &"raptor", &"raptor", &"raptor"],
	&"wolves": [&"murkwolf_big", &"murkwolf", &"murkwolf"],
	&"krugs": [&"krug_big", &"krug", &"krug"],
	&"gromp": [&"gromp"],
}
## Stage id -> waves; each wave lists [enemy or pack id, count] in spawn order.
const STAGES := {
	"1-1": [[[MELEE, 6], [RANGED, 4]], [[MELEE, 6], [RANGED, 6], [SIEGE, 1]]],
	"2-1": [[[MELEE, 6], [RANGED, 4], [SIEGE, 1]], [[MELEE, 6], [RANGED, 6], [SIEGE, 1], [SUPER, 1]]],
	"2-2": [[[MELEE, 6], [RANGED, 6], [SIEGE, 1]], [[MELEE, 6], [RANGED, 6], [SIEGE, 2]], [[MELEE, 6], [RANGED, 6], [SIEGE, 1], [SUPER, 1]]],
	"2-3": [[[MELEE, 6], [RANGED, 6], [SIEGE, 2]], [[MELEE, 6], [RANGED, 6], [SIEGE, 1], [SUPER, 1]], [[MELEE, 8], [RANGED, 6], [SIEGE, 2], [SUPER, 1]]],
	"3-1": [
		[[&"raptors", 1], [&"wolves", 1]],
		[[&"raptors", 2], [&"gromp", 1], [BLUE_SENTINEL, 1]],
		[[&"wolves", 1], [&"krugs", 1], [&"gromp", 1], [RED_BRAMBLEBACK, 1], [SCUTTLER, 1]],
	],
	"3-2": [
		[[&"raptors", 1], [&"wolves", 1], [&"gromp", 1]],
		[[&"raptors", 1], [&"krugs", 1], [&"wolves", 1], [BLUE_SENTINEL, 1]],
		[[&"wolves", 1], [&"krugs", 1], [&"gromp", 1], [RED_BRAMBLEBACK, 1], [SCUTTLER, 1]],
		[[&"raptors", 1], [&"wolves", 1], [&"krugs", 1], [&"gromp", 1], [INFERNAL_DRAKE, 1]],
	],
	"3-3": [
		[[&"raptors", 2], [&"wolves", 1], [&"gromp", 1]],
		[[&"krugs", 1], [&"wolves", 1], [&"gromp", 1], [BLUE_SENTINEL, 1]],
		[[&"raptors", 1], [&"wolves", 1], [&"krugs", 1], [RED_BRAMBLEBACK, 1], [SCUTTLER, 1]],
		[[&"raptors", 2], [&"wolves", 1], [&"krugs", 1], [&"gromp", 1], [BLUE_SENTINEL, 1]],
	],
	"3-4": [
		[[&"raptors", 1], [&"wolves", 1], [&"gromp", 1], [&"krugs", 1]],
		[[&"raptors", 1], [&"wolves", 1], [&"krugs", 1], [BLUE_SENTINEL, 1]],
		[[&"wolves", 1], [&"krugs", 1], [&"gromp", 1], [RED_BRAMBLEBACK, 1], [SCUTTLER, 1]],
		[[&"raptors", 2], [&"krugs", 1], [&"gromp", 1], [BLUE_SENTINEL, 1]],
		[[&"raptors", 1], [&"wolves", 1], [&"krugs", 1], [&"gromp", 1], [RED_BRAMBLEBACK, 1], [OCEAN_DRAKE, 1]],
	],
	"3-5": [
		[[&"raptors", 1], [&"wolves", 1], [&"krugs", 1], [&"gromp", 1]],
		[[&"raptors", 2], [&"wolves", 1], [BLUE_SENTINEL, 1]],
		[[&"wolves", 1], [&"krugs", 1], [&"gromp", 1], [RED_BRAMBLEBACK, 1], [SCUTTLER, 1]],
		[[&"raptors", 1], [&"wolves", 1], [&"krugs", 1], [&"gromp", 1], [BLUE_SENTINEL, 1]],
		[[&"raptors", 2], [&"wolves", 1], [&"krugs", 1], [RED_BRAMBLEBACK, 1], [SCUTTLER, 1]],
	],
}
## Stage id -> the boss wave's enemy id.
const BOSSES := {"1-1": &"thresh_1", "2-3": &"akshan", "3-5": &"elder_dragon"}
## Stage id -> enemy id -> its share of HP in that stage only. Act 1's stage
## is gentler: its melee and ranged minions have 20% less HP.
const HP_SHARES := {"1-1": {MELEE: 0.8, RANGED: 0.8}}


static func has_stage(stage_id: String) -> bool:
	return STAGES.has(stage_id)


## Enemy `id`'s share of HP in stage `stage_id` (1.0 unless listed).
static func hp_share(stage_id: String, id: StringName) -> float:
	return HP_SHARES.get(stage_id, {}).get(id, 1.0)


## Each wave as the enemy ids to spawn, in order.
static func waves(stage_id: String) -> Array:
	return expand(STAGES.get(stage_id, []))


## Waves of [enemy or pack id, count] groups as flat lists of enemy ids, in
## order. [pack, n] brings the pack's members n times.
static func expand(plan: Array) -> Array:
	var found := []
	for wave: Array in plan:
		var ids: Array[StringName] = []
		for group: Array in wave:
			for i in group[1]:
				ids.append_array(PACKS.get(group[0], [group[0]]))
		found.append(ids)
	return found


static func boss(stage_id: String) -> StringName:
	return BOSSES.get(stage_id, &"")
