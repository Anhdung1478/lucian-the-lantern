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


## "9,999" under 10,000; "41.2k" from there on.
static func format(amount: float) -> String:
	var whole := roundi(amount)
	if whole >= 10000:
		return "%.1fk" % (whole / 1000.0)
	var text := str(whole)
	if whole >= 1000:
		text = "%d,%03d" % [whole / 1000, whole % 1000]
	return text
