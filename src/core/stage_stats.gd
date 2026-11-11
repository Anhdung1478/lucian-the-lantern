class_name StageStats
extends RefCounted
## What happened in a stage, for the end screen: kills, the damage Lucian dealt
## and took, and the gold earned.

var kills := 0
## HP Lucian's hits really took from enemies.
var damage_dealt := 0.0
## After armor, before shields.
var damage_taken := 0.0
var gold_earned := 0
## The damage taken (as damage_taken) per source: the attacking enemy's id,
## else the hit's own source (&"burn" for ground fire).
var damage_by_source := {}
## Who struck the last blow (a key of damage_by_source) and with what
## (DamageInfo.source, e.g. &"basic", &"burn" or a boss skill).
var last_hit_by: StringName
var last_hit_with: StringName


## Counts a hit Lucian took: `amount` is what it did after armor.
func record_hit(info: DamageInfo, amount: float) -> void:
	var by := source_of(info)
	damage_taken += amount
	damage_by_source[by] = damage_by_source.get(by, 0.0) + amount
	last_hit_by = by
	last_hit_with = info.source


## The key a hit counts under: its enemy's id (copied onto the hit when it
## was made, so the enemy may be gone by now), else its source.
static func source_of(info: DamageInfo) -> StringName:
	return info.attacker_id if info.attacker_id != &"" else info.source


## "9,999" under 10,000; "41.2k" from there on.
static func format(amount: float) -> String:
	var whole := roundi(amount)
	if whole >= 10000:
		return "%.1fk" % (whole / 1000.0)
	var text := str(whole)
	if whole >= 1000:
		text = "%d,%03d" % [whole / 1000, whole % 1000]
	return text
