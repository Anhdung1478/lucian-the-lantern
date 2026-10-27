class_name StatBlock
extends RefCounted
## Final stat values for one level. Regen values are per second.

var max_hp := 0.0
var hp_regen := 0.0
var max_mana := 0.0
var mana_regen := 0.0
var ad := 0.0
var ap := 0.0
var attack_speed := 0.0
var crit_chance := 0.0
var crit_damage := 1.75
var armor := 0.0
var mr := 0.0
var move_speed := 0.0
var ability_haste := 0.0
var attack_range := 0.0
## Fractions (0.15 = 15%).
var lifesteal := 0.0
var omnivamp := 0.0
var armor_pen := 0.0
var magic_pen := 0.0
var heal_shield_power := 0.0
var tenacity := 0.0


func attack_period() -> float:
	return 1.0 / attack_speed
