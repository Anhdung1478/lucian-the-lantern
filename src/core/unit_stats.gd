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


## `bonus` holds item stats keyed like ItemStats. Bonus attack speed goes
## through the AS ratio like level growth does.
func at_level(level: int, bonus: Dictionary = {}) -> StatBlock:
	var g := growth_factor(level)
	var block := StatBlock.new()
	block.max_hp = max_hp + max_hp_growth * g + bonus.get(&"max_hp", 0.0)
	block.hp_regen = (hp_regen_per_5 + hp_regen_per_5_growth * g) / 5.0
	block.max_mana = max_mana + max_mana_growth * g + bonus.get(&"max_mana", 0.0)
	block.mana_regen = (mana_regen_per_5 + mana_regen_per_5_growth * g) / 5.0
	block.ad = ad + ad_growth * g + bonus.get(&"ad", 0.0)
	block.ap = bonus.get(&"ap", 0.0)
	var bonus_attack_speed: float = attack_speed_growth * g + bonus.get(&"attack_speed", 0.0)
	block.attack_speed = minf(attack_speed + attack_speed_ratio * bonus_attack_speed, MAX_ATTACK_SPEED)
	block.crit_chance = minf(bonus.get(&"crit_chance", 0.0), 1.0)
	block.armor = armor + armor_growth * g + bonus.get(&"armor", 0.0)
	block.mr = mr + mr_growth * g + bonus.get(&"mr", 0.0)
	block.move_speed = (move_speed + bonus.get(&"move_speed", 0.0)) * (1.0 + bonus.get(&"move_speed_pct", 0.0))
	block.ability_haste = bonus.get(&"ability_haste", 0.0)
	block.attack_range = attack_range
	block.crit_damage = crit_damage
	for key in [&"lifesteal", &"omnivamp", &"armor_pen", &"magic_pen", &"heal_shield_power", &"tenacity"]:
		block.set(key, bonus.get(key, 0.0))
	return block
