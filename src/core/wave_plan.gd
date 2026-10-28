class_name WavePlan
extends RefCounted
## Which enemies each wave of a stage brings (docs/act1_the_loss.md,
## docs/act2_the_sentinels.md), and each stage's boss.

const MELEE := &"melee_minion"
const RANGED := &"ranged_minion"
const SIEGE := &"siege_minion"
const SUPER := &"super_minion"
## Stage id -> waves; each wave lists [enemy id, count] in spawn order.
const STAGES := {
	"1-1": [[[MELEE, 6], [RANGED, 4]], [[MELEE, 6], [RANGED, 6], [SIEGE, 1]]],
	"2-1": [[[MELEE, 6], [RANGED, 4], [SIEGE, 1]], [[MELEE, 6], [RANGED, 6], [SIEGE, 1], [SUPER, 1]]],
	"2-2": [[[MELEE, 6], [RANGED, 6], [SIEGE, 1]], [[MELEE, 6], [RANGED, 6], [SIEGE, 2]], [[MELEE, 6], [RANGED, 6], [SIEGE, 1], [SUPER, 1]]],
	"2-3": [[[MELEE, 6], [RANGED, 6], [SIEGE, 2]], [[MELEE, 6], [RANGED, 6], [SIEGE, 1], [SUPER, 1]], [[MELEE, 8], [RANGED, 6], [SIEGE, 2], [SUPER, 1]]],
}
## Stage id -> the boss wave's enemy id.
const BOSSES := {"1-1": &"thresh_1", "2-3": &"akshan"}


## Each wave as the enemy ids to spawn, in order.
static func waves(stage_id: String) -> Array:
	var found := []
	for wave: Array in STAGES.get(stage_id, []):
		var ids: Array[StringName] = []
		for group: Array in wave:
			for i in group[1]:
				ids.append(group[0])
		found.append(ids)
	return found


static func boss(stage_id: String) -> StringName:
	return BOSSES.get(stage_id, &"")
