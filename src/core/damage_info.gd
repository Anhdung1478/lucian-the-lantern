class_name DamageInfo
extends RefCounted
## One hit before mitigation. `amount` already includes the crit multiplier.

enum Type { PHYSICAL, MAGIC, TRUE }

var amount := 0.0
var type := Type.PHYSICAL
## What dealt the hit, e.g. &"basic", &"lightslinger", &"q". Shown in the hit log.
var source: StringName
var attacker: Node
var is_crit := false
## The attacker's percent penetration, copied when the hit is made.
var armor_pen := 0.0
var magic_pen := 0.0
## Item effects this basic attack carries to its target, e.g. &"energized",
## &"kraken_slayer", &"spellblade".
var procs: Array[StringName] = []
## A boss or mini boss skill (Banshee's Veil blocks it).
var from_skill := false
## A burn or poison tick (DamageOverTime): no hit sound and no flash, and the
## attacker's on-hit effects don't fire on it.
var over_time := false


static func create(amount: float, type: Type, source: StringName, attacker: Node = null, is_crit := false) -> DamageInfo:
	var info := DamageInfo.new()
	info.amount = amount
	info.type = type
	info.source = source
	info.attacker = attacker
	info.is_crit = is_crit
	return info
