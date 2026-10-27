class_name SkillData
extends Resource
## Per-rank numbers for one skill. An array with one value applies to every rank.

@export var id: StringName
@export var display_name := ""
@export var icon: Texture2D
@export var max_rank := 5
@export var damage_type := DamageInfo.Type.PHYSICAL
@export var mana_cost: Array[float] = []
@export var cooldown: Array[float] = []
@export var base_damage: Array[float] = []
@export var ad_ratio: Array[float] = []
@export var ap_ratio: Array[float] = []


func value_at(values: Array[float], rank: int) -> float:
	if values.is_empty() or rank < 1:
		return 0.0
	return values[mini(rank, values.size()) - 1]


func damage_at(rank: int, stats: StatBlock) -> float:
	return (
		value_at(base_damage, rank)
		+ value_at(ad_ratio, rank) * stats.ad
		+ value_at(ap_ratio, rank) * stats.ap
	)
