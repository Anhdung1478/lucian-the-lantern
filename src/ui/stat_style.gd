class_name StatStyle
extends RefCounted
## How each stat looks: icon, color, name and hover text. Covers every item
## stat key (ItemStats) plus the panel-only regen (health and mana together)
## and attack_range. move_speed_pct looks like move_speed.

const KEYS: Array[StringName] = [
	&"ad", &"ap", &"armor", &"mr", &"attack_speed", &"ability_haste", &"crit_chance", &"move_speed",
	&"move_speed_pct", &"max_hp", &"max_mana", &"regen", &"heal_shield_power",
	&"armor_pen", &"magic_pen", &"lifesteal", &"omnivamp", &"attack_range", &"tenacity",
]
const ICONS := {
	&"ad": preload("res://assets/art/stats/ad.svg"),
	&"ap": preload("res://assets/art/stats/ap.svg"),
	&"armor": preload("res://assets/art/stats/armor.svg"),
	&"mr": preload("res://assets/art/stats/mr.svg"),
	&"attack_speed": preload("res://assets/art/stats/attack_speed.svg"),
	&"ability_haste": preload("res://assets/art/stats/ability_haste.svg"),
	&"crit_chance": preload("res://assets/art/stats/crit_chance.svg"),
	&"move_speed": preload("res://assets/art/stats/move_speed.svg"),
	&"max_hp": preload("res://assets/art/stats/max_hp.svg"),
	&"max_mana": preload("res://assets/art/stats/max_mana.svg"),
	&"regen": preload("res://assets/art/stats/regen.svg"),
	&"heal_shield_power": preload("res://assets/art/stats/heal_shield_power.svg"),
	&"armor_pen": preload("res://assets/art/stats/armor_pen.svg"),
	&"magic_pen": preload("res://assets/art/stats/magic_pen.svg"),
	&"lifesteal": preload("res://assets/art/stats/lifesteal.svg"),
	&"omnivamp": preload("res://assets/art/stats/omnivamp.svg"),
	&"attack_range": preload("res://assets/art/stats/attack_range.svg"),
	&"tenacity": preload("res://assets/art/stats/tenacity.svg"),
}
const COLORS := {
	&"ad": Color("ff9a3c"),
	&"ap": Color(TooltipText.COLORS["ap"]),
	&"armor": Color("f2c94c"),
	&"mr": Color("7fd4ff"),
	&"attack_speed": Color("fff3a3"),
	&"ability_haste": Color("ffffff"),
	&"crit_chance": Color("ff4b4b"),
	&"move_speed": Color("ffffff"),
	&"max_hp": Color("6fd36f"),
	&"max_mana": Color("8fb8ff"),
	&"regen": Color("6fd36f"),
	&"heal_shield_power": Color("7fe3c4"),
	&"armor_pen": Color("ff7a5a"),
	&"magic_pen": Color("b48cff"),
	&"lifesteal": Color("e0475a"),
	&"omnivamp": Color("c0508f"),
	&"attack_range": Color("cfd6e0"),
	&"tenacity": Color("c9b28a"),
}
## Stats no item gives.
const EXTRA_NAMES := {&"regen": "Health / Mana Regen", &"attack_range": "Attack Range"}
## TooltipText markup.
const DESCRIPTIONS := {
	&"ad": "Basic attacks deal this much [phys]physical damage[/phys]. Many skills grow with it.",
	&"ap": "Makes skills and item effects that scale with Ability Power stronger.",
	&"armor": "Lowers [phys]physical damage[/phys] taken: 100 armor blocks half.",
	&"mr": "Lowers [magic]magic damage[/magic] taken: 100 magic resist blocks half.",
	&"attack_speed": "Basic attacks per second (up to 2.5).",
	&"ability_haste": "Shortens skill cooldowns: 100 haste halves them.",
	&"crit_chance": "Chance for a basic attack to critically strike for 175% damage.",
	&"move_speed": "Units Lucian moves per second.",
	&"max_hp": "Lucian's health.",
	&"max_mana": "Spent to cast skills.",
	&"regen": "[hp]Health[/hp] / [mana]mana[/mana] restored every second.",
	&"heal_shield_power": "Makes heals and shields on Lucian stronger.",
	&"armor_pen": "Ignores this share of the target's armor.",
	&"magic_pen": "Ignores this share of the target's magic resist.",
	&"lifesteal": "Basic attacks heal Lucian for this share of their damage.",
	&"omnivamp": "All damage heals Lucian for this share of it.",
	&"attack_range": "How far basic attacks reach.",
	&"tenacity": "Shortens crowd control on Lucian.",
}


static func icon(key: StringName) -> Texture2D:
	return ICONS.get(_look(key))


static func color(key: StringName) -> Color:
	return COLORS.get(_look(key), Color.WHITE)


static func stat_name(key: StringName) -> String:
	return ItemStats.NAMES.get(key, EXTRA_NAMES.get(key, String(key)))


static func description(key: StringName) -> String:
	return DESCRIPTIONS.get(_look(key), "")


## An item card stat line: the icon, the amount in the stat's color, then the name.
static func item_line(key: StringName, value: float) -> String:
	return "[img=20x20]%s[/img] %s %s" % [icon(key).resource_path,
		TooltipText.color(ItemStats.amount(key, value), color(key).to_html(false)), ItemStats.NAMES[key]]


## The key whose icon, color and text `key` uses.
static func _look(key: StringName) -> StringName:
	return &"move_speed" if key == &"move_speed_pct" else key
