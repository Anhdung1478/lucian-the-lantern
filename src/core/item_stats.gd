class_name ItemStats
extends RefCounted
## The stats items can give. Keys are used in ItemData.stats and in the bonus
## passed to UnitStats.at_level. Percent stats are stored as fractions.

const NAMES := {
	&"ad": "Attack Damage",
	&"ap": "Ability Power",
	&"attack_speed": "Attack Speed",
	&"crit_chance": "Critical Strike Chance",
	&"armor": "Armor",
	&"mr": "Magic Resist",
	&"max_hp": "Health",
	&"max_mana": "Mana",
	&"ability_haste": "Ability Haste",
	&"move_speed": "Move Speed",
	&"move_speed_pct": "Move Speed",
	&"lifesteal": "Life Steal",
	&"omnivamp": "Omnivamp",
	&"armor_pen": "Armor Penetration",
	&"magic_pen": "Magic Penetration",
	&"heal_shield_power": "Heal and Shield Power",
	&"tenacity": "Tenacity",
}
const PERCENT := [
	&"attack_speed", &"crit_chance", &"move_speed_pct", &"lifesteal", &"omnivamp",
	&"armor_pen", &"magic_pen", &"heal_shield_power", &"tenacity",
]


static func is_known(key: StringName) -> bool:
	return NAMES.has(key)


static func is_percent(key: StringName) -> bool:
	return PERCENT.has(key)


## "+65 Attack Damage" or "+25% Attack Speed".
static func line(key: StringName, value: float) -> String:
	if is_percent(key):
		return "+%d%% %s" % [roundi(value * 100.0), NAMES[key]]
	return "+%d %s" % [roundi(value), NAMES[key]]
