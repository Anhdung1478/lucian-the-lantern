class_name UnitStats
extends Resource
## Base stats and per-level growth. Regen is entered per 5 seconds like LoL.

const MAX_ATTACK_SPEED := 2.5

@export var max_hp := 0.0
@export var max_hp_growth := 0.0
@export var hp_regen_per_5 := 0.0
@export var hp_regen_per_5_growth := 0.0
@export var max_mana := 0.0
@export var max_mana_growth := 0.0
@export var mana_regen_per_5 := 0.0
@export var mana_regen_per_5_growth := 0.0
@export var ad := 0.0
@export var ad_growth := 0.0
@export var attack_speed := 0.0
## Bonus attack speed is multiplied by this instead of the base value (LoL's AS ratio).
@export var attack_speed_ratio := 0.0
## Bonus attack speed gained per level, as a fraction (0.03 = 3%).
@export var attack_speed_growth := 0.0
@export var armor := 0.0
@export var armor_growth := 0.0
@export var mr := 0.0
@export var mr_growth := 0.0
@export var move_speed := 0.0
@export var attack_range := 0.0
@export var crit_damage := 1.75


## LoL's growth curve: 0 at level 1, 17 at level 18.
static func growth_factor(level: int) -> float:
	var n := float(level - 1)
	return n * (0.7025 + 0.0175 * n)


func at_level(level: int) -> StatBlock:
	var g := growth_factor(level)
	var block := StatBlock.new()
	block.max_hp = max_hp + max_hp_growth * g
	block.hp_regen = (hp_regen_per_5 + hp_regen_per_5_growth * g) / 5.0
	block.max_mana = max_mana + max_mana_growth * g
	block.mana_regen = (mana_regen_per_5 + mana_regen_per_5_growth * g) / 5.0
	block.ad = ad + ad_growth * g
	block.attack_speed = minf(attack_speed + attack_speed_ratio * attack_speed_growth * g, MAX_ATTACK_SPEED)
	block.armor = armor + armor_growth * g
	block.mr = mr + mr_growth * g
	block.move_speed = move_speed
	block.attack_range = attack_range
	block.crit_damage = crit_damage
	return block
